require "spec_helper"

RSpec.describe Sidekiq::Tracer::ClientMiddleware do
  let(:tracer) { OpenTracingTestTracer.build }

  describe "pushing to the queue" do
    before do
      Sidekiq::Tracer.instrument_client(tracer: tracer)
      schedule_test_job
    end

    it "still enqueues job to the queue" do
      expect(TestJob.jobs.size).to eq(1)
    end
  end

  describe "auto-instrumentation" do
    before do
      Sidekiq::Tracer.instrument_client(tracer: tracer)
      schedule_test_job
    end

    it "creates a new span" do
      expect(tracer.spans.count).to eq(1)
    end

    it "sets operation_name to job name" do
      expect(tracer.spans.first.operation_name).to eq("TestJob")
    end

    it "sets standard OT tags" do
      span = tracer.spans.first

      expect(span.tags).to include(
        'component' => 'Sidekiq',
        'span.kind' => 'client'
      )
    end

    it "sets Sidekiq specific OT tags" do
      span = tracer.spans.first

      expect(span.tags).to include(
        'sidekiq.queue' => 'default',
        'sidekiq.retry' => 'true',
        'sidekiq.args' => 'value1, value2, 1',
        'sidekiq.jid' => /\S+/
      )
    end
  end

  describe "active span propagation" do
    let(:root_span) { tracer.start_span("root") }

    before do
      Sidekiq::Tracer.instrument_client(tracer: tracer, active_span: -> { root_span })
      schedule_test_job
    end

    it "creates the new span with active span as a parent" do
      expect(tracer.spans.count).to eq(2)
      expect(tracer.spans.first).to eq(root_span)
      child_span = tracer.spans.last

      expect(child_span.context.parent_id).to eq(root_span.context.span_id)
    end
  end

  describe "span context injection" do
    before do
      Sidekiq::Tracer.instrument_client(tracer: tracer)
      schedule_test_job
    end

    it "injects span context to enqueued job" do
      enqueued_span = tracer.spans.last

      job = TestJob.jobs.last
      carrier = job['Trace-Context']
      extracted_span_context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)

      expect(enqueued_span.context.trace_id).to eq(extracted_span_context.trace_id)
      expect(enqueued_span.context.span_id).to eq(extracted_span_context.span_id)
    end
  end

  def schedule_test_job
    TestJob.perform_async("value1", "value2", 1)
  end

  class TestJob
    include Sidekiq::Worker

    def perform(*args)
    end
  end
end
