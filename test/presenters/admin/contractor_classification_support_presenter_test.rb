# frozen_string_literal: true

require "test_helper"

class AdminContractorClassificationSupportPresenterTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Presenter Agency", code: "pre#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Contractor")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Contractor")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "individual_contractor",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.new(2025, 1, 1))

    @tax_type = DocumentType.create!(
      agency: @agency,
      code: "rollup_tax",
      name: "Tax",
      category: "tax_form",
      status: "active",
      verification_required: true
    )
    @agr_type = DocumentType.create!(
      agency: @agency,
      code: "rollup_agr",
      name: "Agr",
      category: "contractor_agreement",
      status: "active",
      verification_required: false
    )

    @document_types_by_id = {
      @tax_type.id => @tax_type,
      @agr_type.id => @agr_type
    }.freeze

    ev = Documents::ReadinessEvaluator::RequirementEvaluation
    @req_rows = [
      ev.new(
        document_requirement_id: 101,
        document_type_id: @tax_type.id,
        requirement_scope: "engagement",
        relationship_type: "individual_contractor",
        required: true,
        verification_required: true,
        requirement_outcome: "expiring_soon",
        record_review_status: "verified",
        document_record_id: 501,
        expires_on: Date.new(2025, 6, 15)
      ),
      ev.new(
        document_requirement_id: 102,
        document_type_id: @tax_type.id,
        requirement_scope: "engagement",
        relationship_type: "individual_contractor",
        required: true,
        verification_required: true,
        requirement_outcome: "missing",
        record_review_status: nil,
        document_record_id: nil,
        expires_on: nil
      ),
      ev.new(
        document_requirement_id: 201,
        document_type_id: @agr_type.id,
        requirement_scope: "engagement",
        relationship_type: "individual_contractor",
        required: true,
        verification_required: false,
        requirement_outcome: "satisfied",
        record_review_status: "verified",
        document_record_id: 502,
        expires_on: nil
      )
    ]

    @readiness = Documents::ReadinessResult.new(
      readiness_status: "not_ready",
      as_of_date: Date.new(2025, 6, 1),
      engagement_id: @engagement.id,
      requirements: @req_rows,
      alerts: []
    )
  end

  test "category rollup picks blocking outcome over expiring_soon within same category" do
    presenter = Admin::ContractorClassificationSupportPresenter.new(
      engagement: @engagement,
      readiness: @readiness,
      document_types_by_id: @document_types_by_id
    )

    tax_rollup = presenter.category_rollups.find { |r| r.category == "tax_form" }

    assert_equal "missing", tax_rollup.rollup_outcome
    assert_equal 2, tax_rollup.rows.size

    agr_rollup = presenter.category_rollups.find { |r| r.category == "contractor_agreement" }

    assert_equal "satisfied", agr_rollup.rollup_outcome
  end
end
