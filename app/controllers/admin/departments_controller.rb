# frozen_string_literal: true

module Admin
  class DepartmentsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_department, only: %i[show edit update]

    def index
      @departments = Department.where(agency_id: current_agency.id).order(:code)
    end

    def show
    end

    def new
      @department = Department.new(agency: current_agency, status: "active")
    end

    def create
      @department = Department.new(department_params.merge(agency: current_agency))
      if @department.save
        redirect_to admin_department_path(@department), notice: "Department created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @department.update(department_params)
        redirect_to admin_department_path(@department), notice: "Department updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_department
      @department = Department.where(agency_id: current_agency.id).find(params[:id])
    end

    def department_params
      params.require(:department).permit(:name, :code, :description, :status, :parent_department_id)
    end
  end
end
