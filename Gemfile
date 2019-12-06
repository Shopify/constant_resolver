# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in constant_resolver.gemspec
gemspec

group :deployment do
  gem 'rake'
end

group :development do
  gem 'rubocop', '~> 0.75.1', require: false # 0.76 currently not compatible with shopify style guide
  gem 'rubocop-performance'
end
