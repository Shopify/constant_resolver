# typed: true
# frozen_string_literal: true

module ConstantResolver
  module Qualifications
    class << self
      # What fully qualified constants can this constant refer to in this context?
      #
      # For example, `Foo` in the namespace `A::B` could be any of:
      #   - `A::B::Foo`,
      #   - `A::Foo`, or
      #   - `::Foo`.
      #
      # If a fully qualified name is already given, like `::Foo::Bar`, just that
      # name will be return.
      def for(constant_name, namespace_path:)
        return [constant_name] if constant_name.start_with?("::")

        fully_qualified_constant_name = "::#{constant_name}"

        possible_namespaces = namespace_path.reduce([""]) do |acc, current|
          acc << acc.last + "::" + current
        end

        possible_namespaces.map { |namespace| namespace + fully_qualified_constant_name }
      end
    end
  end

  private_constant :Qualifications
end
