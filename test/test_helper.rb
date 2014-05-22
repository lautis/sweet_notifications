ENV['RAILS_ENV'] = 'test'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'sweet_notifications'

class ActiveSupport::TestCase
  class << self
    remove_method :describe
  end

  extend MiniTest::Spec::DSL
  register_spec_type /ControllerRuntime$/, ActionController::TestCase
  register_spec_type self
end
