# frozen_string_literal: true

module Admin
  class DocumentRequirementsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_document_requirement, only: %i[edit update]

    def index
      @document_requirements =
        DocumentRequirement
          .includes(:document_type)
          .where(agency_id: current_agency.id)
          .order(:id)
    end

    def new
      @document_requirement =
        DocumentRequirement.new(agency: current_agency, status: "active", relationship_type: "any", required: true)
      load_document_types
    end

    def create
      @document_requirement = DocumentRequirement.new(document_requirement_params.merge(agency: current_agency))
      load_document_types
      if @document_requirement.save
        redirect_to admin_document_requirements_path, notice: "Document requirement created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_document_types
    end

    def update
      load_document_types
      if @document_requirement.update(document_requirement_params)
        redirect_to admin_document_requirements_path, notice: "Document requirement updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_document_requirement
      @document_requirement = DocumentRequirement.where(agency_id: current_agency.id).find(params[:id])
    end

    def load_document_types
      @document_types = DocumentType.where(agency_id: current_agency.id).order(:name)
    end

    def document_requirement_params
      params.require(:document_requirement).permit(
        :document_type_id, :name, :description, :requirement_scope, :relationship_type,
        :required, :verification_required, :expiration_required, :expiring_soon_days, :status
      )
    end
  end
end
