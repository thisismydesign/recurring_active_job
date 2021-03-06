# RecurringActiveJob

#### Dynamic recurring ActiveJob scheduler based on time spent between executions

<!--- Version informartion -->
*You are viewing the README of the development version. You can find the README of the latest release (v0.4.0) [here](https://github.com/thisismydesign/recurring_active_job/releases/tag/v0.4.0).*
<!--- Version informartion end -->

| Branch | Status |
| ------ | ------ |
| Release | [![Build Status](https://travis-ci.org/thisismydesign/recurring_active_job.svg?branch=release)](https://travis-ci.org/thisismydesign/recurring_active_job)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/recurring_active_job/badge.svg?branch=release)](https://coveralls.io/github/thisismydesign/recurring_active_job?branch=release)   [![Gem Version](https://badge.fury.io/rb/recurring_active_job.svg)](https://badge.fury.io/rb/recurring_active_job)   [![Total Downloads](http://ruby-gem-downloads-badge.herokuapp.com/recurring_active_job?type=total)](https://rubygems.org/gems/recurring_active_job) |
| Development | [![Build Status](https://travis-ci.org/thisismydesign/recurring_active_job.svg?branch=master)](https://travis-ci.org/thisismydesign/recurring_active_job)   [![Coverage Status](https://coveralls.io/repos/github/thisismydesign/recurring_active_job/badge.svg?branch=master)](https://coveralls.io/github/thisismydesign/recurring_active_job?branch=master) |

## Features

- Adapter agnostic scheduling via ActiveJob
- Dynamic management (rather than via predefined configuration)
- Doesn't require its own worker or service

Scheduling is based on time spent between extecutions. This is useful for
  - Running jobs constantly without delay in between
  - Running jobs again some time after their execution
  - Jobs where the execution time might be longer than the recurring timeframe but you *don't* want to trigger multiple jobs at once

#### Example use case

10 minute `RecurringActiveJob` recurrence schedule for a 5 minute job means it runs 10 minutes after the previous run finished:
  - Run#1 00:00 - 00:05
  - Run#2 00:15 - 00:20

*As opposed to* regular scheduling:
  - Run#1 00:00 - 00:05
  - Run#2 00:10 - 00:15

## Alternatives

[resque-scheduler](https://github.com/resque/resque-scheduler#dynamic-schedules) provides regular dynamic scheduling (and more) and with a bit of tweaking [it can also support ActiveJob](https://stackoverflow.com/a/48551550/2771889). The drawback being the mandatory dependency on Resque (and therefore Redis) and having to run it as a separate service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'recurring_active_job'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install recurring_active_job

## Setup

Recurring jobs are stored in the DB therefore we need the following migration:

```bash
bin/rails generate migration CreateRecurringActiveJob
```

`*_create_recurring_active_job.rb`
```ruby
def change
  create_table :recurring_active_jobs do |t|
    t.string :job_id
    t.string :provider_job_id
    t.boolean :active, default: true, null: false
    t.integer :frequency_seconds, default: 600, null: false
    t.boolean :auto_delete, default: true, null: false
    t.string :last_error
    t.text :last_error_details

    t.timestamps
  end

  add_index :recurring_active_jobs, :job_id, unique: true
  add_index :recurring_active_jobs, :provider_job_id, unique: true
end
```

## Usage

Jobs need to subclass `RecurringActiveJob::Base` instead of `ActiveJob::Base`:

```ruby
class MyRecurringJob < RecurringActiveJob::Base
  def perform(*args)
    puts "hi"
  end
end
```

Create a `RecurringActiveJob::Model` record and pass its ID when performing the job:

```ruby
recurring_active_job = RecurringActiveJob::Model.create!(frequency_seconds: 10)

MyRecurringJob.perform_later(recurring_active_job_id: recurring_active_job.id)
```

### Testing

Make sure that the class properly inherits:

```ruby
describe MyJob
  it "is a RecurringActiveJob" do
    expect(described_class).to be < RecurringActiveJob::Base
  end
end
```

Add a shared context to be included when testing Recurring jobs:

`spec/support/shared_context_for_recurring_active_job.rb`
```ruby
RSpec.shared_context "recurring active job" do
  let(:recurring_active_job) { create(:recurring_active_job) }
  let(:recurring_active_job_params) { { recurring_active_job_id: recurring_active_job.id } }

  before do
    allow(RecurringActiveJob::Model).to receive(:find).and_return(recurring_active_job)
  end
end
```

```ruby
RSpec.describe MyJob do
  describe "#perform" do
    include_context "recurring active job"
    # ...
  end
end
```

### Custom error handling

`RecurringActiveJob` defines the following generic error handling which is required for some features (but raises the original error at the end):

```ruby
rescue_from(StandardError) do |e|
  handle_exception(e)
end
```

To define your own error handling but keep those features working you can redefine `handle_exception` like this:

```ruby
rescue_from(StandardError) do |e|
  handle_exception(e)
end

# ...

def handle_exception(e)
  super rescue StandardError

  # ...
end
```

## Feedback

Feedback is appreciated.

I can only tailor this project to fit use-cases I know about - which are usually my own ones. If you find that this might be the right direction to solve your problem too but you find that it's suboptimal or lacks features don't hesitate to contact me.

## Conventions

This gem is developed using the following conventions:
- [Bundler's guide for developing a gem](http://bundler.io/v1.14/guides/creating_gem.html)
- [Better Specs](http://www.betterspecs.org/)
- [Semantic versioning](http://semver.org/)
- [RubyGems' guide on gem naming](http://guides.rubygems.org/name-your-gem/)
- [RFC memo about key words used to Indicate Requirement Levels](https://tools.ietf.org/html/rfc2119)
- [Bundler improvements](https://github.com/thisismydesign/bundler-improvements)
- [Minimal dependencies](http://www.mikeperham.com/2016/02/09/kill-your-dependencies/)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thisismydesign/recurring_active_job.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
