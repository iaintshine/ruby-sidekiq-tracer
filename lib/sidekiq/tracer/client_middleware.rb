module Sidekiq
  module Tracer
    class ClientMiddleware
      include Commons

      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(worker_class, job, queue, redis_pool)
        span = tracer.start_span(operation_name(job),
                                 child_of: active_span.respond_to?(:call) ? active_span.call : active_span,
                                 tags: tags(job, 'producer'))

        inject(span, job)

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

      def inject(span, job)
        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
        job[TRACE_CONTEXT_KEY] = carrier
      end
    end
  end
end
