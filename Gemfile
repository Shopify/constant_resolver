# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in constant_resolver.gemspec
gemspec

group :deployment do
  gem 'package_cloud'
  gem 'rake'
end

group :development do
  gem 'rubocop'
  gem 'rubocop-performance'
end
