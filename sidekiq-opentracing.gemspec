# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq/tracer/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-opentracing"
  spec.version       = Sidekiq::Tracer::VERSION
  spec.authors       = ["iaintshine"]
  spec.email         = ["bodziomista@gmail.com"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{OpenTracing instrumentation for Sidekiq.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/iaintshine/ruby-sidekiq-tracer"

  spec.required_ruby_version = ">= 2.2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'opentracing', '~> 0.4'
  spec.add_dependency 'sidekiq'

  spec.add_development_dependency "opentracing_test_tracer", "~> 0.1"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
