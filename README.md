# ConstantResolver [![Build Status](https://github.com/Shopify/constant_resolver/workflows/CI/badge.svg)](https://github.com/Shopify/constant_resolver/actions?query=workflow%3ACI)

`ConstantResolver` resolves partially qualified constant reference to the fully qualified name and the path of the file defining it. It does not load the files to do that, its inference engine purely works on file paths and constant names.

`ConstantResolver` uses the same assumptions as [Rails' code loader, `Zeitwerk`](https://github.com/fxn/zeitwerk) to infer constant locations. Please see Zeitwerk's documentation on [file structure](https://github.com/fxn/zeitwerk#file-structure) and [inflection](https://github.com/fxn/zeitwerk#zeitwerkinflector) for more information.

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

### Initialize the resolver

Initialize a `ConstantResolver` with a root path and load paths:

```ruby
resolver = ConstantResolver.new(
  root_path: "/app",
  load_paths: [
    "/app/models",
    "/app/services",
  ]
)
```

### Default namespaces

If any load paths have a default namespace other than `Object`, these can be specified in a hash:

```ruby
resolver = ConstantResolver.new(
  root_path: "/app",
  load_paths: {
    "/app/models" => "::Object",
    "/app/services" => "::Object",
    "/app/internal" => "::Business",
  }
)
```

### Resolve a constant

Resolve a constant from the contents of your load paths:

```ruby
context = resolver.resolve("Some::Nested::Model")

context.name     # => "::Some::Nested::Model"
context.location # => "models/some/nested/model.rb"
```

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/constant_resolver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
