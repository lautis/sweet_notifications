require 'sweet_notifications/version'
require 'sweet_notifications/log_subscriber'
require 'sweet_notifications/controller_runtime'
require 'sweet_notifications/railtie'

module SweetNotifications
  extend ControllerRuntime
  extend Railtie
  def self.subscribe(name, &block)
    log_subscriber = Class.new(SweetNotifications::LogSubscriber, &block)
    controller_runtime = self.controller_runtime(name, log_subscriber)
    if Rails.try(:application).try(:initialized?)
      self.initialize_rails(name, log_subscriber, controller_runtime)
      [nil, log_subscriber]
    else
      [self.railtie(name, log_subscriber, controller_runtime), log_subscriber]
    end
  end
end
