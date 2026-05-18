# frozen_string_literal: true

module Admin
  class GuidedOnboardingController < Admin::BaseController
    before_action :require_current_agency!
    before_action :load_party_context, only: %i[
      employee
      individual_contractor
      contractor_organization
      subcontractor
    ]
    before_action :assign_guided_checklist, only: %i[
      employee
      individual_contractor
      contractor_organization
      subcontractor
    ]

    def hub
    end

    def employee
    end

    def individual_contractor
    end

    def contractor_organization
    end

    def subcontractor
    end

    private

    def guided_relationship_type
      case action_name
      when "employee" then "employee"
      when "individual_contractor" then "individual_contractor"
      when "contractor_organization" then "contractor_organization"
      when "subcontractor" then "subcontractor"
      else
        raise ArgumentError, "unexpected guided action #{action_name.inspect}"
      end
    end

    def assign_guided_checklist
      presenter =
        GuidedOnboarding::ChecklistPresenter.new(
          agency: current_agency,
          selected_party: @selected_party,
          relationship_type: guided_relationship_type,
          org_flow: action_name == "contractor_organization",
          guided_return_path: request.fullpath,
          search_q: @search_q,
          team_member_id_param: params[:team_member_id]
        )
      @guided_checklist_rows = presenter.rows
      @guided_document_ui = presenter.readiness_ui_context
    end

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
