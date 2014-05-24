require 'active_support/test_case'
require 'active_support/log_subscriber'
require 'active_support/log_subscriber/test_helper'
require 'action_controller/log_subscriber'
require 'action_controller'
require 'test_helper'
require 'securerandom'

describe SweetNotifications::ControllerRuntime do
  class TestLogSubscriber < SweetNotifications::LogSubscriber
  end

  ControllerRuntime = SweetNotifications.controller_runtime('Test', TestLogSubscriber)
  ActionController::Base.send :include, ControllerRuntime

  class LogSubscribersController < ActionController::Base
    def create
      TestLogSubscriber.runtime += 100
      render text: '100'
    end

    def show
      render text: '0'
    end

    def destroy
      TestLogSubscriber.runtime += 50
      render text: 'OK'
      TestLogSubscriber.runtime += 5
    end
  end

  include ActiveSupport::LogSubscriber::TestHelper
  tests LogSubscribersController

  before do
    @old_logger = ActionController::Base.logger
    ActionController::LogSubscriber.attach_to :action_controller
  end

  after do
    ActiveSupport::LogSubscriber.log_subscribers.clear
    ActionController::Base.logger = @old_logger
  end

  def set_logger(logger)
    ActionController::Base.logger = logger
  end

  describe '.log_process_action' do
    it 'emits runtime to log messages' do
      messages = LogSubscribersController.log_process_action(test_runtime: 1234)
      assert_equal("Test: 1234.0ms", messages[0])
    end
  end

  describe 'runtime logging' do
    it 'does not append runtime when it is 0' do
      get :show, id: 1
      wait
      assert_no_match(/Test:/, @logger.logged(:info)[2])
    end

    it 'appends non-zero runtime' do
      post :create, test: 1
      wait
      assert_match(/\(Views: [\d.]+ms \| Test: 100.0ms\)/, @logger.logged(:info)[2])
    end

    it 'resets runtime before request' do
      TestLogSubscriber.runtime += 1000
      post :create, test: 1
      wait
      assert_match(/\(Views: [\d.]+ms \| Test: 100.0ms\)/, @logger.logged(:info)[2])
    end

    it 'includes runtime after render' do
      post :destroy, id: 1
      wait
      assert_match(/\(Views: [\d.]+ms \| Test: 55.0ms\)/, @logger.logged(:info)[2])
    end
  end
end
