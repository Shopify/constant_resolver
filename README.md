# ConstantResolver [![Build Status](https://badge.buildkite.com/af9f619f65b3cc8a13093c17d8049035ff029b049cca8d95d4.svg?branch=master)](https://buildkite.com/shopify/constant-resolver/builds?branch=master)

`ConstantResolver` resolves partially qualified constant reference to the fully qualified name and the path of the file defining it. It does not load the files to do that, its inference engine purely works on file paths and constant names.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'constant_resolver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install constant_resolver

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shopify/constant_resolver.

### Cutting a release to Package Cloud

1. bump `lib/constant_resolver/version.rb`
2. deploy in [shipit](https://shipit.shopify.io/shopify/constant_resolver/production)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
