# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  module Parsers
    class ParserTest < Minitest::Test
      def setup
        @parser = Ruby.new
      end

      def test_that_it_parses_valid_code
        File
          .expects(:read)
          .with("test_file.rb")
          .returns( "class Foo; end")

        result = @parser.parse_file("test_file.rb")

        assert_kind_of(::Parser::AST::Node, result)
      end

      def test_that_it_raises_syntax_error_for_invalid_code
        File
          .expects(:read)
          .with("test_file.rb")
          .returns("class not+valid-ruby<>")

        assert_raises(Parsers::SyntaxError) do
          @parser.parse_file("test_file.rb")
        end
      end
    end
  end
end
