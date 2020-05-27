# frozen_string_literal: true

require "sidekiq"

require "sidekiq/tracer/version"
require "sidekiq/tracer/constants"
require "sidekiq/tracer/commons"
require "sidekiq/tracer/client_middleware"
require "sidekiq/tracer/server_middleware"

module Sidekiq
  module Tracer
    class << self
      def instrument(tracer: OpenTracing.global_tracer, active_span: nil)
        instrument_client(tracer: tracer, active_span: active_span)
        instrument_server(tracer: tracer, active_span: active_span)
      end

      def instrument_client(tracer: OpenTracing.global_tracer, active_span: nil)
        Sidekiq.configure_client do |config|
          config.client_middleware { |chain| add_client_middleware(chain, tracer, active_span) }
        end
      end

      def instrument_server(tracer: OpenTracing.global_tracer, active_span: nil)
        Sidekiq.configure_server do |config|
          config.client_middleware { |chain| add_client_middleware(chain, tracer, active_span) }
          config.server_middleware { |chain| add_server_middleware(chain, tracer, active_span) }
        end

        return unless defined?(Sidekiq::Testing)

        Sidekiq::Testing.server_middleware { |chain| add_server_middleware(chain, tracer, active_span) }
      end

      def add_client_middleware(chain, tracer, active_span)
        chain.add Sidekiq::Tracer::ClientMiddleware, tracer: tracer, active_span: active_span
      end

      def add_server_middleware(chain, tracer, active_span)
        chain.add Sidekiq::Tracer::ServerMiddleware, tracer: tracer, active_span: active_span
      end
    end
  end
end
