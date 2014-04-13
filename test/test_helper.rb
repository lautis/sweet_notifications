ENV['RAILS_ENV'] = 'test'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'sweet_notifications'

class ActiveSupport::TestCase
  extend MiniTest::Spec::DSL
  register_spec_type self
end
