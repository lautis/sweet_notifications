require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'yard'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

desc 'Check for code style'
RuboCop::RakeTask.new

task default: [:test, :rubocop]
