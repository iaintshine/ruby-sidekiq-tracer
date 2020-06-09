# frozen_string_literal: true

module Sidekiq
  module Tracer
    class ServerMiddleware
      include Commons

      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(_worker, job, _queue)
        span = build_span(job)

        yield
      rescue StandardError => e
        tag_errors(span, e) if span
        raise
      ensure
        span&.finish
      end

      private

      def build_span(job)
        parent_span_context = extract(job)

        follows_from = OpenTracing::Reference.follows_from(parent_span_context)

        tracer.start_span(operation_name(job),
                          references: [follows_from],
                          ignore_active_scope: true,
                          tags: tags(job, "consumer"))
      end

      def tag_errors(span, error)
        span.set_tag("error", true)
        span.log(event: "error", 'error.object': error)
      end

      def extract(job)
        carrier = job[TRACE_CONTEXT_KEY]
        return unless carrier

        tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      end
    end
  end
end
