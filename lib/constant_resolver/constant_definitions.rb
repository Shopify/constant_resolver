# typed: true
# frozen_string_literal: true

module ConstantResolver
  class ConstantDefinitions
    def initialize(parser: Parsers::Ruby.new)
      @parser = parser
    end

    def each_definition_for(path)
      return to_enum(:each_definition_for, path) unless block_given?
      return unless File.file?(path)

      root_node = parser.parse_file(path)
      collect_local_definitions(root_node) do |name|
        yield name
      end
    rescue Parsers::SyntaxError
      # we'll silently ignore syntax errors here
    end

    private

    attr_reader :parser

    def collect_local_definitions(node, current_namespace_path = [])
      return unless node

      if node.type == :casgn
        # constant assignment, `FOO = 1`
        yield fully_qualified_name(node.node_parts[1].to_s, current_namespace_path)
      elsif node.defined_module
        # handle compact constant nesting for module/class definitions (e.g. "module Sales::Order"). We yield
        # each intermediate name, because they could be autovivified.
        tempnode = node
        while (tempnode = tempnode.children.select { |c| c.is_a?(AST::Node) }.find(&:const_type?))
          yield fully_qualified_name(tempnode.const_name, current_namespace_path)
        end

        current_namespace_path += [node.identifier.const_name.split("::")]
      end

      node.each_child_node do |child|
        collect_local_definitions(child, current_namespace_path) do |name|
          yield name
        end
      end
    end

    def fully_qualified_name(constant_name, current_namespace_path)
      ["", *current_namespace_path, constant_name].join("::")
    end
  end
end
