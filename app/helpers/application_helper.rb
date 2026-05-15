module ApplicationHelper
  def subcontractor_workforce_tier_label(party, agency)
    tm = party&.team_members&.find_by(agency_id: agency.id)
    eng = tm&.engagements&.where(relationship_type: "subcontractor")&.order(:id)&.last
    if eng
      "Promoted — #{eng.status.titleize}"
    else
      "Related only"
    end
  end

  def outbound_subcontractors_panel_title(party)
    if party.organization? && party.organization_profile&.organization_kind == "contractor_organization"
      "Subcontractors under this party"
    else
      "Subcontractor relationships from this contractor"
    end
  end
end
