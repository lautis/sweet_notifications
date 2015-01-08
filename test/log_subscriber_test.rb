require 'test_helper'

describe SweetNotifications::LogSubscriber do
  include ActiveSupport::LogSubscriber::TestHelper

  def event(name: 'Test', duration: 1, transaction_id: SecureRandom.hex,
            payload: {})
    now = Time.now
    ActiveSupport::Notifications::Event.new(name,
                                            now,
                                            now + duration,
                                            transaction_id,
                                            payload)
  end

  describe '.event' do
    it 'creates event listener for event' do
      class LogSubscriber < SweetNotifications::LogSubscriber
        event :test
      end
      assert LogSubscriber.new.respond_to?(:test)
    end

    it 'proxies messages to Rails logger' do
      class LoggingLogSubscriber < SweetNotifications::LogSubscriber
        event :test_event do
          debug 'test, 1-2-3'
        end
      end
      log_subscriber = LoggingLogSubscriber.new
      log_subscriber.test_event(event)
      assert_equal ['test, 1-2-3'], @logger.logged(:debug)
    end

    it 'increments runtime when asked to' do
      class RuntimeLogSubscriber < SweetNotifications::LogSubscriber
        event :runtime_event, runtime: true
        event :no_runtime_event, runtime: false
      end

      log_subscriber = RuntimeLogSubscriber.new
      log_subscriber.runtime_event(event(duration: 5))
      assert_equal 5000.0, RuntimeLogSubscriber.runtime
      log_subscriber.no_runtime_event(event(duration: 10))
      assert_equal 5000.0, RuntimeLogSubscriber.runtime
    end

    it 'does not log anything when not given block' do
      class MuteLogSubscriber < SweetNotifications::LogSubscriber
        event :mute_event, runtime: true
      end
      log_subscriber = MuteLogSubscriber.new
      log_subscriber.mute_event(event(duration: 5))
      assert_equal [], @logger.logged(:info)
      assert_equal [], @logger.logged(:debug)
    end

    it 'listens to events when attached to a namespace' do
      class AttachedLogSubscriber < SweetNotifications::LogSubscriber
        event :important_stuff, runtime: true do
          info 'received!'
        end
      end
      AttachedLogSubscriber.attach_to :namespace
      ActiveSupport::Notifications.instrument 'important_stuff.namespace' do
        'OK'
      end
      assert_equal ['received!'], @logger.logged(:info)
    end
  end

  describe '.runtime' do
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

  describe '.reset_runtime' do
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

  describe '#message' do
    class MessageLogSubscriber < SweetNotifications::LogSubscriber
      color ActiveSupport::LogSubscriber::CYAN,
            ActiveSupport::LogSubscriber::MAGENTA
    end

    subject { MessageLogSubscriber.new }

    it 'uses given colors for title' do
      subject.colorize_logging = true
      odd = subject.message(event, 'Label', 'body')
      even = subject.message(event, 'Label', 'body')
      assert_match ActiveSupport::LogSubscriber::CYAN, odd
      assert_match ActiveSupport::LogSubscriber::MAGENTA, even
    end

    it 'uses only one color when alternate color is not defined' do
      subject = Class.new(SweetNotifications::LogSubscriber) do
        color ActiveSupport::LogSubscriber::CYAN
      end.new
      subject.colorize_logging = true
      assert_match(ActiveSupport::LogSubscriber::CYAN,
                   subject.message(event, 'Label', 'body'))

      assert_match(ActiveSupport::LogSubscriber::CYAN,
                   subject.message(event, 'Label', 'body'))
    end

    it 'alternates between bold and normal body text' do
      subject.colorize_logging = true
      odd = subject.message(event, 'Label', 'body')
      even = subject.message(event, 'Label', 'body')
      assert !odd.include?(ActiveSupport::LogSubscriber::BOLD + 'body')
      assert even.include?(ActiveSupport::LogSubscriber::BOLD + 'body')
    end

    it 'does not use colors when setting is disabled' do
      subject.colorize_logging = false
      message = subject.message(event, 'Label', 'body')
      assert !message.include?(ActiveSupport::LogSubscriber::CYAN)
    end
  end
end
