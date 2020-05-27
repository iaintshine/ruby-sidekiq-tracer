# frozen_string_literal: true

module Sidekiq
  module Tracer
    module Commons
      def operation_name(job)
        job["class"]
      end

      def tags(job, kind)
        {
          "component" => "Sidekiq",
          "span.kind" => kind,
          "sidekiq.queue" => job["queue"],
          "sidekiq.jid" => job["jid"],
          "sidekiq.retry" => job["retry"].to_s,
          "sidekiq.args" => job["args"].join(", ")
        }
      end
    end
  end
end
