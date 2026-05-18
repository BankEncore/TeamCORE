# frozen_string_literal: true

module Admin
  class PeopleHubController < Admin::BaseController
    before_action :require_current_agency!

    def show
    end
  end
end
