require 'rails/railtie'

module SweetNotifications
  module Railtie
    def railtie(name, log_subscriber, controller_runtime)
      Class.new(Rails::Railtie) do
        railtie_name name
        initializer "#{name}.notifications" do
          log_subscriber.attach_to name.to_sym
          ActiveSupport.on_load(:action_controller) do
            include controller_runtime
          end
        end
      end
    end
  end
end
