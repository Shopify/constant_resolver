# typed: true
# frozen_string_literal: true

module ConstantResolver
  class ConstantDefinitions
    def initialize(root_node:)
      @local_definitions = {}

      collect_local_definitions_from_root(root_node)
    end

    def defined?(constant_name, namespace_path: [])
      Qualifications
        .for(constant_name, namespace_path: namespace_path)
        .any? { |name| @local_definitions.key?(name) }
    end

    private

    def collect_local_definitions_from_root(node, current_namespace_path = [])
      return unless node

      if node.type == :casgn
        # constant assignment, `FOO = 1`
        add_definition(node.node_parts[1].to_s, current_namespace_path, node.location.name)
      elsif node.defined_module
        # handle compact constant nesting for module/class definitions (e.g. "module Sales::Order")
        tempnode = node
        while (tempnode = tempnode.children.select { |c| c.is_a?(AST::Node) }.find(&:const_type?))
          add_definition(tempnode.const_name, current_namespace_path, tempnode.location.name)
        end
        current_namespace_path.concat(node.identifier.const_name.split("::"))
      end

      node.each_child_node { |child| collect_local_definitions_from_root(child, current_namespace_path) }
    end

    def add_definition(constant_name, current_namespace_path, location)
      fully_qualified_constant = [""].concat(current_namespace_path).push(constant_name).join("::")

      @local_definitions[fully_qualified_constant] = location
    end
  end
end
