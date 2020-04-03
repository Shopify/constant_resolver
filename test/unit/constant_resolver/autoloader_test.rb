# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class AutoloaderTest < Minitest::Test
    def test_returns_path_for_known_constant
      autoloader = new_autoloader(root_path: "test/fixtures/constant_discovery/valid")

      path = autoloader.path_for("::Sales::Entry")

      assert_equal("app/models/sales/entry.rb", path)
    end

    def test_returns_nil_for_unknown_constant
      autoloader = new_autoloader(root_path: "test/fixtures/constant_discovery/valid")

      path = autoloader.path_for("::Unknown::Constant")

      assert_nil(path)
    end

    def test_autovivifies_modules_without_a_file
      autoloader = new_autoloader(root_path: "test/fixtures/constant_discovery/valid")

      path = autoloader.path_for("::GraphQL")

      assert_equal("app/models/graphql", path)
    end

    def test_actual_namespace_file_overrides_autovivification
      autoloader = new_autoloader(root_path: "test/fixtures/constant_discovery/valid")

      path = autoloader.path_for("::Sales")

      assert_equal("app/models/sales.rb", path)
    end

    def test_raises_if_ambiguous_file_path_structure
      e = assert_raises(ConstantResolver::Error) do
        new_autoloader(root_path: "test/fixtures/constant_discovery/invalid")
      end

      assert_equal(<<~MSG, e.message)
        Ambiguous constant definition:

        "::Order" could refer to any of
          app/services/order.rb
          app/models/order.rb
      MSG
    end

    def test_raises_if_no_files
      e = assert_raises(ConstantResolver::Error) do
        new_autoloader(root_path: "test/fixtures/constant_discovery/empty/")
      end

      assert_equal(<<~MSG, e.message)
        Could not find any ruby files. Searched in:

        - test/fixtures/constant_discovery/empty/app/public/**/*.rb
        - test/fixtures/constant_discovery/empty/app/models/**/*.rb
        - test/fixtures/constant_discovery/empty/app/models/concerns/**/*.rb
        - test/fixtures/constant_discovery/empty/app/services/**/*.rb
      MSG
    end

    private

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

    private_constant :OverrideInflector

    def new_autoloader(root_path:)
      Autoloader.new(
        root_path: root_path,
        load_paths: [
          "app/public",
          "app/models",
          "app/models/concerns",
          "app/services",
        ],
        inflector: OverrideInflector.new("graphql" => "GraphQL")
      )
    end
  end
end
