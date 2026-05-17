# frozen_string_literal: true

module Admin
  class GuidedOnboardingController < Admin::BaseController
    before_action :require_current_agency!

    def hub
    end

    def employee
      load_party_context
    end

    def individual_contractor
      load_party_context
    end

    def contractor_organization
      load_party_context
    end

    def subcontractor
      load_party_context
    end

    private

    def load_party_context
      q = params[:q].to_s.strip
      @search_q = q
      @party_hits =
        if q.length >= 2
          Admin::Search::Query.new(agency: current_agency, q: q).parties
        else
          []
        end
      if params[:party_id].to_s.match?(/\A\d+\z/)
        @selected_party =
          Party.where(agency_id: current_agency.id).find_by(id: params[:party_id].to_i)
      end
    end
  end
end
