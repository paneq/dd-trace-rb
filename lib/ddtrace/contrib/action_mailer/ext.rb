module Datadog
  module Contrib
    module ActionMailer
      # ActionMailer integration constants
      module Ext
        APP = 'action_mailer'.freeze
        ENV_ENABLED = 'DD_TRACE_ACTION_MAILER_ENABLED'.freeze
        ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTION_MAILER_ANALYTICS_ENABLED'.freeze
        ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTION_MAILER_ANALYTICS_SAMPLE_RATE'.freeze

        ENV_ANALYTICS_ENABLED_OLD = 'DD_ACTION_MAILER_ANALYTICS_ENABLED'.freeze

        ENV_ANALYTICS_SAMPLE_RATE_OLD = 'DD_ACTION_MAILER_ANALYTICS_SAMPLE_RATE'.freeze
        SERVICE_NAME = 'action_mailer'.freeze
        SPAN_PROCESS = 'action_mailer.process'.freeze
        SPAN_DELIVER = 'action_mailer.deliver'.freeze
        TAG_ACTION = 'action_mailer.action'.freeze
        TAG_MAILER = 'action_mailer.mailer'.freeze
        TAG_MSG_ID = 'action_mailer.message_id'.freeze
      end
    end
  end
end
