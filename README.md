Metrix
========

An Elixir library to log custom application metrics (for use by other downstream systems such as [Librato](https://www.librato.com/), [Riemann](http://riemann.io/) etc...)

Metrix subscribes to the Twelve Factor App notion that [logs are streams of time-ordered events](http://12factor.net/logs) and that events should be captured and recorded in the [l2met logging convention](https://github.com/ryandotsmith/l2met/wiki/Usage#logging-convention).

What this means in pragmatic terms is that this library provides a few convenience methods to help you capture data from your application to your logging output in a well-structured key-value format:

```
measure#api.request.service=23.43ms path=/v1/user.json response_status=200
sample#api.response.size=1.34kb path=/v1/user.json
count#user.login user_id=32 other="data with spaces"
```

Note: Metrix does *not* do any calculations itself. It merely logs the data its given in a specific format. If you are looking for an in-app instrumentation library, you may want to look at [exometer](https://github.com/Feuerlabs/exometer) or [folsom](https://github.com/boundary/folsom) instead.

## Benefits

Treating "logs as data" in this manner has several advantages, including:

* Logs are machine parseable *and* human readable, providing the best of both worlds
* It's a low-overhead way of getting data out of your app, not requiring any additional in-app processing or dependencies
* The ability to pipe app data to one or more downstream processors, such as Librato for visualization and Reimann for alerting, without requiring modification to the app
* Data is output via logging and can be manipulated with a multitude of POSIX utilities

If you are looking for a more substantive justification for this style of logging, please see [5 Steps to Better Application Logging](http://www.miyagijournal.com/articles/five-steps-application-logging/).

## Install

Add `metrix` to your applications in `mix.exs`:

```elixir
def application do
  [mod: {YourApp, []},
   applications: [..., :metrix]]
end
```

And declare it as a dependency:

```elixir
defp deps do
  [
    # ...
    {:metrix, "~> 0.4.0"}
  ]
end
```

Then update your dependencies:

```session
$ mix deps.get
```

## Usage

There are three types of metrics natively supported by Metrix: `count`s, `sample`s and `measure`ments.

### Count

When you want to count the occurrences of an event in your app, use `count`:

```elixir
import Metrix

count "app.event"
count "app.event", 3
```

Which will output:

```session
count#event.name=1
count#event.name=3
```

Event metadata can be attached by passing in a map as the first argument:

```elixir
%{"path" => "/users/1"} |> count "app.event"
```

Which outputs:

```session
count#event.name=1 path=/users/1
```

`metadata` can be a map or keyword list:

```elixir
[path: "/users/1"] |> count "app.event"
```

When passed to log processors like Librato, counts can be min, max, summed, stacked etc...

![](http://f.cl.ly/items/1C2r2e1p2E233m0H3S2s/Image%202015-06-15%20at%209.26.29%20AM.png)

### Sample

Samples are used to take periodic, point-in-time, measurements such as CPU load, hard disk space etc...

Samples are logged in the same fashion as `count`:

```elixir
import Metrix

sample "file.size", "12.3kb"
[file: "/images/hi.png"] |> sample "file.size", "12.3kb"
```

Which will output:

```session
sample#file.size=12.3kb
sample#file.size=12.3kb file=/images/hi.png
```

Samples are captured in Librato with the units used in the measurement value (`kb` in this case) and can be averaged, p50, p95, and p99d.

![](http://cl.ly/bdHZ/Image%202015-06-15%20at%209.23.48%20AM.png)

### Measure

Measurements are measures of time, most often used to track execution time. As such, they wrap a block of code whose execution time is to be measured:

```elixir
import Metrix

measure "api.request", fn -> HTTPotion.get "httpbin.org/get" end

[path: "/get"]
|> measure "api.request", fn -> HTTPotion.get "httpbin.org/get" end
```

Measurements are taken in `ms`:

```session
measure#api.request=142ms
measure#api.request=131ms path=/get
```

It's common to want to add metadata to a measurement that is used within the function call (the `path` above being a good example). Instead of providing a no-arg function to `measure`, you can provide a 1-arity function that accepts the metrics metadata (and can pattern match against it). For instance:


```elixir
%{"path" => "/get", "client" => "elixir"}
|> measure "api.request", fn(%{"path" => path}) -> HTTPotion.get "httpbin.org#{path}" end
```
```session
measure#api.request=131ms path=/get client=elixir
```

Measurements in Librato are collected into median, p95 and p99 series:

![](http://f.cl.ly/items/0q2o3A1G06442f2G0t39/Image%202015-06-15%20at%206.29.28%20PM.png)

### Global context

Often times there is metadata you want applied to every measurement. For instance a `source` element indicating which server the output originated from or `app` which differentiates output from multiple components going to the same downstream processor. This type of universally applicable metadata can be set once using the global context:

```elixir
Metrix.add_context %{"source" => System.get_env("NODE_NAME")}
Metrix.count "event.name"
```

```
count#event.name=1 source=node.us-east.1a
```

The context can be cleared with `Metrix.clear_context`, though be aware it is global context and will be cleared for all output.

The global context can also be set via the configuration...

### Configuration

Metrix allows its initial context to be configured, which must be a map:

```elixir
config :metrix,
  context: %{"source" => "my-app"}
```

The format of each metric can also be customized through formats and parameters:

```Elixir
config :metrix,
  count_format: "$count#$prefix.$metric",
  measure_format: "$measure#$prefix.$metric",
  sample_format: "$sample#$prefix.$metric",
  parameters: %{
    :prefix => "my-prefix",
    :count => "count-it",
    :measure => "measure-it",
    :sample => "sample-it",
  }
```

Given the above config, `Metrix.count "event.name"` would yield:

```
count-it#my-prefix.event.name=1
```

The default formats are:

* count: count#$metric
* measure: measure#$metric
* sample: sample#$metric

Where `$metric` is the name of the metric passed in.

Metrix writes to `Logger.info`. To adjust the output target, set the logger configuration in `config.exs`. For instance, to write to `stdout` (the Elixir default) with no timestamp line info, do:

```elixir
config :logger, :console,
  level: :info,
  format: "$message\n",
  colors: [enabled: false]
 ```

## Heroku & Librato

Librato is my preferred choice for metrics visualization and long-term storage. It also plays very well with apps deployed to Heroku. Follow these instructions to get your Heroku app's Metrix log output streaming to Librato for processing.

### Librato add-on

If your app is deployed to Heroku, just add the Librato add-on and all [custom counts, samples and measurements](https://devcenter.heroku.com/articles/librato#custom-log-based-metrics) will automatically be sent to Librato which will apply median, p95, p99 and a host of other real-time aggregations. In addition, Heroku's native logging will also be piped to Librato, giving you both platform and app metrics in one place.

### External Librato account

If you already have a Librato account, you can still stream your data to from Heroku by setting up a [custom log drain](https://www.librato.com/docs/kb/collect/integrations/heroku_integration.html).

## Todo

There are a few known missing pieces, including:

* Multiple metrics per log line
* Scoped contexts (e.g., request ids) - is this even possible w/ Elixir w/o having to pass the data through the whole call stack?
* k/v pair ordering

## Contributions

This library was built as an Elixir alternative to the Ruby-based [Scrolls](https://github.com/asenchi/scrolls) library, which I've found to be indispensable. It was also built on top of [Logfmt](https://github.com/jclem/logfmt-elixir), which handles the mundane but critical task of actually formatting the output as correctly escaped key/value pairs.

Code contributors include:

* [objectuser](https://github.com/objectuser)
* [sdball](https://github.com/sdball)
* [davidsantoso](https://github.com/davidsantoso)
* [shosti](https://github.com/shosti)

## Changelog

### 0.4.0

* Allow global context to be set via app configuration
* Bump Elixir version

### 0.3.1

* Relax Elixir version requirement

### 0.3.0

* Output is now written to `Logger.info` instead of `stdout` and will respect existing Logger settings
* Due to the use of `ExUnit.CaptureLog`, Elixir v1.1.0 and up is required
