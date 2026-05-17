# frozen_string_literal: true

module Admin
  class DocumentRecordsController < Admin::BaseController
    include Admin::DocumentVerifier

    before_action :require_current_agency!
    before_action :set_document_record,
      only: %i[show edit update verify reject void]
    before_action :require_document_verifier, only: %i[verify reject void]

    SUBMITTED_FIELDS = %i[
      document_type_id team_member_id engagement_id party_id
      storage_key filename content_type byte_size display_name
      submitted_on issued_on expires_on
    ].freeze

    POST_REVIEW_METADATA_FIELDS = %i[
      display_name filename storage_key content_type byte_size
      issued_on expires_on
    ].freeze

    def index
      @document_records =
        DocumentRecord
          .includes(:document_type, :team_member, :engagement)
          .where(agency_id: current_agency.id)
          .order(id: :desc)
      if params[:status].present? && DocumentRecord::STATUSES.include?(params[:status])
        @document_records = @document_records.where(status: params[:status])
      end
    end

    def show
    end

    def new
      @document_record = DocumentRecord.new(agency: current_agency, status: "submitted")
      assign_document_record_from_query_params!
      load_collections
    end

    def create
      @document_record = DocumentRecord.new(document_record_create_params.merge(agency: current_agency))
      @document_record.status = "submitted"
      load_collections

      if @document_record.save
        redirect_after_admin_save admin_document_record_path(@document_record), notice: "Document record created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_collections
    end

    def update
      @document_record.assign_attributes(document_record_update_params)
      load_collections

      if @document_record.save
        redirect_after_admin_save admin_document_record_path(@document_record), notice: "Document record updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def verify
      result = Documents::ReviewDocumentRecord.call(
        document_record: @document_record,
        action: :verify,
        reviewer: current_user,
        notes: params[:verification_notes]
      )
      if result.success?
        redirect_after_admin_save admin_document_record_path(result.document_record), notice: "Document verified."
      else
        flash.now[:alert] = result.error_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def reject
      result = Documents::ReviewDocumentRecord.call(
        document_record: @document_record,
        action: :reject,
        reviewer: current_user,
        notes: params[:verification_notes],
        rejection_reason: params[:rejection_reason]
      )
      if result.success?
        redirect_after_admin_save admin_document_record_path(result.document_record), notice: "Document rejected."
      else
        flash.now[:alert] = result.error_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def void
      result = Documents::ReviewDocumentRecord.call(
        document_record: @document_record,
        action: :void,
        reviewer: current_user,
        notes: params[:verification_notes]
      )
      if result.success?
        redirect_after_admin_save admin_document_record_path(result.document_record), notice: "Document voided."
      else
        flash.now[:alert] = result.error_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def assign_document_record_from_query_params!
      if params[:party_id].present?
        p = Party.where(agency_id: current_agency.id).find_by(id: params[:party_id])
        @document_record.party_id = p.id if p
      end
      if params[:team_member_id].present?
        tm = TeamMember.where(agency_id: current_agency.id).find_by(id: params[:team_member_id])
        @document_record.team_member_id = tm.id if tm
      end
      if params[:engagement_id].present?
        e = Engagement.where(agency_id: current_agency.id).find_by(id: params[:engagement_id])
        @document_record.engagement_id = e.id if e
      end
    end

    def set_document_record
      @document_record = DocumentRecord.where(agency_id: current_agency.id).find(params[:id])
    end

    def load_collections
      @document_types = DocumentType.where(agency_id: current_agency.id).order(:name)
      @team_members = TeamMember.where(agency_id: current_agency.id).includes(:party).order(:id)
      @engagements = Engagement.where(agency_id: current_agency.id).includes(:team_member).order(:id)
      @users = User.order(:email)
    end

    def document_record_create_params
      params.require(:document_record).permit(*SUBMITTED_FIELDS)
    end

    def document_record_update_params
      if @document_record.status == "submitted"
        params.require(:document_record).permit(*SUBMITTED_FIELDS)
      else
        params.require(:document_record).permit(*POST_REVIEW_METADATA_FIELDS)
      end
    end
  end
end
