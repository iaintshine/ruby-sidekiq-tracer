# Sidekiq::Tracer

OpenTracing instrumentation for Sidekiq (both client, and server-side).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-tracer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-tracer

## Usage

The gem hooks up into Sidekiq through [middlewares](https://github.com/mperham/sidekiq/wiki/Middleware) - similar to Rack. Both server-side, and client-side middlewares are supported.

* Client-side middleware runs before the pushing of the job to Redis and injects the current span context into the job's metadata.
* Server-side runs around job processing, extracts the context from the job metadata and creates a new span for the server-side proessing.

To instrument Sidekiq (both sides), you need to specify at least a tracer instance and optionally an active span provider - a proc which returns a current active span. The gem plays nicely with [spanmanager](https://github.com/iaintshine/ruby-spanmanager).

```ruby
require "sidekiq-tracer"

Sidekiq::Tracer.instrument(tracer: OpenTracing.global_tracer,
                           active_span: -> { OpenTracing.global_tracer.active_span })
```

And you are all set.

The code below shows how to register and manage middlewares on your own.

Server-side:

```ruby
Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Tracer::ClientMiddleware, tracer: OpenTracing.global_tracer
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Tracer::ServerMiddleware, tracer: OpenTracing.global_tracer
  end
end
```

Client-side:

```ruby
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Tracer::ClientMiddleware, tracer: OpenTracing.global_tracer
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iaintshine/ruby-sidekiq-tracer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Sidekiq::Tracer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iaintshine/ruby-sidekiq-tracer/blob/master/CODE_OF_CONDUCT.md).
