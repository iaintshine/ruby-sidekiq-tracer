module Sidekiq
  module Tracer
    class ServerMiddleware
      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(worker, job, queue)
        parent_span_context = extract(job)

        span = tracer.start_span(job['class'],
                                 child_of: parent_span_context,
                                 tags: {
                                  'component' => 'Sidekiq',
                                  'span.kind' => 'server',
                                  'sidekiq.queue' => job['queue'],
                                  'sidekiq.jid' => job['jid'],
                                  'sidekiq.retry' => job['retry'].to_s,
                                  'sidekiq.args' => job['args'].join(", ")
                                 })
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
        carrier = job['Trace-Context']
        return unless carrier

        tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      end
    end
  end
end
