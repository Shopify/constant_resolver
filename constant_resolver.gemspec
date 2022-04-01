# frozen_string_literal: true

require_relative "lib/constant_resolver/version"

Gem::Specification.new do |spec|
  spec.name          = "constant_resolver"
  spec.version       = ConstantResolver::VERSION
  spec.authors       = ["Philip Müller"]
  spec.email         = ["philip.mueller@shopify.com"]

  spec.summary       = "Statically resolve any ruby constant"
  spec.description   = <<~DESCRIPTION
    Given a code base that adheres to certain conventions, ConstantResolver resolves any, even partially qualified,
    constant to the path of the file that defines it.
  DESCRIPTION
  spec.homepage      = "https://github.com/Shopify/constant_resolver"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/Shopify/constant_resolver"
    spec.metadata["changelog_uri"] = "https://github.com/Shopify/constant_resolver/releases"
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency("rake", "~> 10.0")
  spec.add_development_dependency("minitest", "~> 5.0")
end
