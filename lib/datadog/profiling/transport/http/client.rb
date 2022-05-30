# typed: true

require 'ddtrace/transport/http/client'
require 'ddtrace/transport/request'

module Datadog
  module Profiling
    module Transport
      module HTTP
        # Routes, encodes, and sends tracer data to the trace agent via HTTP.
        class Client < Datadog::Transport::HTTP::Client
          def export(flush)
            send_profiling_flush(flush)
          end

          def send_profiling_flush(flush)
            # Build a request
            request = flush
            send_payload(request).tap do |response|
              if response.ok?
                Datadog.logger.debug('Successfully reported profiling data')
              else
                Datadog.logger.debug { "Failed to report profiling data -- #{response.inspect}" }
              end
            end
          end

          def send_payload(request)
            send_request(request) do |api, env|
              api.send_profiling_flush(env)
            end
          end
        end
      end
    end
  end
end
