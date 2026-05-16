# frozen_string_literal: true

module Team360
  class ProfileAssembler
    def initialize(team_member:, agency:, current_user: nil, as_of_date: Date.current, focused_engagement_id: nil)
      @team_member = team_member
      @agency = agency
      @current_user = current_user
      @as_of_date = as_of_date
      @focused_engagement_id = focused_engagement_id
    end

    def call
      party = @team_member.party
      engagements = @team_member.engagements.to_a.sort_by(&:id)

      focused =
        Team360::FocusedEngagementResolver.call(
          team_member: @team_member,
          preferred_engagement_id: @focused_engagement_id
        )

      engagement_summaries =
        engagements.map do |e|
          {
            id: e.id,
            relationship_type: e.relationship_type,
            status: e.status,
            title: e.title,
            start_on: e.start_on,
            end_on: e.end_on,
            expected_end_on: e.expected_end_on,
            renewal_on: e.renewal_on,
            employee_path: e.employee_path?,
            contractor_class: e.contractor_class?,
            terminal: e.terminal?,
            suspended: e.suspended?,
            operational_blocked: e.operational_forward_work_blocked_by_status?
          }
        end

      current_ids = engagements.select { |e| e.status == "active" }.map(&:id)

      organization_context = build_organization_context(focused)
      readiness_result = build_readiness(focused)
      doc_types_by_id, records_by_id = build_document_lookups(readiness_result)

      Team360::ProfileSnapshot.new(
        as_of_date: @as_of_date,
        focused_engagement_id: focused&.id,
        identity: build_identity(party),
        contacts: build_contacts(party),
        engagement_summaries: engagement_summaries,
        current_engagement_ids: current_ids,
        organization_context: organization_context,
        readiness_result: readiness_result,
        document_types_by_id: doc_types_by_id,
        records_by_id: records_by_id,
        subcontractor_rows: build_subcontractor_rows(party)
      )
    end

    private

    def build_identity(party)
      {
        display_name: party.display_name,
        party_type: party.party_type,
        party_id: party.id,
        team_member_number: @team_member.team_member_number,
        team_member_status: @team_member.status,
        team_member_id: @team_member.id
      }
    end

    def build_contacts(party)
      party
        .party_contact_methods
        .order(:id)
        .map do |cm|
          {
            id: cm.id,
            contact_type: cm.contact_type,
            value: cm.value,
            is_primary: cm.is_primary,
            status: cm.status
          }
        end
    end

    def build_organization_context(focused_engagement)
      return nil unless focused_engagement

      placement =
        Team360::OrgEffectiveRow.pick(
          focused_engagement.engagement_organization_placements.order(:effective_start_on).to_a,
          @as_of_date
        )

      supervision =
        Team360::OrgEffectiveRow.pick(
          focused_engagement.engagement_supervision_assignments.order(:effective_start_on).to_a,
          @as_of_date
        )

      supervisor_engagement = supervision&.supervisor_engagement
      supervisor_party_name = supervisor_engagement&.team_member&.party&.display_name

      dept = placement&.department
      loc = placement&.location
      team = placement&.team

      {
        engagement_id: focused_engagement.id,
        placement_id: placement&.id,
        department: dept && { id: dept.id, name: dept.name, status: dept.status },
        location: loc && { id: loc.id, name: loc.name, status: loc.status },
        team: team && { id: team.id, name: team.name, status: team.status },
        placement_effective: placement && {
          start_on: placement.effective_start_on,
          end_on: placement.effective_end_on
        },
        supervision: supervision && {
          id: supervision.id,
          supervisor_engagement_id: supervision.supervisor_engagement_id,
          supervisor_display: supervisor_party_name,
          relationship_type: supervision.relationship_type,
          start_on: supervision.effective_start_on,
          end_on: supervision.effective_end_on
        }
      }
    end

    def build_readiness(focused_engagement)
      return nil unless focused_engagement

      Documents::ReadinessEvaluator.new(engagement: focused_engagement, as_of_date: @as_of_date).call
    end

    def build_document_lookups(readiness_result)
      return [{}, {}] unless readiness_result

      type_ids =
        (
          readiness_result.requirements.map(&:document_type_id) +
          readiness_result.alerts.map(&:document_type_id)
        ).uniq
      doc_types_by_id = DocumentType.where(id: type_ids).index_by(&:id)

      rec_ids = readiness_result.requirements.filter_map(&:document_record_id).uniq
      records_by_id =
        if rec_ids.empty?
          {}
        else
          DocumentRecord.where(id: rec_ids).includes(:verified_by).index_by(&:id)
        end

      [doc_types_by_id, records_by_id]
    end

    def build_subcontractor_rows(party)
      rels =
        PartyRelationship.where(
          agency_id: @agency.id,
          relationship_type: "subcontractor",
          target_party_id: party.id
        ).includes(:source_party).order(id: :asc).to_a

      sub_engagements =
        @team_member.engagements.select { |e| e.relationship_type == "subcontractor" }

      rels.map do |rel|
        promoted = sub_engagements.any?
        latest_sub = sub_engagements.max_by { |e| [e.start_on || Date.new(1900, 1, 1), e.id] }
        {
          id: rel.id,
          source_party: rel.source_party&.display_name,
          source_party_id: rel.source_party_id,
          status: rel.status,
          effective_start: rel.effective_start_date,
          effective_end: rel.effective_end_date,
          promoted: promoted,
          subcontractor_engagement_status: latest_sub&.status
        }
      end
    end
  end
end
