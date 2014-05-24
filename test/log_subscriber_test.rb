require 'test_helper'
require 'active_support/log_subscriber/test_helper'

describe SweetNotifications::LogSubscriber do
  include ActiveSupport::LogSubscriber::TestHelper

  def event(name: 'Test', duration: 1, transaction_id: SecureRandom.hex, payload: {})
    now = Time.now
    ActiveSupport::Notifications::Event.new(name,
                                            now,
                                            now + duration,
                                            transaction_id,
                                            payload)
  end

  describe '#event' do
    it 'creates event listener for event' do
      class LogSubscriber < SweetNotifications::LogSubscriber
        event :test
      end
      assert LogSubscriber.new.respond_to?(:test)
    end

    it 'proxies messages to Rails logger' do
      class LoggingLogSubscriber < SweetNotifications::LogSubscriber
        event :test_event do
          'test, 1-2-3'
        end
      end
      log_subscriber = LoggingLogSubscriber.new
      log_subscriber.test_event(event)
      assert_equal ['test, 1-2-3'], @logger.logged(:debug)
    end

    it 'uses given log level' do
      class LeveledLogSubscriber < SweetNotifications::LogSubscriber
        event :debug_event, log_level: :debug do
          'debug'
        end
        event :info_event, log_level: :info do
          'info'
        end
        event :warn_event, log_level: :warn do
          'warn'
        end
      end
      log_subscriber = LeveledLogSubscriber.new
      log_subscriber.debug_event(event)
      log_subscriber.info_event(event)
      log_subscriber.warn_event(event)
      assert_equal %w(debug), @logger.logged(:debug)
      assert_equal %w(info), @logger.logged(:info)
      assert_equal %w(warn), @logger.logged(:warn)
    end

    it 'increments runtime when asked to' do
      class RuntimeLogSubscriber < SweetNotifications::LogSubscriber
        event :runtime_event, runtime: true do
          'debug'
        end

        event :no_runtime_event, runtime: false do
          'info'
        end
      end

      log_subscriber = RuntimeLogSubscriber.new
      log_subscriber.runtime_event(event(duration: 5))
      assert_equal 5000.0, RuntimeLogSubscriber.runtime
      log_subscriber.no_runtime_event(event(duration: 10))
      assert_equal 5000.0, RuntimeLogSubscriber.runtime
    end

    it 'does not log anything when not given block' do
      class MuteLogSubscriber < SweetNotifications::LogSubscriber
        event :mute_event, runtime: true, log_level: :info
      end
      log_subscriber = MuteLogSubscriber.new
      log_subscriber.mute_event(event(duration: 5))
      assert_equal [], @logger.logged(:info)
    end
  end

  describe '#runtime' do
    it 'can be incremented' do
      log_subscriber = Class.new(SweetNotifications::LogSubscriber)
      assert_equal 0, log_subscriber.runtime
      log_subscriber.runtime += 1.2
      assert_equal 1.2, log_subscriber.runtime
    end

    it 'does not share runtime across subscribers' do
      first = Class.new(SweetNotifications::LogSubscriber)
      second = Class.new(SweetNotifications::LogSubscriber)

      first.runtime += 100
      second.runtime += 200
      refute_equal first.runtime, second.runtime
    end
  end

  describe '#reset_runtime' do
    before :each do
      @log_subscriber = Class.new(SweetNotifications::LogSubscriber)
      @log_subscriber.runtime = 2000
    end

    it 'returns the current runtime' do
      assert_equal 2000, @log_subscriber.reset_runtime
    end

    it 'sets the current runtime to 0' do
      @log_subscriber.reset_runtime
      assert_equal 0, @log_subscriber.runtime
    end
  end
end
