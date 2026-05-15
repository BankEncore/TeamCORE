# frozen_string_literal: true

module Admin
  class DocumentTypesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_document_type, only: %i[show edit update]

    def index
      @document_types = DocumentType.where(agency_id: current_agency.id).order(:code)
    end

    def show
    end

    def new
      @document_type = DocumentType.new(agency: current_agency, status: "active")
    end

    def create
      @document_type = DocumentType.new(document_type_params.merge(agency: current_agency))
      if @document_type.save
        redirect_to admin_document_type_path(@document_type), notice: "Document type created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @document_type.update(document_type_params)
        redirect_to admin_document_type_path(@document_type), notice: "Document type updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_document_type
      @document_type = DocumentType.where(agency_id: current_agency.id).find(params[:id])
    end

    def document_type_params
      params.require(:document_type).permit(
        :code, :name, :description, :category, :requires_expiration_date,
        :default_expiring_soon_days, :verification_required, :status
      )
    end
  end
end
