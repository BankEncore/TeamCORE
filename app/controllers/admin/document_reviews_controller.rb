# frozen_string_literal: true

module Admin
  class DocumentReviewsController < Admin::BaseController
    include Admin::DocumentVerifier

    before_action :require_current_agency!
    before_action :require_document_verifier

    def index
      scope =
        DocumentRecord
          .includes(:document_type, { team_member: :party }, :engagement)
          .where(agency_id: current_agency.id, status: "submitted")
          .order(submitted_on: :desc, id: :desc)

      scope = scope.where(document_type_id: params[:document_type_id].to_i) if numeric_id?(params[:document_type_id])

      scope = scope.where(team_member_id: params[:team_member_id].to_i) if numeric_id?(params[:team_member_id])

      scope = scope.where(engagement_id: params[:engagement_id].to_i) if numeric_id?(params[:engagement_id])

      if params[:relationship_type].present?
        scope = scope.joins(:engagement).where(engagements: { relationship_type: params[:relationship_type] })
      end

      if (d = parse_date(params[:submitted_on_from])).present?
        scope = scope.where("document_records.submitted_on >= ?", d)
      end

      if (d = parse_date(params[:submitted_on_to])).present?
        scope = scope.where("document_records.submitted_on <= ?", d)
      end

      if (d = parse_date(params[:expires_on_from])).present?
        scope = scope.where("document_records.expires_on >= ?", d)
      end

      if (d = parse_date(params[:expires_on_to])).present?
        scope = scope.where("document_records.expires_on <= ?", d)
      end

      @document_records = scope
      @document_types = DocumentType.where(agency_id: current_agency.id).order(:name)
      @team_members = TeamMember.where(agency_id: current_agency.id).includes(:party).order(:id)
      @engagements = Engagement.where(agency_id: current_agency.id).includes(:team_member).order(:id)
    end

    private

    def numeric_id?(value)
      value.present? && value.to_s.match?(/\A\d+\z/)
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
