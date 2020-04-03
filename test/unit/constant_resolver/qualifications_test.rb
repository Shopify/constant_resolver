# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class QualificationsTest < Minitest::Test
    def test_for_generates_all_possible_qualifications_for_a_reference
      qualifications = Qualifications.for("Order", namespace_path: ["Sales", "Internal"])

      assert_equal(["::Order", "::Sales::Order", "::Sales::Internal::Order"].sort, qualifications.sort)
    end

    def test_for_generates_single_qualification_for_an_already_fully_qualified_reference
      qualifications = Qualifications.for("::Order", namespace_path: ["Sales", "Internal"])

      assert_equal(["::Order"], qualifications.sort)
    end
  end
end
