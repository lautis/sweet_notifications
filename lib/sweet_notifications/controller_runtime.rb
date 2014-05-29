require 'active_support/concern'
require 'active_support/core_ext/module/attr_internal'

module SweetNotifications
  # Controller runtime tracking
  module ControllerRuntime
    # Define a controller runtime logger for a LogSusbcriber
    #
    # @param name [String] title for logging
    # @return [Module] controller runtime tracking mixin
    def controller_runtime(name, log_subscriber)
      runtime_attr = "#{name.to_s.underscore}_runtime".to_sym
      Module.new do
        extend ActiveSupport::Concern
        attr_internal runtime_attr

        protected

        define_method :process_action do |action, *args|
          log_subscriber.reset_runtime
          super(action, *args)
        end

        define_method :cleanup_view_runtime do |&block|
          runtime_before_render = log_subscriber.reset_runtime
          send("#{runtime_attr}=", (send(runtime_attr) || 0) + runtime_before_render)
          runtime = super(&block)
          runtime_after_render = log_subscriber.reset_runtime
          send("#{runtime_attr}=", send(runtime_attr) + runtime_after_render)
          runtime - runtime_after_render
        end

        define_method :append_info_to_payload do |payload|
          super(payload)
          payload[runtime_attr] = (send(runtime_attr) || 0) + log_subscriber.reset_runtime
        end

        const_set(:ClassMethods, Module.new do
          define_method :log_process_action do |payload|
            messages, runtime = super(payload), payload[runtime_attr]
            messages << ("#{name}: %.1fms" % runtime.to_f) if runtime && runtime != 0
            messages
          end
        end)
      end
    end
  end
end
