# frozen_string_literal: true

module ConstantResolver
  module Parsers
    autoload :Ruby, "constant_resolver/parsers/ruby"

    class SyntaxError < ::SyntaxError; end
  end
end