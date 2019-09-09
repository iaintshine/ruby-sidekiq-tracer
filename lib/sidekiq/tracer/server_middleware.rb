module Sidekiq
  module Tracer
    class ServerMiddleware
      include Commons

      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(worker, job, queue)
        parent_span_context = extract(job)

        follows_from = OpenTracing::Reference.follows_from(parent_span_context)
        
        span = tracer.start_span(operation_name(job),
                                 references: [follows_from],
                                 tags: tags(job, 'consumer'))

        yield
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log(event: 'error', :'error.object' => e)
        end
        raise
      ensure
        span.finish if span
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
