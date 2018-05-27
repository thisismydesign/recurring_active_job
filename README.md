# RecurringActiveJob

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/recurring_active_job`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'recurring_active_job'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install recurring_active_job

## Usage

```bash
bin/rails generate migration CreateRecurringActiveJob
```

`*_create_recurring_active_job.rb`
```
def change
  create_table :recurring_active_jobs do |t|
    t.string :job_id
    t.string :provider_job_id
    t.boolean :active, default: true, null: false
    t.integer :frequency_seconds, default: 600, null: false

    t.timestamps
  end

  add_index :recurring_active_jobs, :job_id, unique: true
  add_index :recurring_active_jobs, :provider_job_id, unique: true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/recurring_active_job.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
