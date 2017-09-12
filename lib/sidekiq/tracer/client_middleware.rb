module Sidekiq
  module Tracer
    class ClientMiddleware
      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(worker_class, job, queue, redis_pool)
        span = tracer.start_span(job['class'],
                                 child_of: active_span.respond_to?(:call) ? active_span.call : active_span,
                                 tags: {
                                  'component' => 'Sidekiq',
                                  'span.kind' => 'client',
                                  'sidekiq.queue' => job['queue'],
                                  'sidekiq.jid' => job['jid'],
                                  'sidekiq.retry' => job['retry'].to_s,
                                  'sidekiq.args' => job['args'].join(", ")
                                 })

        carrier = {}
        tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
        job['Trace-Context'] = carrier

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
    end
  end
end
