# frozen_string_literal: true

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
        %w[component Sidekiq],
        ["span.kind", "consumer"]
      ].each do |key, value|
        expect(tracer).to have_span.with_tag(key, value)
      end
    end

    it "sets Sidekiq specific OT tags" do
      [
        ["sidekiq.queue", "default"],
        ["sidekiq.retry", "true"],
        ["sidekiq.args", "value1, value2, 1"],
        ["sidekiq.jid", /\S+/]
      ].each do |key, value|
        expect(tracer).to have_span.with_tag(key, value)
      end
    end
  end

  describe "after trace hook" do
    it "calls hook if defined" do
      after_trace = double("after_trace")
      expect(after_trace).to receive(:call)

      schedule_test_job
      Sidekiq::Tracer.instrument_server(tracer: tracer, after_trace: after_trace)
      TestJob.drain
    end
  end

  describe "trace context propagation" do
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

    it "creates separate traces for the producer and consumer" do
      expect(tracer).to have_traces(2)
    end
  end

  def schedule_test_job
    TestJob.perform_async("value1", "value2", 1)
  end
  class TestJob
    include Sidekiq::Worker

    def perform(*args); end
  end
end
