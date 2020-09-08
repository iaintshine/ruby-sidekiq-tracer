
Changelog
=========

## 1.2.2 09/08/2020
  * Add optional after_trace hook to ClientMiddleware

## 1.2.1 07/09/2020
  * Ensure child spans are nested under the root Sidekiq span in the trace

## 1.2.0 05/28/2020
  * Ignore active scope in consumers

## 1.1.0 05/27/2020
  * Set up build pipeline with circleci and gem-publisher
  * Fixed linting issues
  * Renamed gem to `sidekiq-instrumentation`
