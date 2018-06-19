require "bundler/setup"

def ran_by_guard
  ARGV.any? {|e| e =~ /guard-rspec/ }
end

unless ran_by_guard
  require 'simplecov'
  SimpleCov.add_filter ['spec', 'config']
  require "coveralls"
  Coveralls.wear!
end

require "recurring_active_job"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSPEC_ROOT = File.dirname __FILE__
