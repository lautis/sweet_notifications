require 'test_helper'

describe SweetNotifications do
  include ActiveSupport::LogSubscriber::TestHelper

  describe '.subscribe' do
    it 'creates a railtie' do
      railtie, _ = SweetNotifications.subscribe 'railtie_create' do
      end
      assert railtie < Rails::Railtie
    end

    it 'initializes a log subscriber' do
      _, log_subscriber = SweetNotifications.subscribe 'subscriber_create' do
        event :foo, runtime: true
      end
      assert log_subscriber < ActiveSupport::LogSubscriber
      assert log_subscriber.new.public_methods(false).include?(:foo)
    end

    it 'binds log subscriber to notifications' do
      railtie, _ = SweetNotifications.subscribe 'sweet' do
        event :test do |event|
          info message(event, 'Test', 'blah blah')
        end
      end

      railtie.run_initializers
      ActiveSupport::Notifications.instrument 'test.sweet' do
        'ok'
      end
      assert_match(/Test \(\d\.\d{2}ms\)  blah blah/, @logger.logged(:info)[0])
    end

    it 'binds to current Rails app directly when the app is initialized' do
      module ::Rails
        def self.application
          Struct.new(:initialized?).new(true)
        end
      end

      railtie, _ = SweetNotifications.subscribe 'sweet' do
        event :direct do |event|
          info message(event, 'Direct', 'foo bar')
        end
      end

      assert_equal nil, railtie
      module ::Rails
        class << self
          undef application
        end
      end
      ActiveSupport::Notifications.instrument 'direct.sweet' do
        'ok'
      end
      assert_match(/Direct \(\d\.\d{2}ms\)  foo bar/, @logger.logged(:info)[0])
    end
  end
end
