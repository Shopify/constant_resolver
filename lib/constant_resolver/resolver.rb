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
      constant_pieces = const_name.split("::")
      if const_name.start_with?("::")
        namespace_path = []
        constant_pieces = constant_pieces[1..]
      end

      inferred_name, location = resolve_constant_pieces(constant_pieces, namespace_path)
      return unless inferred_name

      ConstantContext.new(inferred_name, location)
    end

    private

    attr_reader :defined_constants

    def resolve_constant_pieces(constant_pieces, namespace_path)
      # The first piece can traverse the namespace.
      const_name = constant_pieces.shift
      namespace_path, location = resolve_traversing_namespace_path(const_name, namespace_path)

      return nil unless location

      namespace_path << const_name

      # All other pieces will be fixed to the namespace found via traversal.
      constant_pieces.each do |const_piece|
        _, location = resolve_constant(const_piece, namespace_path)
        return nil unless location

        namespace_path << const_piece
      end

      fully_qualified_name = ["", *namespace_path].join("::")
      [fully_qualified_name, location]
    end

    # Attempt to resolve the given constant in the given namespace.
    #
    # For example, if we have `const_name = Foo` and namespace path consists of `Spam` and `Eggs`,
    # we'll attempt to look for `spam/eggs/foo.rb`.
    def resolve_constant(const_name, namespace_path)
      fully_qualified_name_guess = ["", *namespace_path, const_name].join("::")

      location = defined_constants[fully_qualified_name_guess]
      return [namespace_path, location] if location

      location = @autoloader.path_for(fully_qualified_name_guess)
      if location
        defined_constants[fully_qualified_name_guess] = location
        [namespace_path, location]
      end
    end

    # Attempt to resolve the given constant in the given namespace, traversing upwards
    # through the namespace until the constant is found or the namespace is exhausted.
    #
    # For example, if we have `const_name = Foo` and namespace path consists of `Spam` and `Eggs`,
    # we'll attempt to look for the following files, in the following order:
    #
    # - spam/eggs/foo.rb
    # - spam/foo.rb
    # - foo.rb
    def resolve_traversing_namespace_path(const_name, namespace_path)
      ret = resolve_constant(const_name, namespace_path)
      return ret if ret || namespace_path.empty?

      resolve_traversing_namespace_path(const_name, namespace_path[0..-2])
    end
  end
end
