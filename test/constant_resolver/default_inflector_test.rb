# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class DefaultInflectorTest < Minitest::Test
    def setup
      @inflector = DefaultInflector.new
    end

    def test_camelize_capitalizes_single_word
      assert_equal("Thing", @inflector.camelize("thing"))
    end

    def test_camelize_capitilizes_at_underscore_boundary
      assert_equal("AnotherThing", @inflector.camelize("another_thing"))
    end

    def test_camelize_puts_double_colons_at_forward_slash
      assert_equal("Yet::AnotherThing", @inflector.camelize("yet/another_thing"))
    end
  end
end
