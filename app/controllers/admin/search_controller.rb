# frozen_string_literal: true

module Admin
  class SearchController < Admin::BaseController
    before_action :require_current_agency!

    def index
      @q = params[:q].to_s.strip
      if @q.length >= 2
        catalog = Admin::Search::Query.new(agency: current_agency, q: @q)
        @party_hits = catalog.parties
        @team_member_hits = catalog.team_members
        @engagement_hits = catalog.engagements
      else
        @party_hits = []
        @team_member_hits = []
        @engagement_hits = []
      end
    end
  end
end
