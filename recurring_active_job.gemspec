lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "recurring_active_job/version"

Gem::Specification.new do |spec|
  spec.name          = "recurring_active_job"
  spec.version       = RecurringActiveJob::VERSION
  spec.authors       = ["thisismydesign"]
  spec.email         = ["git.thisismydesign@gmail.com"]

  spec.summary       = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 5.0.0" # Usage of `retry_on`
  spec.add_dependency "activerecord"

  spec.add_development_dependency "sqlite3"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rspec-rails', '~> 3.7'
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "autowow"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency 'factory_bot_rails', ">= 4.8.1" # https://github.com/thoughtbot/factory_bot/pull/982
end
