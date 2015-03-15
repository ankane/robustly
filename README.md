# Robustly

Don’t let small errors bring down the system

```ruby
safely do
  # keep going if this code fails
end
```

Raises exceptions in development and test environments and rescues and reports exceptions elsewhere.

Also aliased as `yolo`.

Reports exceptions to [Rollbar](https://rollbar.com/), [Airbrake](https://airbrake.io/), [Exceptional](http://www.exceptional.io/), [Honeybadger](https://www.honeybadger.io/), [Sentry](https://getsentry.com/), [Raygun](https://raygun.io/), and [Bugsnag](https://bugsnag.com/) out of the box thanks to [Errbase](https://github.com/ankane/errbase).

Customize reporting with:

```ruby
Robustly.report_exception_method = proc { |e| Rollbar.error(e) }
```

By default, exception messages are prefixed with `[safely]`. This makes it easier to spot rescued exceptions. Turn this off with:

```ruby
Robustly.tag = false
```

Throttle reporting with:

```ruby
safely sample: 1000 do
  # reports ~ 1/1000 errors
end
```

Specify a default value to return on exceptions

```ruby
safely default: 30 do
  # big bucks, no whammy
end
```

Raise specific exceptions

```ruby
safely except: ActiveRecord::RecordNotUnique do
  # all other exceptions will be rescued
end
```

Pass an array for multiple exception classes.

Rescue only specific exceptions

```ruby
safely only: ActiveRecord::RecordNotUnique do
  # all other exceptions will be raised
end
```

Silence exceptions

```ruby
safely silence: ActiveRecord::RecordNotUnique do
end
```

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'robustly'
```

## History

View the [changelog](https://github.com/ankane/robustly/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/robustly/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/robustly/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
