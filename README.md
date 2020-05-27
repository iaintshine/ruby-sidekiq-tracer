# Sidekiq::Tracer

OpenTracing instrumentation for Sidekiq (both client, and server-side).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-opentracing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-opentracing

## Usage

The gem hooks up into Sidekiq through [middlewares](https://github.com/mperham/sidekiq/wiki/Middleware) - similar to Rack. Both server-side, and client-side middlewares are supported.

* Client-side middleware runs before the pushing of the job to Redis and injects the current span context into the job's metadata.
* Server-side runs around job processing, extracts the context from the job metadata and creates a new span for the server-side proessing.

To instrument Sidekiq (both sides), you need to specify at least a tracer instance and optionally an active span provider - a proc which returns a current active span. The gem plays nicely with [spanmanager](https://github.com/iaintshine/ruby-spanmanager).

```ruby
require "sidekiq-opentracing"

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

# Development

## Gem documentation

You can find the documentation by going to CircleCI, looking for the `build` job, going to Artifacts and clicking on `index.html`. A visual guide on this can be found in our wiki at [Gems Development: Where to find documentation for our gems](https://wiki.doximity.com/articles/gems-development-where-to-find-documentation-for-our-gems).

## Gem development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bundle console` for an interactive prompt that will allow you to experiment.

This repository uses a gem publishing mechanism on the CI configuration, meaning most work related with cutting a new
version is done automatically.

To release a new version, follow the [wiki instructions](https://wiki.doximity.com/articles/gems-development-releasing-new-versions).
