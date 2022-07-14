# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in constant_resolver.gemspec
gemspec

group :deployment do
  gem "rake"
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-shopify", require: false
end
