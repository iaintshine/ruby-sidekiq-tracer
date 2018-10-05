require "bundler/setup"
require "sidekiq/testing"
require "sidekiq-opentracing"
require 'opentracing_test_tracer'
require "pry"

OpenTracing.global_tracer = OpenTracingTestTracer.build

Sidekiq::Testing.fake!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
