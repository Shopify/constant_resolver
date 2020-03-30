# typed: ignore
# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class ConstantDefinitionsTest < Minitest::Test
    def test_recognizes_constant_assignment
      definitions = ConstantDefinitions.new(
        root_node: parse_code('HELLO = "World"')
      )

      assert definitions.defined?("HELLO")
    end

    def test_recognizes_class_or_module_definitions
      definitions = ConstantDefinitions.new(
        root_node: parse_code("module Sales; class Order; end; end")
      )

      assert definitions.defined?("Sales")
      assert definitions.defined?("Order", namespace_path: ["Sales"])
    end

    def test_recognizes_constants_that_are_more_fully_qualified
      definitions = ConstantDefinitions.new(
        root_node: parse_code('module Sales; HELLO = "World"; end')
      )

      assert definitions.defined?("HELLO", namespace_path: ["Sales"])
      assert definitions.defined?("Sales::HELLO")
      assert definitions.defined?("::Sales::HELLO")
    end

    def test_understands_fully_qualified_references
      definitions = ConstantDefinitions.new(
        root_node: parse_code("module Sales; class Order; end; end")
      )

      assert definitions.defined?("::Sales")
      assert definitions.defined?("::Sales", namespace_path: ["Sales"])
      refute definitions.defined?("::Order")
      refute definitions.defined?("::Order", namespace_path: ["Sales"])
    end

    def test_recognizes_compact_nested_constant_definition
      definitions = ConstantDefinitions.new(
        root_node: parse_code("module Sales::Order::Something; end")
      )

      assert definitions.defined?("Sales::Order")
      assert definitions.defined?("Order", namespace_path: ["Sales"])
      assert definitions.defined?("Sales", namespace_path: [])
      refute definitions.defined?("More", namespace_path: ["Sales"])
    end

    def test_recognizes_local_constant_reference_from_sub_namespace
      definitions = ConstantDefinitions.new(
        root_node: parse_code("module Something; class Else; HELLO = 1; end; end")
      )

      assert definitions.defined?("HELLO", namespace_path: ["Something", "Else", "Sales"])
    end

    def test_handles_empty_files
      ast = parse_code("# just a comment")

      definitions = ConstantDefinitions.new(root_node: ast)

      refute definitions.defined?("Something")
    end

    private

    def parse_code(string)
      Parsers::Ruby.new.parse(string)
    end
  end
end
