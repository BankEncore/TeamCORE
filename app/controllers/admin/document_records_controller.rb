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

    INTAKE_MODES = %w[missing_requirement replace_rejected renew_expired general].freeze

    POST_REVIEW_METADATA_FIELDS = Documents::PostReviewDocumentRecordPatch::ALLOWED_ATTRIBUTE_KEYS

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
        notice = compose_created_notice
        redirect_after_admin_save admin_document_record_path(@document_record), notice: notice
      else
        @document_intake_mode = params[:document_intake_mode].presence_in(INTAKE_MODES)
        hydrate_document_requirement_banner_after_validation_failure!
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_collections
    end

    def update
      load_collections

      if @document_record.status == "submitted"
        @document_record.assign_attributes(document_record_update_params)
        if @document_record.save
          redirect_after_admin_save admin_document_record_path(@document_record), notice: "Document record updated."
        else
          render :edit, status: :unprocessable_entity
        end
      else
        result =
          Documents::PostReviewDocumentRecordPatch.call(
            document_record: @document_record,
            attributes: document_record_update_params,
            actor: current_user
          )
        if result.success?
          redirect_after_admin_save admin_document_record_path(@document_record), notice: "Document record updated."
        else
          flash.now[:alert] = result.error_messages.to_sentence
          render :edit, status: :unprocessable_entity
        end
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

    def compose_created_notice
      notice = "Document record created."
      mode = params[:document_intake_mode].presence_in(INTAKE_MODES)
      return notice if mode.blank?

      req =
        if params[:document_requirement_id].to_s.match?(/\A\d+\z/)
          DocumentRequirement.where(agency_id: current_agency.id).find_by(id: params[:document_requirement_id].to_i)
        end

      if req&.verification_required
        "#{notice} This record is pending verification — readiness updates after verification completes."
      elsif mode != "general"
        "#{notice} Readiness reflects evaluator output when you return or refresh Team360."
      else
        notice
      end
    end

    def assign_document_record_from_query_params!
      @document_intake_mode = params[:intake].presence_in(INTAKE_MODES)

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

      eng =
        if @document_record.engagement_id.present?
          Engagement.where(agency_id: current_agency.id).find_by(id: @document_record.engagement_id)
        end

      if params[:document_requirement_id].to_s.match?(/\A\d+\z/)
        req = DocumentRequirement.where(agency_id: current_agency.id).find_by(id: params[:document_requirement_id].to_i)
        if req.blank?
          # ignore unknown id
        elsif eng.blank?
          flash.now[:alert] = [
            flash.now[:alert],
            "Choose an engagement before attaching document requirement context."
          ].compact.join(" ")
        elsif req.applies_to_engagement?(eng)
          @document_requirement_for_intake = req

          supplied_dt = params[:document_type_id].to_s
          if supplied_dt.match?(/\A\d+\z/) && supplied_dt.to_i != req.document_type_id
            flash.now[:alert] = [
              flash.now[:alert],
              "Document type adjusted to match the selected requirement."
            ].compact.join(" ")
          end
          @document_record.document_type_id = req.document_type_id
        else
          flash.now[:alert] = [
            flash.now[:alert],
            "This document requirement does not apply to the selected engagement."
          ].compact.join(" ")
        end
      elsif params[:document_type_id].present?
        dt = DocumentType.where(agency_id: current_agency.id).find_by(id: params[:document_type_id])
        @document_record.document_type_id = dt.id if dt
      end

      if @document_record.new_record? && @document_record.submitted_on.blank?
        @document_record.submitted_on = Date.current
      end
    end

    def hydrate_document_requirement_banner_after_validation_failure!
      rid = params[:document_requirement_id].to_s
      return unless rid.match?(/\A\d+\z/)

      req = DocumentRequirement.where(agency_id: current_agency.id).find_by(id: rid.to_i)
      return unless req

      eng =
        if @document_record.engagement_id.present?
          Engagement.where(agency_id: current_agency.id).find_by(id: @document_record.engagement_id)
        end

      @document_requirement_for_intake = req if eng.present? && req.applies_to_engagement?(eng)
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
