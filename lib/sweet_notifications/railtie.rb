require 'rails/railtie'

module SweetNotifications
  # Rails Railtie integration
  module Railtie
    extend self
    # Attach LogSubscriber and ControllerRuntime to a notifications namespace
    #
    # @param name [Symbol] Notifications namespace
    # @param log_subscriber [LogSubscriber] subscriber to be attached
    # @param controller_runtime [Module] mixin that logs runtime
    def initialize_rails(name, log_subscriber, controller_runtime)
      log_subscriber.attach_to name.to_sym
      ActiveSupport.on_load(:action_controller) do
        include controller_runtime
      end
    end

    # Create a Railtie for LogSubscriber and ControllerRuntime mixin
    #
    # @param name [Symbol] Notifications namespace
    # @param log_subscriber [LogSubscriber] subscriber to be attached
    # @param controller_runtime [Module] mixin that logs runtime
    # @return [Rails::Railtie] Rails initializer
    def railtie(name, log_subscriber, controller_runtime)
      Class.new(Rails::Railtie) do
        railtie_name name
        initializer "#{name}.notifications" do
          SweetNotifications::Railtie.initialize_rails(name,
                                                       log_subscriber,
                                                       controller_runtime)
        end
      end
    end
  end
end
