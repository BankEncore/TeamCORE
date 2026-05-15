# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin_user!
    before_action :ensure_agency_context

    helper_method :current_agency

    private

    def authenticate_admin_user!
      redirect_to login_path, alert: "Sign in required." unless current_user
    end

    def skipping_agency_context?
      controller_name == "agency_context"
    end

    def ensure_agency_context
      return if skipping_agency_context?

      ids = current_user.agency_ids

      if ids.empty?
        @current_agency = nil
        return
      end

      if ids.size == 1
        session[:current_agency_id] = ids.first
        @current_agency = Agency.find(ids.first)
        return
      end

      cid = session[:current_agency_id].to_i
      unless cid.positive? && ids.include?(cid)
        session.delete(:current_agency_id)
        return redirect_to(
          admin_agency_context_path(return_to: request.fullpath),
          alert: "Select an agency to continue."
        )
      end

      @current_agency = Agency.find_by(id: cid)
    end

    def current_agency
      @current_agency
    end

    def require_current_agency!
      return if current_agency

      redirect_to admin_agency_context_path(return_to: request.fullpath),
        alert: "Choose an agency with access."
    end

    def scoped(resource_class)
      resource_class.where(agency_id: current_agency.id)
    end
  end
end
