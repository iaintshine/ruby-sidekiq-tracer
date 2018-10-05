module Sidekiq
  module Tracer
    class ServerMiddleware
      include Commons

      attr_reader :tracer

      def initialize(tracer:)
        @tracer = tracer
      end

      def call(worker, job, queue)
        parent_span_context = extract(job)

        scope = tracer.start_active_span(
          operation_name(job),
          child_of: parent_span_context,
          tags: tags(job, 'server')
        )

        yield
      rescue Exception => e
        if scope
          scope.span.set_tag('error', true)
          scope.span.log(event: 'error', :'error.object' => e)
        end
        raise
      ensure
        scope.close if scope
      end

      private

      def extract(job)
        carrier = job[TRACE_CONTEXT_KEY]
        return unless carrier

        tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      end
    end
  end
end
