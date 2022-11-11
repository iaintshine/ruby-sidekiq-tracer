# frozen_string_literal: true

module Sidekiq
  module Tracer
    class ClientMiddleware
      include Commons

      attr_reader :tracer, :active_span

      def initialize(tracer, active_span)
        @tracer = tracer
        @active_span = active_span
      end

      def call(_worker_class, job, _queue, _redis_pool)
        span = build_span(job)

        inject(span, job)

        yield
      rescue StandardError => e
        tag_errors(span, e) if span
        raise
      ensure
        span&.finish
      end

      private

      def build_span(job)
        tracer.start_span(operation_name(job),
                          child_of: active_span.respond_to?(:call) ? active_span.call : active_span,
                          tags: tags(job, "producer"))
      end

      def tag_errors(span, error)
        span.set_tag("error", true)
        span.log_kv({event: "error", 'error.object': error})
      end

      def inject(span, job)
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
        job[TRACE_CONTEXT_KEY] = carrier
      end
    end
  end
end
