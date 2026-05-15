# frozen_string_literal: true

module Admin
  class DocumentRecordsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_document_record, only: %i[show edit update]

    def index
      @document_records =
        DocumentRecord
          .includes(:document_type, :team_member, :engagement)
          .where(agency_id: current_agency.id)
          .order(id: :desc)
    end

    def show
    end

    def new
      @document_record = DocumentRecord.new(agency: current_agency, status: "submitted")
      load_collections
    end

    def create
      @document_record = DocumentRecord.new(document_record_params.merge(agency: current_agency))
      apply_verifier_defaults(@document_record)
      load_collections
      if @document_record.save
        redirect_to admin_document_record_path(@document_record), notice: "Document record created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_collections
    end

    def update
      @document_record.assign_attributes(document_record_params)
      apply_verifier_defaults(@document_record)
      load_collections
      if @document_record.save
        redirect_to admin_document_record_path(@document_record), notice: "Document record updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_document_record
      @document_record = DocumentRecord.where(agency_id: current_agency.id).find(params[:id])
    end

    def load_collections
      @document_types = DocumentType.where(agency_id: current_agency.id).order(:name)
      @team_members = TeamMember.where(agency_id: current_agency.id).includes(:party).order(:id)
      @engagements = Engagement.where(agency_id: current_agency.id).includes(:team_member).order(:id)
      @users = User.order(:email)
    end

    def document_record_params
      params.require(:document_record).permit(
        :document_type_id, :team_member_id, :engagement_id, :party_id,
        :storage_key, :filename, :content_type, :byte_size, :display_name,
        :status, :submitted_on, :issued_on, :expires_on,
        :verified_by_id, :verified_on, :verification_notes, :rejection_reason
      )
    end

    def apply_verifier_defaults(record)
      return unless record.status.in?(%w[verified rejected])

      record.verified_by_id = current_user.id if record.verified_by_id.blank?
      record.verified_on = Date.current if record.verified_on.blank?
    end
  end
end
