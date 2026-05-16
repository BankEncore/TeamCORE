# frozen_string_literal: true

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

  def tc_link_classes(variant = :default)
    case variant.to_sym
    when :muted
      "tc-link tc-link--muted"
    when :danger
      "tc-link tc-link--danger"
    else
      "tc-link"
    end
  end

  def tc_nav_path_active?(path)
    base = path.to_s.chomp("/")
    root = admin_root_path.to_s.chomp("/")
    return request.path == base if base == root

    request.path == base || request.path.start_with?("#{base}/")
  end

  def tc_nav_link_to(text, path, **html_options)
    active = tc_nav_path_active?(path)
    opts = html_options.deep_dup
    opts[:class] = [
      "tc-section-nav__link",
      ("tc-section-nav__link--active" if active),
      opts[:class]
    ].compact.join(" ")
    opts["aria-current"] = "page" if active
    link_to text, path, opts
  end

  def tc_reports_nav_active?
    request.path.start_with?("/admin/reports")
  end

  # Maps domain status / readiness strings to existing tc-badge modifiers in 03_components.css
  def tc_status_badge_classes(status)
    s = status.to_s.strip.downcase.tr(" ", "_")
    return "tc-badge tc-badge--neutral" if s.blank?

    modifier = case s
    when "active", "verified", "approved", "ready", "satisfied"
      "tc-badge--active"
    when "inactive"
      "tc-badge--inactive"
    when "draft"
      "tc-badge--draft"
    when "pending", "submitted", "warning", "suspended", "expiring_soon"
      "tc-badge--pending"
    when "blocking"
      "tc-badge--danger"
    when "info"
      "tc-badge--info"
    when "pending_review", "submitted_for_review", "pending_verification"
      "tc-badge--pending-review"
    when "archived", "ended", "cancelled", "not_applicable", "n_a", "na"
      "tc-badge--neutral"
    when "terminated"
      "tc-badge--terminated"
    when "not_ready", "missing", "rejected", "blocked", "expired"
      "tc-badge--danger"
    else
      "tc-badge--neutral"
    end
    "tc-badge #{modifier}"
  end

  def tc_readiness_badge_classes(readiness_status)
    s = readiness_status.to_s.strip.downcase.tr(" ", "_")
    modifier = case s
    when "ready"
      "tc-badge--active"
    when "warning"
      "tc-badge--pending"
    when "not_ready"
      "tc-badge--danger"
    when "not_applicable"
      "tc-badge--neutral"
    else
      "tc-badge--info"
    end
    "tc-badge #{modifier}"
  end
end
