# frozen_string_literal: true

module ConstantResolver
  class Autoloader
    # @param root_path [String] The root path of the application to analyze
    # @param load_paths [Array<String>] The autoload paths of the application.
    # @param inflector [Object] Any object that implements a `camelize` function.
    def initialize(root_path:, load_paths:, inflector: DefaultInflector.new)
      root_path += "/" unless root_path.end_with?("/")
      load_paths = load_paths.map { |p| p.end_with?("/") ? p : p + "/" }.uniq

      @root_path = root_path
      @load_paths = load_paths
      @inflector = inflector
      @file_map = build_file_map
    end

    # Get the autoload path for a given constant name
    #
    # @param fully_qualified_constant [String]
    #   The fully qualified constant name, such as ::Foo, or ::Spam::Eggs
    def path_for(fully_qualified_constant)
      @file_map[fully_qualified_constant]
    end

    private

    # Maps constant names to file paths.
    #
    # @return [Hash<String, String>]
    def build_file_map
      file_map = {}
      duplicate_files = {}

      @load_paths.each do |load_path|
        Dir[glob_path(load_path)].each do |file_path|
          root_relative_path = file_path.delete_prefix!(@root_path)

          const_name = @inflector
            .camelize(root_relative_path.delete_prefix(load_path).delete_suffix!(".rb"))
            .prepend("::")

          existing_entry = file_map[const_name]
          if existing_entry
            duplicate_files[const_name] ||= [existing_entry]
            duplicate_files[const_name] << root_relative_path
          end

          file_map[const_name] = root_relative_path
        end
      end

      if duplicate_files.any?
        raise(Error, <<~MSG)
          Ambiguous constant definition:

          #{duplicate_files.map { |const_name, paths| ambiguous_constant_message(const_name, paths) }.join("\n")}
        MSG
      end

      if file_map.empty?
        raise(Error, <<~MSG)
          Could not find any ruby files. Searched in:

          - #{@load_paths.map { |load_path| glob_path(load_path) }.join("\n- ")}
        MSG
      end

      file_map
    end

    def ambiguous_constant_message(const_name, paths)
      <<~MSG.chomp
        "#{const_name}" could refer to any of
          #{paths.join("\n  ")}
      MSG
    end

    def glob_path(path)
      File.join(@root_path, path, "**/*.rb")
    end
  end
end
