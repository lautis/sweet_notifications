require 'request_store'
require 'securerandom'

module SweetNotifications
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.inherited(base)
      base.class_eval do
        @name ||= SecureRandom.hex
      end
    end

    class << self
      def runtime=(value)
        RequestStore.store["#{@name}_runtime"] = value
      end

      def runtime
        RequestStore.store["#{@name}_runtime"] || 0
      end

      def reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end

      def event(command, log_level: :debug, runtime: true, &block)
        define_method command do |event|
          self.class.runtime += event.duration if runtime
          send(log_level, block.call(event))
        end
      end
    end
  end
end
