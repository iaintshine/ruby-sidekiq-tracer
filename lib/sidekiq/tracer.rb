require "sidekiq"

require "sidekiq/tracer/version"
require "sidekiq/tracer/client_middleware"

module Sidekiq
  module Tracer
    class << self
      def instrument_client(tracer: OpenTracing.global_tracer, active_span: nil)
        Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add Sidekiq::Tracer::ClientMiddleware, tracer: tracer, active_span: active_span
          end
        end
      end
    end
  end
end
