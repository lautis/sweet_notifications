# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sweet_notifications/version'

Gem::Specification.new do |spec|
  spec.name          = "sweet_notifications"
  spec.version       = SweetNotifications::VERSION
  spec.authors       = ["Ville Lautanala"]
  spec.email         = ["lautis@gmail.com"]
  spec.summary       = %q{Syntactic sugar for ActiveSupport::LogSubscriber.}
  spec.description   = %q{Syntactic sugar for ActiveSupport::LogSubscriber for easy instrumentation and logging from third-party libraries.}
  spec.homepage      = "https://github.com/lautis/sweet_notifications"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency "activesupport", ">= 4.0", "< 6"
  spec.add_runtime_dependency "request_store", "~> 1.0"
  spec.add_runtime_dependency "railties", ">= 4.0", "< 6"
  spec.add_development_dependency "actionpack", ">= 4.0", "< 6"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake", "~> 10.3"
  spec.add_development_dependency "yard", "~> 0.8.7"
  spec.add_development_dependency "appraisal", "~> 2.0"
  spec.add_development_dependency "simplecov", "~> 0.10.0"
  spec.add_development_dependency "rubocop", "~> 0.34.0"
end
