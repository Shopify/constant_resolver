# frozen_string_literal: true

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
module ConstantResolver
  class Error < StandardError; end
  class ConstantContext < Struct.new(:name, :location); end
end

require "constant_resolver/default_inflector"
require "constant_resolver/resolver"
require "constant_resolver/version"
