require 'active_support/log_subscriber'
require 'request_store'
require 'securerandom'

module SweetNotifications
  # LogSubscriber with runtime calculation and improved logging
  class LogSubscriber < ActiveSupport::LogSubscriber
    class_attribute :odd_color, :even_color

    def initialize
      super
      @odd = false
    end

    # Format a message for logging
    #
    # @param event [ActiveSupport::Notifications::Event] subscribed event
    # @param label [String] label for log messages
    # @param body [String] the rest
    # @return [String] formatted message for logging
    #
    # ==== Examples
    #
    #  event :test do |event|
    #    message(event, 'Test', 'message body')
    #  end
    #  # => "  Test (0.00ms)  message body"
    def message(event, label, body)
      @odd = !@odd
      label_color = @odd ? odd_color : even_color

      format(
        '  %s (%.2fms)  %s',
        color(label, label_color, self.class.as_7_1_or_upper? ? { bold: true } : true),
        event.duration,
        color(body, nil, self.class.as_7_1_or_upper? ? { bold: !@odd } : !@odd)
      )
    end

    class << self
      # Store aggregated runtime form request specific store
      def runtime=(value)
        RequestStore.store["#{@name}_runtime"] = value
      end

      # Fetch aggregated runtime form request specific store
      def runtime
        RequestStore.store["#{@name}_runtime"] || 0
      end

      # Reset aggregated runtime
      #
      # @return Numeric previous runtime value
      def reset_runtime
        rt = runtime
        self.runtime = 0
        rt
      end

      # Set colors for logging title and duration
      def color(odd, even = nil)
        self.odd_color = odd
        self.even_color = even || odd
      end

      # Define an event subscriber
      #
      # @param command [Symbol] event name
      # @param runtime [Boolean] aggregate runtime for this event
      # @yield [ActiveSupport::Notifications::Event] handle event
      def event(command, runtime: true, &block)
        define_method command do |event|
          self.class.runtime += event.duration if runtime
          instance_exec(event, &block) if block
        end
      end

      def as_7_1_or_upper?
        return @as_7_1_or_upper if defined?(@as_7_1_or_upper)

        @as_7_1_or_upper =
          Gem::Version.new(ActiveSupport::VERSION::STRING) >= Gem::Version.new('7.1.0')
      end

      protected

      def inherited(base)
        super
        base.class_eval do
          @name ||= SecureRandom.hex
        end
      end
    end
  end
end
