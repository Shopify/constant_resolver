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

    def test_raises_if_ambiguous_file_path_structure
      e = assert_raises(ConstantResolver::Error) do
        new_autoloader(root_path: "test/fixtures/constant_discovery/invalid")
      end

      assert_equal(<<~MSG, e.message)
        Ambiguous constant definition:

        "::Order" could refer to any of
          app/models/order.rb
          app/services/order.rb
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

    def new_autoloader(root_path:)
      Autoloader.new(
        root_path: root_path,
        load_paths: [
          "app/public",
          "app/models",
          "app/models/concerns",
          "app/services",
        ],
      )
    end
  end
end
