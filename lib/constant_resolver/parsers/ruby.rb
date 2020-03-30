# typed: false
# frozen_string_literal: true

require "parser/current"
require "rubocop"

module ConstantResolver
  module Parsers
    class Ruby
      def initialize(parser_class: ::Parser::CurrentRuby)
        @builder = ::RuboCop::AST::Builder.new
        @parser_class = parser_class
      end

      def parse(file_path)
        buffer = ::Parser::Source::Buffer.new(file_path)
        buffer.source = File.read(file_path)
        new_parser.parse(buffer)
      rescue ::Parser::SyntaxError => e
        raise Parsers::SyntaxError, "could not parse #{file_path}: #{e}"
      end

      def new_parser
        @parser_class.new(@builder).tap do |parser|
          parser.diagnostics.ignore_warnings = true
          parser.diagnostics.all_errors_are_fatal = true
        end
      end
    end
  end
end
