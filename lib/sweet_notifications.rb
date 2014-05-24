require 'sweet_notifications/version'
require 'sweet_notifications/log_subscriber'
require 'sweet_notifications/controller_runtime'
require 'sweet_notifications/railtie'

module SweetNotifications
  extend ControllerRuntime
  extend Railtie
end
