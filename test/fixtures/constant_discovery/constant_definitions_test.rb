# typed: ignore
# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class ConstantDefinitionsTest < Minitest::Test
    def test_recognizes_constant_assignment
      assert_equal(
        %w(::HELLO),
        definitions_for('HELLO = "World"')
      )
    end

    def test_recognizes_class_or_module_definitions
      assert_equal(
        %w(::Sales ::Sales::Order),
        definitions_for("module Sales; class Order; end; end")
      )
    end

    def test_recognizes_constants_that_are_more_fully_qualified
      assert_equal(
        %w(::Sales ::Sales::HELLO),
        definitions_for("module Sales; HELLO = 2; end")
      )
    end

    def test_recognizes_compact_nested_constant_definition
      assert_equal(
        %w(::Sales ::Sales::Order ::Sales::Order::Something),
        definitions_for("module Sales::Order::Something; end")
      )
    end

    def test_recognizes_local_constant_reference_from_sub_namespace
      assert_equal(
        %w(::Something ::Something::Else ::Something::Else::HELLO),
        definitions_for("module Something; class Else; HELLO = 1; end; end")
      )
    end

    def test_recognizes_multiple_nested_classes
      assert_equal(
        %w(::Parent ::Parent::ChildError1 ::Parent::ChildError2),
        definitions_for(
          <<~EOS
            class Parent
              class ChildError1 < StandardError; end
              class ChildError2 < StandardError; end
            end
          EOS
        )
      )
    end

    def test_handles_empty_files
      assert_empty(definitions_for("# just a comment"))
    end

    private

    def definitions_for(string)
      ast = Parsers::Ruby.new.parse(string)
      parser = stub(parse: ast, parse_file: ast)

      File.expects(:file?).with("some/path/ruby_file.rb").returns(true)

      ConstantDefinitions.new(parser: parser)
        .each_definition_for("some/path/ruby_file.rb")
        .to_a
        .sort
    end
  end
end
