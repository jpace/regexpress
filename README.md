# Regexpress

Regexpress contains a factory for the Ruby built-in Regexp class.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regexpress'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regexpress

## Usage

The `create` method accepts hash arguments, and parses the pattern, extracting flags from that as
well.

```ruby
   rf = RegexpFactory.new
   re = rf.create 'abcd+', ignorecase: true
   re = rf.create '/a b c d+/ix'
   re = rf.create 'a b c d+', extended: true
   re = rf.create '/a b c d+/x'
   re = rf.create 'abcd+', wholewords: true, ignorecase: true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jpace/regexpress.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
