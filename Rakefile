require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

begin
  require 'rubocop/rake_task'
  desc 'Check for code style'
  RuboCop::RakeTask.new
  task default: %i[test rubocop]
rescue LoadError
  task default: %i[test]
end
