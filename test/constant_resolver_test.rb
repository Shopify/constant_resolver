# frozen_string_literal: true

require "test_helper"

class ConstantResolverTest < Minitest::Test
  def setup
    @resolver = ConstantResolver.new(
      root_path: "test/fixtures/constant_discovery/valid/",
      load_paths: [
        "app/public",
        "app/models",
        "app/models/concerns",
        "app/services",
      ],
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

  def test_understands_acronyms
    constant = @resolver.resolve(
      "AcronymsMVP::MVPAcronym"
    )
    assert_equal("::AcronymsMVP::MVPAcronym", constant.name)
    assert_equal("app/models/acronyms_mvp/mvp_acronym.rb", constant.location)

    constant = @resolver.resolve(
      "MVPAcronym",
      current_namespace_path: ["AcronymsMVP"]
    )
    assert_equal("::AcronymsMVP::MVPAcronym", constant.name)
    assert_equal("app/models/acronyms_mvp/mvp_acronym.rb", constant.location)
  end

  def test_resolves_nested_acronym_constant_to_parent_namespace
    constant = @resolver.resolve(
      "ORDER",
      current_namespace_path: ["Sales", "Entry"]
    )

    # does not resolve to order.rb
    assert_nil(constant)
  end

  def test_raises_if_ambiguous_file_path_structure
    resolver = ConstantResolver.new(@resolver.config.merge(
      root_path: "test/fixtures/constant_discovery/invalid/"
    ))
    begin
      e = assert_raises(ConstantResolver::Error) do
        resolver.resolve("AnythingReally")
      end
      assert_match("ERROR: 'order' could refer to any", e.message)
    end
  end

  def test_raises_if_no_files
    resolver = ConstantResolver.new(@resolver.config.merge(
      root_path: "test/fixtures/constant_discovery/empty/"
    ))
    begin
      e = assert_raises(ConstantResolver::Error) do
        resolver.resolve("AnythingReally")
      end
      assert_match("could not find any files", e.message)
    end
  end
end
