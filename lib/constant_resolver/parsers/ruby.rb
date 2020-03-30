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

      def parse_file(file_path)
        parse(File.read(file_path), name: file_path)
      end

      def parse(source, name: "(string)")
        buffer = ::Parser::Source::Buffer.new(name)
        buffer.source = source
        new_parser.parse(buffer)
      rescue ::Parser::SyntaxError => e
        raise Parsers::SyntaxError, "could not parse #{name}: #{e}"
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
