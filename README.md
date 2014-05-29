# SweetNotifications [![Build Status](https://travis-ci.org/lautis/sweet_notifications.svg?branch=master)](https://travis-ci.org/lautis/sweet_notifications)

Syntactic sugar for ActiveSupport::LogSubscriber for easy instrumentation and
logging from third-party libraries.

## Installation

Add this line to your application's Gemfile:

    gem 'sweet_notifications'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sweet_notifications

## Usage

This library helps with creating ActiveSupport::Notifications subscribers for
logging purposes. First, there should be a source of notifications:

```ruby

class CandiesController < ApplicationController
  def index
    candies = %w{M&M's Gummibears Pez Salmiakki}
    ActiveSupport::Notifications.instrument 'list.candies', list: candies do
      sleep 0.5
      render json: candies
    end
  end
end
```

Then, subscribe to these notifications using SweetNotifications in an initializer:

```ruby
SweetNotifications.subscribe :candies do
  color ActiveSupport::LogSubscriber::GREEN
  event :list, runtime: true do |event|
    return unless logger.debug?
    debug message(event, 'Candy', "listing candies: #{event.payload[:candies]}")
  end
end
```

`SweetNotifications.subscribe` will subscribe to the namespace given as
argument and, if necessary, create a Rails initializer that will be run when
the application is initialized.

If this functionality is too much, use `SweetNotification::LogSubscriber` to
create LogSusbcribers and `SweetNotification.controller_runtime` to bind this
to a Rails controller logging.

```ruby
class AwesomeLogSubscriber < SweetNotifications::LogSubscriber
  color ActiveSupport::LogSubscriber::CYAN, ActiveSupport::LogSubscriber::MAGENTA
  event :cool, runtime: true do |event|
    info "Cool stuff"
  end

  event :insanely_great, runtime: false do |event|
    debug "Insanely greate"
  end
end

AwesomeLogSubscriber.attach_to :namespace
ControllerRuntime = SweetNotifications.controller_runtime(:namespace, AwesomeLogSubscriber)

ActionController::Base.send(:include, ControllerRuntime)

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sweet_notifications/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
