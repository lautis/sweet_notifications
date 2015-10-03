require 'test_helper'

describe SweetNotifications::ControllerRuntime do
  class TestLogSubscriber < SweetNotifications::LogSubscriber
  end

  ControllerRuntime = SweetNotifications.controller_runtime('Test',
                                                            TestLogSubscriber)
  ActionController::Base.send :include, ControllerRuntime

  class LogSubscribersController < ActionController::Base
    def create
      TestLogSubscriber.runtime += 100
      render_text '100'
    end

    def show
      render_text '0'
    end

    def destroy
      TestLogSubscriber.runtime += 50
      render_text 'OK'
      TestLogSubscriber.runtime += 5
    end

    private

    def render_text(text)
      if Gem.loaded_specs['rails'].version < Gem::Version.new('4.2')
        render text: text
      else
        render plain: text
      end
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

  # rubocop:disable AccessorMethodName
  def set_logger(logger)
    ActionController::Base.logger = logger
  end
  # rubocop:enable AccessorMethodName

  describe '.log_process_action' do
    it 'emits runtime to log messages' do
      out = LogSubscribersController.log_process_action(test_runtime: 1234)
      assert_equal('Test: 1234.0ms', out[0])
    end
  end

  describe 'runtime logging' do
    it 'does not append runtime when it is 0' do
      get :show, params: { id: 1 }
      wait
      assert_no_match(/Test:/, @logger.logged(:info)[2])
    end

    it 'appends non-zero runtime' do
      post :create, params: { test: 1 }
      wait
      expected_message = /\(Views: [\d.]+ms \| Test: 100.0ms\)/
      assert_match(expected_message, @logger.logged(:info)[2])
    end

    it 'resets runtime before request' do
      TestLogSubscriber.runtime += 1000
      post :create, params: { test: 1 }
      wait
      expected_message = /\(Views: [\d.]+ms \| Test: 100.0ms\)/
      assert_match(expected_message, @logger.logged(:info)[2])
    end

    it 'includes runtime after render' do
      post :destroy, params: { id: 1 }
      wait
      expected_message = /\(Views: [\d.]+ms \| Test: 55.0ms\)/
      assert_match(expected_message, @logger.logged(:info)[2])
    end
  end
end
