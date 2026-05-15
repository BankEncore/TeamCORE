# frozen_string_literal: true

require "test_helper"

class DocumentRequirementTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Doc Req Agency", code: "drq#{SecureRandom.hex(4)}")
    @dtype = DocumentType.create!(
      agency: @agency,
      code: "cat",
      name: "Catalog item",
      category: "other",
      status: "active"
    )
  end

  test "relationship_type any is valid" do
    r = DocumentRequirement.new(
      agency: @agency,
      document_type: @dtype,
      requirement_scope: "engagement",
      relationship_type: "any",
      status: "active"
    )

    assert r.valid?, r.errors.full_messages.join(", ")
    assert_equal "any", r.relationship_type
  end

  test "forbids duplicate agency type scope relationship tuple" do
    DocumentRequirement.create!(
      agency: @agency,
      document_type: @dtype,
      requirement_scope: "engagement",
      relationship_type: "any",
      status: "active"
    )

    dup = DocumentRequirement.new(
      agency: @agency,
      document_type: @dtype,
      requirement_scope: "engagement",
      relationship_type: "any",
      status: "active"
    )

    assert_not dup.valid?
    assert dup.errors[:document_type_id].present?
  end
end
