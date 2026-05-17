# frozen_string_literal: true

module Admin
  class AgencyContextController < Admin::BaseController
    def show
      @agencies = current_user.agencies.order(:name)
      @return_to = safe_admin_return_path(params[:return_to]) || admin_root_path
    end

    def update
      aid = params.require(:agency_id).to_i
      unless current_user.agency_ids.include?(aid)
        redirect_to admin_agency_context_path(return_to: params[:return_to]), alert: "That agency is not available."
        return
      end

      session[:current_agency_id] = aid
      redirect_to safe_admin_return_path(params[:return_to]) || admin_root_path
    end
  end
end
