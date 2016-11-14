# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/unique_scheduler/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-unique_scheduler"
  spec.version       = Sidekiq::UniqueScheduler::VERSION
  spec.authors       = ["SHIBATA Hiroshi"]
  spec.email         = ["hsbt@ruby-lang.org"]

  spec.summary       = %q{Auto detect unique scheduler for sidekiq-scheduler.}
  spec.description   = %q{Auto detect unique scheduler for sidekiq-scheduler.}
  spec.homepage      = "https://github.com/hsbt/sidekiq-unique_scheduler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_dependency "diplomat"
  spec.add_dependency 'sidekiq-scheduler'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha"
end
