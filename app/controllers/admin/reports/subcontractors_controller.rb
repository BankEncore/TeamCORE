# frozen_string_literal: true

module Admin
  module Reports
    # Subcontractor PartyRelationship list with promoted vs related-only (TC-12 / PR F).
    class SubcontractorsController < Admin::Reports::BaseController
      before_action :require_current_agency!

      def index
        rels =
          PartyRelationship
            .where(agency_id: current_agency.id, relationship_type: "subcontractor")
            .includes(:source_party, :target_party)
            .order(:id)

        if (sid = parse_non_negative_int_param(params[:source_party_id]))
          rels = rels.where(source_party_id: sid)
        end

        if (tid = parse_non_negative_int_param(params[:target_party_id]))
          rels = rels.where(target_party_id: tid)
        end

        rels = rels.where(status: params[:relationship_status]) if params[:relationship_status].present?

        rels = rels.to_a

        party_ids = rels.map(&:target_party_id).uniq
        @team_members_by_party =
          TeamMember.where(agency_id: current_agency.id, party_id: party_ids).includes(:engagements).index_by(&:party_id)

        if params[:promoted].present?
          want = ActiveModel::Type::Boolean.new.cast(params[:promoted])
          rels.select! { |r| promoted_for_report?(r) == want }
        end

        @rows =
          rels.map do |rel|
            prom = promoted_for_report?(rel)
            tm = @team_members_by_party[rel.target_party_id]
            sub_eng =
              tm &&
                tm.engagements
                  .select { |e| e.relationship_type == "subcontractor" }
                  .max_by { |e| [e.start_on || Date.new(1900, 1, 1), e.id] }
            {
              rel: rel,
              promoted: prom,
              team_member: tm,
              subcontractor_engagement: sub_eng
            }
          end

        if (es = params[:engagement_status]).present?
          @rows.select! do |row|
            row[:subcontractor_engagement] && row[:subcontractor_engagement].status == es
          end
        end
      end

      private

      def promoted_for_report?(rel)
        @team_members_by_party.key?(rel.target_party_id)
      end
    end
  end
end
