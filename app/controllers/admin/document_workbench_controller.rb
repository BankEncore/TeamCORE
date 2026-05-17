# frozen_string_literal: true

module Admin
  class DocumentWorkbenchController < Admin::BaseController
    before_action :require_current_agency!

    SECTION_LIMIT = 25

    def show
      aid = current_agency.id
      base_includes = [ :document_type, { team_member: :party }, :engagement ]

      @pending_review =
        DocumentRecord
          .where(agency_id: aid, status: "submitted")
          .includes(*base_includes)
          .order(submitted_on: :desc, id: :desc)
          .limit(SECTION_LIMIT)

      @recently_rejected =
        DocumentRecord
          .where(agency_id: aid, status: "rejected")
          .includes(*base_includes)
          .order(Arel.sql("verified_on DESC"), id: :desc)
          .limit(SECTION_LIMIT)

      today = Date.current
      window_end = today + 30.days
      @expiring_soon =
        DocumentRecord
          .where(agency_id: aid, status: %w[submitted verified])
          .where.not(expires_on: nil)
          .where("document_records.expires_on <= ?", window_end)
          .includes(*base_includes)
          .order(:expires_on, :id)
          .limit(SECTION_LIMIT)
    end
  end
end
