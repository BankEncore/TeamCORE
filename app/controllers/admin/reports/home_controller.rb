# frozen_string_literal: true

module Admin
  module Reports
    class HomeController < Admin::Reports::BaseController
      before_action :require_current_agency!

      def show
      end
    end
  end
end
