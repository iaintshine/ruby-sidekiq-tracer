module Sidekiq
  module Tracer
    class ClientMiddleware
      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end
    end
  end
end
