require 'request_store'
require 'securerandom'

module SweetNotifications
  class LogSubscriber < ActiveSupport::LogSubscriber
    class_attribute :odd_color, :even_color

    def message(event, label, body)
      @odd = !@odd
      label_color = @odd ? odd_color : even_color

      "%s (%.2fms)  %s" % [
        color(label, label_color, true),
        event.duration,
        color(body, nil, @odd)
      ]
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

      # Set colors for logging title and duration
      def color(even, odd = nil)
        self.even_color = even
        self.odd_color = odd || even
      end

      def event(command, runtime: true, &block)
        define_method command do |event|
          self.class.runtime += event.duration if runtime
          instance_exec(event, &block) if block
        end
      end

      def inherited(base)
        base.class_eval do
          @name ||= SecureRandom.hex
        end
      end
    end
  end
end
