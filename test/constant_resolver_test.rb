# frozen_string_literal: true

require "test_helper"

class ConstantResolver
  class ResolveTest < Minitest::Test
    class OverrideInflector < DefaultInflector
      def initialize(overrides)
        @overrides = overrides
      end

      def camelize(string)
        string = string.dup
        @overrides.each do |before, after|
          string.gsub!(/\b#{before}\b/, after)
        end
        super(string)
      end
    end

    def setup
      @resolver = ConstantResolver.new(
        root_path: "test/fixtures/constant_discovery/valid/",
        load_paths: [
          "app/public",
          "app/models",
          "app/models/concerns",
          "app/services",
        ],
        inflector: OverrideInflector.new("graphql" => "GraphQL")
      )
      super
    end

    def test_that_it_has_a_version_number
      refute_nil(::ConstantResolver::VERSION)
    end

    def test_discovers_simple_constant
      constant = @resolver.resolve("Order")
      assert_equal("::Order", constant.name)
      assert_equal("app/models/order.rb", constant.location)
    end

    def test_resolve_returns_constant_context
      context = @resolver.resolve("Order")
      assert_instance_of(ConstantResolver::ConstantContext, context)
    end

    def test_does_not_discover_constant_with_invalid_casing
      constant = @resolver.resolve("ORDER")
      assert_nil(constant)
    end

    def test_understands_nested_load_paths
      constant = @resolver.resolve("Entry")
      assert_equal("::Entry", constant.name)
      assert_equal("app/models/entry.rb", constant.location)

      constant = @resolver.resolve("HasTimeline")
      assert_equal("::HasTimeline", constant.name)
      assert_equal("app/models/concerns/has_timeline.rb", constant.location)
    end

    def test_does_not_try_to_discover_constant_outside_of_load_paths
      assert(File.file?(@resolver.config[:root_path] + "initializers/app_extensions.rb"))

      constant = @resolver.resolve("AppExtensions")
      assert_nil(constant)
    end

    def test_discovers_constants_that_dont_have_their_own_file_using_their_parent_namespace
      constant = @resolver.resolve(
        "Sales::Errors::SomethingWentWrong"
      )
      assert_equal("::Sales::Errors::SomethingWentWrong", constant.name)
      assert_equal("app/public/sales/errors.rb", constant.location)
    end

    def test_discovers_constants_using_custom_inflector
      constant = @resolver.resolve("GraphQL::QueryRoot")

      assert_equal("::GraphQL::QueryRoot", constant.name)
      assert_equal("app/models/graphql/query_root.rb", constant.location)
    end

    def test_discovers_constants_that_are_partially_qualified_inferring_their_full_qualification_from_parent_namespace
      constant = @resolver.resolve(
        "Errors",
        current_namespace_path: ["Sales", "SomeEntrypoint"]
      )
      assert_equal("::Sales::Errors", constant.name)
      assert_equal("app/public/sales/errors.rb", constant.location)
    end

    def test_discovers_constants_that_are_both_partially_qualified_and_dont_have_their_own_file
      constant = @resolver.resolve(
        "Errors::SomethingWentWrong",
        current_namespace_path: ["Sales", "SomeEntrypoint"]
      )
      assert_equal("::Sales::Errors::SomethingWentWrong", constant.name)
      assert_equal("app/public/sales/errors.rb", constant.location)
    end

    def test_discovers_constants_that_are_explicitly_toplevel
      constant = @resolver.resolve("::Order")
      assert_equal("::Order", constant.name)
      assert_equal("app/models/order.rb", constant.location)
    end

    def test_respects_colon_colon_prefix_by_resolving_as_top_level_constant
      constant = @resolver.resolve(
        "Entry",
        current_namespace_path: ["Sales", "SomeEntrypoint"]
      )
      assert_equal("::Sales::Entry", constant.name)
      assert_equal("app/models/sales/entry.rb", constant.location)

      constant = @resolver.resolve(
        "::Entry",
        current_namespace_path: ["Sales", "SomeEntrypoint"]
      )
      assert_equal("::Entry", constant.name)
      assert_equal("app/models/entry.rb", constant.location)
    end

    def test_raises_if_ambiguous_file_path_structure
      resolver = ConstantResolver.new(@resolver.config.merge(
        root_path: "test/fixtures/constant_discovery/invalid/"
      ))
      begin
        e = assert_raises(ConstantResolver::Error) do
          resolver.resolve("AnythingReally")
        end
        assert_match("ERROR: 'Order' could refer to any", e.message)
      end
    end
  end
end
