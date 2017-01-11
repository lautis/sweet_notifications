require 'sweet_notifications/version'
require 'sweet_notifications/log_subscriber'
require 'sweet_notifications/controller_runtime'
require 'sweet_notifications/railtie'

# Syntactic sugar for ActiveSupport::Notifications subscribers for logging
# purposes in Rails.
module SweetNotifications
  extend ControllerRuntime
  extend Railtie

  # Subscribe to an ActiveSupport::Notifications namespace.
  #
  # This will subscribe to the namespace given as argument and, if necessary,
  # create a Rails initializer that will be run when the application is
  # initialized.
  #
  # @param name [Symbol] event namespace
  # @param label [String] optional label for logging
  # @return [Rails::Railtie, ActiveSupport::LogSubscriber] An array consisting
  #   of a Railtie and a LogSubscriber
  # @yield event subscription
  #
  # ==== Examples
  #
  #  SweetNotifications.subscribe :active_record do
  #    color ActiveSupport::LogSubscriber::GREEN
  #    event :sql, runtime: true do |event|
  #      return unless logger.debug?
  #      debug message(event, event.payload[:name], event.payload[:sql])
  #    end
  #  end
  def self.subscribe(name, label: nil, &block)
    label ||= name
    log_subscriber = Class.new(SweetNotifications::LogSubscriber, &block)
    controller_runtime = self.controller_runtime(label, log_subscriber)
    if Rails.respond_to?(:application) && Rails.application && Rails.application.initialized?
      initialize_rails(name, log_subscriber, controller_runtime)
      [nil, log_subscriber]
    else
      [railtie(name, log_subscriber, controller_runtime), log_subscriber]
    end
  end
end
