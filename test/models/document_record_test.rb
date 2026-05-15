# frozen_string_literal: true

require "test_helper"

class DocumentRecordTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Doc Rec Agency", code: "dra#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Doc Person")
    PersonProfile.create!(party: @party, first_name: "Doc", last_name: "Person")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.current)
    @dtype = DocumentType.create!(
      agency: @agency,
      code: "t1",
      name: "Type X",
      category: "other",
      status: "active"
    )
    @user = User.create!(email: "doc#{SecureRandom.hex(4)}@ex.test", password: "password12", password_confirmation: "password12")
  end

  test "rejected without rejection_reason is invalid" do
    r = DocumentRecord.new(
      agency: @agency,
      document_type: @dtype,
      team_member: @team_member,
      engagement: @engagement,
      status: "rejected",
      submitted_on: Date.current,
      verified_by: @user,
      verified_on: Date.current,
      filename: "x.pdf",
      content_type: "application/pdf"
    )

    assert_not r.valid?
    assert r.errors[:rejection_reason].present?
  end

  test "syncs team member from engagement" do
    r = DocumentRecord.create!(
      agency: @agency,
      document_type: @dtype,
      engagement: @engagement,
      status: "submitted",
      submitted_on: Date.current,
      filename: "x.pdf",
      content_type: "application/pdf"
    )

    assert_equal @team_member.id, r.team_member_id
  end
end
