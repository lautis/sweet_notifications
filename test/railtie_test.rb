require 'active_support/test_case'
require 'active_support/log_subscriber/test_helper'
require 'test_helper'
require 'securerandom'

describe SweetNotifications::Railtie do
  it 'has a railtie name' do
    railtie = SweetNotifications.railtie('test_railtie', nil, nil)
    assert_equal 'test_railtie', railtie.railtie_name
  end

  describe 'initializer' do
    it 'adds an initializer' do
      railtie = SweetNotifications.railtie('log_subscriber', nil, nil)
      assert_equal 1, railtie.initializers.length
    end

    it 'attaches log subscriber to namespace' do
      mock = MiniTest::Mock.new
      mock.expect :attach_to, true, [:log_subscriber]
      railtie = SweetNotifications.railtie('log_subscriber', mock, Module.new)
      railtie.run_initializers
      assert mock.verify
    end

    it 'injects controller runtime to ActionController::Base' do
      log_subscriber = Class.new(SweetNotifications::LogSubscriber)
      controller_runtime = SweetNotifications.controller_runtime('test', log_subscriber)
      railtie = SweetNotifications.railtie('test', log_subscriber, controller_runtime)
      railtie.run_initializers
      assert_includes ActionController::Base.ancestors, controller_runtime
    end
  end
end
