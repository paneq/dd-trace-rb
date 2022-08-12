# frozen_string_literal: true
# typed: true

require_relative 'parser'
require_relative 'ext'
require_relative '../../trace_digest'
require_relative '../datadog_tags_codec'

module Datadog
  module Tracing
    module Distributed
      module Headers
        # Datadog provides helpers to inject or extract headers for Datadog style headers
        module Datadog
          class << self
            include Ext

            def inject!(digest, env)
              return if digest.nil?

              env[HTTP_HEADER_TRACE_ID] = digest.trace_id.to_s
              env[HTTP_HEADER_PARENT_ID] = digest.span_id.to_s
              env[HTTP_HEADER_SAMPLING_PRIORITY] = digest.trace_sampling_priority.to_s if digest.trace_sampling_priority
              env[HTTP_HEADER_ORIGIN] = digest.trace_origin.to_s unless digest.trace_origin.nil?

              inject_tags(digest, env)

              env
            end

            def extract(env)
              # Extract values from headers
              headers = Parser.new(env)
              trace_id = headers.id(HTTP_HEADER_TRACE_ID)
              parent_id = headers.id(HTTP_HEADER_PARENT_ID)
              origin = headers.header(HTTP_HEADER_ORIGIN)
              sampling_priority = headers.number(HTTP_HEADER_SAMPLING_PRIORITY)

              # Return early if this propagation is not valid
              # DEV: To be valid we need to have a trace id and a parent id
              #      or when it is a synthetics trace, just the trace id.
              # DEV: `Parser#id` will not return 0
              return unless (trace_id && parent_id) || (origin && trace_id)

              trace_distributed_tags = extract_tags(headers)

              # Return new trace headers
              TraceDigest.new(
                span_id: parent_id,
                trace_id: trace_id,
                trace_origin: origin,
                trace_sampling_priority: sampling_priority,
                trace_distributed_tags: trace_distributed_tags,
              )
            end

            private

            # Injects `x-datadog-tags` trace tags
            def inject_tags(digest, env)
              return if digest.trace_distributed_tags.nil? || digest.trace_distributed_tags.empty?

              if ::Datadog.configuration.tracing.x_datadog_tags_max_length <= 0
                active_trace = Tracing.active_trace
                active_trace.set_tag("_dd.propagation_error", "disabled") if active_trace
                return
              end

              encoded_tags = DatadogTagsCodec.encode(digest.trace_distributed_tags)

              if encoded_tags.size > ::Datadog.configuration.tracing.x_datadog_tags_max_length
                active_trace = Tracing.active_trace
                active_trace.set_tag("_dd.propagation_error", "inject_max_size") if active_trace

                ::Datadog.logger.warn("Failed to inject x-datadog-tags: tags are too large (size:#{encoded_tags.size} " \
                  "limit:#{::Datadog.configuration.tracing.x_datadog_tags_max_length}). This limit can be configured " \
                  "through the DD_TRACE_X_DATADOG_TAGS_MAX_LENGTH environment variable.")
                return
              end

              env[HTTP_HEADER_TAGS] = encoded_tags
            rescue => e
              active_trace = Tracing.active_trace
              active_trace.set_tag("_dd.propagation_error", "encoding_error") if active_trace
              ::Datadog.logger.warn(
                "Failed to inject x-datadog-tags: #{e.class.name} #{e.message} at #{Array(e.backtrace).first}"
              )
            end

            # Only extract keys with the expected Datadog prefix
            VALID_TAGS_KEY_PREFIX = '_dd.p.'

            def extract_tags(headers)
              tags_header = headers.header(HTTP_HEADER_TAGS)
              return unless tags_header

              if ::Datadog.configuration.tracing.x_datadog_tags_max_length <= 0
                active_trace = Tracing.active_trace
                active_trace.set_tag("_dd.propagation_error", "disabled") if active_trace
                return
              end

              if tags_header.size > ::Datadog.configuration.tracing.x_datadog_tags_max_length
                active_trace = Tracing.active_trace
                active_trace.set_tag("_dd.propagation_error", "extract_max_size") if active_trace

                ::Datadog.logger.warn("Failed to extract x-datadog-tags: tags are too large (size:#{tags_header.size} " \
                  "limit:#{::Datadog.configuration.tracing.x_datadog_tags_max_length}). This limit can be configured " \
                  "through the DD_TRACE_X_DATADOG_TAGS_MAX_LENGTH environment variable.")
                return
              end

              tags = DatadogTagsCodec.decode(tags_header)
              tags.select! { |key, value| key.start_with?(VALID_TAGS_KEY_PREFIX) }
            rescue => e
              active_trace = Tracing.active_trace
              active_trace.set_tag("_dd.propagation_error", "decoding_error") if active_trace
              ::Datadog.logger.warn(
                "Failed to extract x-datadog-tags: #{e.class.name} #{e.message} at #{Array(e.backtrace).first}"
              )
            end
          end
        end
      end
    end
  end
end
