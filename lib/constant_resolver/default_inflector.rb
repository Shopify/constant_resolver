# frozen_string_literal: true

module ConstantResolver
  class DefaultInflector
    def camelize(string)
      string = string.sub(/^[a-z\d]*/, &:capitalize)
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
      string.gsub!("/", "::")
      string
    end
  end

  private_constant :DefaultInflector
end
