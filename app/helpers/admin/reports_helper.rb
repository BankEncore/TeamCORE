# frozen_string_literal: true

module Admin
  module ReportsHelper
    # Re-applies current report filter params to drill-through links.
    def reports_drill_path(path, **extra)
      qp = request.query_parameters.merge(extra.stringify_keys)
      qp = qp.compact_blank
      return path if qp.empty?

      joiner = path.include?("?") ? "&" : "?"
      "#{path}#{joiner}#{qp.to_query}"
    end

    def reports_team360_path(team_member, engagement: nil)
      extras = {}
      extras[:engagement_id] = engagement.id if engagement.present?
      reports_drill_path(admin_team_member_team360_path(team_member), **extras)
    end
  end
end
