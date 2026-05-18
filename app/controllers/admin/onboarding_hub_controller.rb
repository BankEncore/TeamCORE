# frozen_string_literal: true

module Admin
  class OnboardingHubController < Admin::BaseController
    before_action :require_current_agency!

    def show
    end
  end
end
