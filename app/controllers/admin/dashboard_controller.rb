# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def show
      @agency_count = current_user.agencies.count
    end
  end
end
