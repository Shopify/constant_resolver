# frozen_string_literal: true

require "constant_resolver/version"

# Get information about (partially qualified) constants without loading the application code.
# We infer the fully qualified name and the filepath.
#
# The implementation makes a few assumptions about the code base:
# - `Something::SomeOtherThing` is defined in a path of either `something/some_other_thing.rb` or `something.rb`,
#   relative to the load path. Constants that have their own file do not have all-uppercase names like MAGIC_NUMBER or
#   all-uppercase parts like SomeID. Rails' `zeitwerk` autoloader makes the same assumption.
# - It is OK to not always infer the exact file defining the constant. For example, when a constant is inherited, we
#   have no way of inferring the file it is defined in. You could argue though that inheritance means that another
#   constant with the same name exists in the inheriting class, and this view is sufficient for all our use cases.
class ConstantResolver
  class Error < StandardError; end
  ConstantContext = Struct.new(:name, :location)

  class DefaultInflector
    def camelize(string)
      string = string.sub(/^[a-z\d]*/, &:capitalize)
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
      string.gsub!("/", "::")
      string
    end
  end

  # @param root_path [String] The root path of the application to analyze
  # @param load_paths [Array<String>] The autoload paths of the application.
  # @param inflector [Object] Any object that implements a `camelize` function.
  #
  # @example usage in a Rails app
  #   config = Rails.application.config
  #   load_paths = (config.eager_load_paths + config.autoload_paths + config.autoload_once_paths)
  #     .map { |p| Pathname.new(p).relative_path_from(Rails.root).to_s }
  #   ConstantResolver.new(
  #     root_path: Rails.root.to_s,
  #     load_paths: load_paths
  #   )
  def initialize(root_path:, load_paths:, inflector: DefaultInflector.new)
    root_path += "/" unless root_path.end_with?("/")
    load_paths = load_paths.map { |p| p.end_with?("/") ? p : p + "/" }.uniq

    @root_path = root_path
    @load_paths = load_paths
    @file_map = nil
    @inflector = inflector
  end

  def config
    {
      root_path: @root_path,
      load_paths: @load_paths,
    }
  end

  # Resolve a constant via its name.
  # If the name is partially qualified, we need the current namespace path to correctly infer its full name
  #
  # @param const_name [String] The constant's name, fully or partially qualified.
  # @param current_namespace_path [Array<String>] (optional) The namespace of the context in which the constant is
  #   used, e.g. ["Apps", "Models"] for `Apps::Models`. Defaults to [] which means top level.
  # @return [ConstantResolver::ConstantContext]
  def resolve(const_name, current_namespace_path: [])
    current_namespace_path = [] if const_name.start_with?("::")
    inferred_name, location = resolve_constant(const_name.sub(/^::/, ""), current_namespace_path)

    return unless inferred_name

    ConstantContext.new(
      inferred_name,
      location,
    )
  end

  # maps constants to file paths
  def file_map
    return @file_map if @file_map
    @file_map = {}
    duplicate_files = {}

    @load_paths.each do |load_path|
      Dir[@root_path + load_path + "**/*.rb"].each do |file_path|
        root_relative_path = file_path.delete_prefix!(@root_path)
        const_name = @inflector.camelize(root_relative_path.delete_prefix(load_path).delete_suffix!(".rb"))
        existing_entry = @file_map[const_name]

        if existing_entry
          duplicate_files[const_name] ||= [existing_entry]
          duplicate_files[const_name] << root_relative_path
        end
        @file_map[const_name] = root_relative_path
      end
    end

    unless duplicate_files.empty?
      message = duplicate_files.map do |const_name, full_paths|
        "ERROR: '#{const_name}' could refer to any of\n#{full_paths.map { |p| '  ' + p }.join("\n")}"
      end.join("\n")
      raise(Error, message)
    end
    raise(Error, "could not find any files") if @file_map.empty?
    @file_map
  end

  private

  def resolve_constant(const_name, current_namespace_path, original_name: const_name)
    namespace, location = resolve_traversing_namespace_path(const_name, current_namespace_path)
    if location
      ["::" + namespace.push(original_name).join("::"), location]
    elsif !const_name.include?("::")
      # constant could not be resolved to a file in the given load paths
      [nil, nil]
    else
      parent_constant = const_name.split("::")[0..-2].join("::")
      resolve_constant(parent_constant, current_namespace_path, original_name: original_name)
    end
  end

  def resolve_traversing_namespace_path(const_name, current_namespace_path)
    fully_qualified_name_guess = (current_namespace_path + [const_name]).join("::")

    location = file_map[fully_qualified_name_guess]
    if location || fully_qualified_name_guess == const_name
      [current_namespace_path, location]
    else
      resolve_traversing_namespace_path(const_name, current_namespace_path[0..-2])
    end
  end
end
