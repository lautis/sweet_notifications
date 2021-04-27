require 'test_helper'

class SweetNotificationsController < ActionController::Base
  def index
    ActiveSupport::Notifications.instrument 'test.controller' do
      'ok'
    end

    if rails_version?('< 4.2')
      render text: 'ok'
    else
      render plain: 'ok'
    end
  end
end

describe SweetNotifications do
  include ActiveSupport::LogSubscriber::TestHelper
  tests SweetNotificationsController

  before do
    if rails_version?('>= 5.0')
      ActionController::TestRoutes.draw do
        resources :sweet_notifications
      end
    end
  end

  describe '.subscribe' do
    it 'creates a railtie' do
      railtie, = SweetNotifications.subscribe 'railtie_create' do
        # empty block
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
      railtie, = SweetNotifications.subscribe 'sweet' do
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

      railtie, = SweetNotifications.subscribe 'sweet' do
        event :direct do |event|
          info message(event, 'Direct', 'foo bar')
        end
      end

      assert_nil railtie

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

    it 'logs to Rails logger' do
      railtie, = SweetNotifications.subscribe 'controller', label: 'Label' do
        event :test, runtime: true do |event|
          info message(event, 'Test', 'logging')
        end
      end
      railtie.run_initializers

      get :index
      wait
      assert_match(/Test \(\d\.\d{2}ms\)  logging/, @logger.logged(:info)[0])
      out = ActionController::Base.log_process_action(label_runtime: 1234)
      assert_match(/Label: 1234\.0ms/, out[0])
    end
  end
end
