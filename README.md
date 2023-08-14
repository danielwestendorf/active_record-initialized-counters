# Activerecord::InitializedCounter

Track the number of times an instance of an ActiveRecord model is initialized in a Rack Request or ActiveJob execution.

## What problem does this solve?

It doesn't solve a problem. It helps you identify a problem. It is also implemented in a way intended to be production-safe, as these problems

Consider the following database structure:

```ruby
# app/models/airport.rb
class Airport < ApplicationRecord
    has_many :concourses

    def very_expensive_memoized_call
        @very_expensive_memoized_call ||= true.tap do
            puts "sleeping once until memoized"
            # Maybe this is an expensive SQL query
            # Or a network request
            # Or a CPU heavy task
            sleep 10
        end
    end
end

# app/models/concourse.rb
class Concourse < ApplicationRecord
    belongs_to :airport

    has_many :terminals
end

# app/models/terminal.rb
class Terminal < ApplicationRecord
    belongs_to :concourse
    has_one :airport, through: :concourse
end

```

Now consider the potential code path:

```ruby
Concourse.find(1).terminals.limit(10).each { |terminal| terminal.airport }; nil

Concourse Load (5.4ms)  SELECT "concourses".* FROM "concourses" WHERE "concourses"."id" = 1 LIMIT 1
Terminal Load (2.3ms)  SELECT "terminals".* FROM "terminals" WHERE "terminals"."concourse_id" = 1 LIMIT 10
Airport Load (5.6ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.2ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.3ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.2ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.6ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.0ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.1ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (2.0ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (1.9ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
Airport Load (3.2ms)  SELECT "airports".* FROM "airports" INNER JOIN "concourses" ON "airports"."id" = "concourses"."airport_id" WHERE "concourses"."id" = 1 LIMIT 1
sleeping once until memoized
nil
```

Not only are we generating a SQL call every time we call `Terminal#airport` we also allocate new instances of the same `Airport` record bypassing our memoization optimization.

Couple this with iteration and additional iteration method chaining and we quickly start feeling some performance pain.

#### What about ActiveRecord's SQL caching?

Yes, in production, your SQL queries are likely hitting the ActiveRecord SQL cache, which is often faster than an actual SQL query. Hitting the SQL cache is not, free, however.

#### Okay, but how would I improve this?
1. Use `strict_loading` a la `has_one :airport, through: :concourse, strict_loading: true`

```diff
-- has_one :airport, through: :concourse
++ has_one :airport, through: :concourse, strict_loading: true
```

```ruby
Concourse.find(1).terminals.limit(10).each { |terminal| terminal.airport }; nil
  Concourse Load (1.2ms)  SELECT "concourses".* FROM "concourses" WHERE "concourses"."id" = 1 LIMIT 1
  Terminal Load (0.9ms)  SELECT "terminals".* FROM "terminals" WHERE "terminals"."concourse_id" = 1 LIMIT 10
ActiveRecord::StrictLoadingViolationError: `Terminal` is marked for strict_loading. The Airport association named `:airport` cannot be lazily loaded.
from /path/to/ruby/activerecord-7.0.6/lib/active_record/core.rb:242:in `strict_loading_violation!'
```

This would force you to use `includes` or `eager_load`.
```ruby
Concourse.find(1).terminals.includes(:airport).limit(10).each { |terminal| terminal.airport }; nil
Concourse Load (4.2ms)  SELECT "concourses".* FROM "concourses" WHERE "concourses"."id" = 1 LIMIT 1
Terminal Load (2.7ms)  SELECT "terminals".* FROM "terminals" WHERE "terminals"."concourse_id" = 1 LIMIT 10
Airport Load (3.3ms)  SELECT "airports".* FROM "airports" WHERE "airports"."id" = 1
sleeping once until memoized
nil
```

2. Improve how you traverse models
```diff
-- Concourse.find(1).terminals.limit(10).each { |terminal| terminal.airport }; nil
++ Concourse.find(1).terminals.limit(10).each { |terminal| terminal.concourse.airport }; nil
```

```ruby
Concourse.find(1).terminals.includes(:airport).limit(10).each { |terminal| terminal.airport }; nil
Concourse Load (4.2ms)  SELECT "concourses".* FROM "concourses" WHERE "concourses"."id" = 1 LIMIT 1
Terminal Load (2.7ms)  SELECT "terminals".* FROM "terminals" WHERE "terminals"."concourse_id" = 1 LIMIT 10
Airport Load (3.3ms)  SELECT "airports".* FROM "airports" WHERE "airports"."id" = 1
sleeping once until memoized
nil
```

#### Okay, I understand the problem. Should I use it?

Maybe? This is best used for hawt 🥵 code paths where you're counting object allocations or chasing repeated expensive calls where you're not expecting them. The SQL query that inspired this work was called 47,000 times per minute in production before being identified.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-initialized_counter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord-initialized_counter

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/activerecord-initialized_counter.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
