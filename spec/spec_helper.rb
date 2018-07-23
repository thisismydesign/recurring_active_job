require "bundler/setup"
require 'rake'

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

# Use rspec-rails for testing ActiveJob
# Requiring `active_record/railtie` is necessary, see: https://github.com/rspec/rspec-rails/issues/1690
require "active_record/railtie"
require "rspec/rails"

require "timecop"

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
ActiveJob::Base.logger = nil

RSPEC_ROOT = File.dirname __FILE__
Dir[Pathname.new(RSPEC_ROOT).join("support", "**", "*.rb")].each { |f| require f }

environment = "development"
class Seeder; def load_seed; end; end
# Root path has to be execution path, see: https://github.com/rails/rails/issues/32910
# Config is expected at `#{root}/config/database.yml`
# If the issue above is fixed it can be moved to `#{root}/spec/example_project/config/database.yml`
root = Pathname.new(".")
db_config = root.join("config", "database.yml")
db_dir = root.join("config")
config = YAML::load(ERB.new(File.read(db_config)).result)
load_active_record_tasks(database_configuration: config, root: root, db_dir: db_dir, seed_loader: Seeder.new)
ENV["DISABLE_DATABASE_ENVIRONMENT_CHECK"] = "1"
Rake::Task["db:migrate:reset"].invoke

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
