require "spec_helper"

RSpec.describe Sidekiq::Tracer::ServerMiddleware do
  let(:tracer) { Test::Tracer.new }

  describe "auto-instrumentation" do
    before do
      schedule_test_job
      Sidekiq::Tracer.instrument_server(tracer: tracer)
      TestJob.drain
    end

    it "creates a new span" do
      expect(tracer).to have_spans(1)
    end

    it "sets operation_name to job name" do
      expect(tracer).to have_span("TestJob")
    end

    it "sets standard OT tags" do
      [
        ['component', 'Sidekiq'],
        ['span.kind', 'server']
      ].each do |key, value|
        expect(tracer).to have_span.with_tag(key, value)
      end
    end

    it "sets Sidekiq specific OT tags" do
      [
        ['sidekiq.queue', 'default'],
        ['sidekiq.retry', "true"],
        ['sidekiq.args', "value1, value2, 1"],
        ['sidekiq.jid', /\S+/]
      ].each do |key, value|
        expect(tracer).to have_span.with_tag(key, value)
      end
    end
  end

  describe "client-server trace context propagation" do
    let(:root_span) { tracer.start_span("root") }

    before do
      Sidekiq::Tracer.instrument(tracer: tracer, active_span: -> { root_span })
      schedule_test_job
      TestJob.drain
      root_span.finish
    end

    it "creates spans for each part of the chain" do
      expect(tracer).to have_spans(3)
    end

    it "all spans contains the same trace_id" do
      expect(tracer).to have_traces(1)
    end

    it "propagates parent child relationship properly" do
      client_span = tracer.finished_spans[0]
      server_span = tracer.finished_spans[1]
      expect(client_span).to be_child_of(root_span)
      expect(server_span).to be_child_of(client_span)
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
