# frozen_string_literal: true

require "test_helper"

class SubcontractorsPromoteRelatedPartyTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Subco", code: "sc#{SecureRandom.hex(4)}")
    @org = Party.create!(agency: @agency, party_type: "organization", display_name: "CO")
    OrganizationProfile.create!(party: @org, legal_name: "CO", organization_kind: "contractor_organization")
    @org.reload
    @target = Party.create!(agency: @agency, party_type: "person", display_name: "Sub T")
    PersonProfile.create!(party: @target, first_name: "Sub", last_name: "Target")
    @target.reload
    @rel = PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: @target,
      relationship_type: "subcontractor",
      status: "active"
    )
  end

  test "creates team member and draft subcontractor engagement" do
    assert_difference -> { TeamMember.count }, 1 do
      assert_difference -> { Engagement.where(relationship_type: "subcontractor").count }, 1 do
        result = Subcontractors::PromoteRelatedParty.call(party_relationship: @rel, agency: @agency)
        assert result.success?
        assert_equal "draft", result.engagement.status
      end
    end
  end

  test "is idempotent when draft engagement already exists" do
    Subcontractors::PromoteRelatedParty.call(party_relationship: @rel, agency: @agency)

    assert_no_difference -> { Engagement.where(relationship_type: "subcontractor").count } do
      result = Subcontractors::PromoteRelatedParty.call(party_relationship: @rel, agency: @agency)
      assert result.success?
    end
  end

  test "blocks when relationship not currently effective" do
    @rel.update_columns(
      effective_start_date: Date.current + 1.year,
      effective_end_date: nil
    )

    result = Subcontractors::PromoteRelatedParty.call(party_relationship: @rel.reload, agency: @agency)
    assert_not result.success?
  end

  test "blocks incomplete target identity" do
    incomplete = Party.create!(agency: @agency, party_type: "person", display_name: nil, status: "active")
    rel = PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: incomplete,
      relationship_type: "subcontractor",
      status: "active"
    )

    result = Subcontractors::PromoteRelatedParty.call(party_relationship: rel, agency: @agency)
    assert_not result.success?
  end
end
