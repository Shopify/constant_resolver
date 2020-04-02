# frozen_string_literal: true

module ConstantResolver
  class Resolver
    # Resolver resolves a constant, autoloading when necessary.
    #
    # @param autoloader [ConstantResolver::Autoloader]
    #   The autoloader used for resolving constants that have yet to have been defined
    #
    # @example usage in a Rails app
    #   config = Rails.application.config
    #   load_paths = (config.eager_load_paths + config.autoload_paths + config.autoload_once_paths)
    #     .map { |p| Pathname.new(p).relative_path_from(Rails.root).to_s }
    #   autoloader = ConstantResolver::Autoloader.new(
    #     root_path: Rails.root.to_s,
    #     load_paths: load_paths
    #   )
    #   resolver = ConstantResolver::Resolver.new(autoloader)
    def initialize(autoloader)
      @autoloader = autoloader
      @defined_constants = {}
    end

    # Resolve a constant via its name.
    # If the name is partially qualified, we need the current namespace path to correctly infer its full name
    #
    # @param const_name [String] The constant's name, fully or partially qualified.
    # @param namespace_path [Array<String>] (optional) The namespace of the context in which the constant is
    #   used, e.g. ["Apps", "Models"] for `Apps::Models`. Defaults to [] which means top level.
    # @return [ConstantResolver::ConstantContext]
    def resolve(const_name, namespace_path: [])
      namespace_path = [] if const_name.start_with?("::")

      inferred_name, location = resolve_constant(const_name.sub(/^::/, ""), namespace_path)
      return unless inferred_name

      ConstantContext.new(inferred_name, location)
    end

    private

    attr_reader :defined_constants

    def resolve_constant(const_name, namespace_path, original_name: const_name)
      namespace, location = resolve_traversing_namespace_path(const_name, namespace_path)
      if location
        ["::" + namespace.push(original_name).join("::"), location]
      elsif !const_name.include?("::")
        # constant could not be resolved to a file in the given load paths
        [nil, nil]
      else
        parent_constant = const_name.split("::")[0..-2].join("::")
        resolve_constant(parent_constant, namespace_path, original_name: original_name)
      end
    end

    # Attempt to resolve the given constant in the given namespace against known files
    # in our autoload paths.
    #
    # For example, if we have `const_name = Foo` and namespace path consists of `Spam` and `Eggs`,
    # we'll attempt to look for the following files, in the following order:
    #
    # - spam/eggs/foo.rb
    # - spam/foo.rb
    # - foo.rb
    #
    def resolve_traversing_namespace_path(const_name, namespace_path)
      fully_qualified_name_guess = ["", *namespace_path, const_name].join("::")

      location = defined_constants[fully_qualified_name_guess]
      return [namespace_path, location] if location

      location = @autoloader.path_for(fully_qualified_name_guess)
      if location || namespace_path.empty?
        defined_constants[fully_qualified_name_guess] = location
        [namespace_path, location]
      else
        resolve_traversing_namespace_path(const_name, namespace_path[0..-2])
      end
    end
  end
end
