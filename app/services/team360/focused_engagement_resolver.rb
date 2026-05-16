# frozen_string_literal: true

module Team360
  # Picks which engagement drives org + document panels on Team360 (TC-3-D03).
  # Display-only; not persisted.
  class FocusedEngagementResolver
    def self.call(team_member:, preferred_engagement_id: nil)
      engagements = team_member.engagements.to_a

      if preferred_engagement_id.present?
        pick = engagements.find { |e| e.id == preferred_engagement_id.to_i }
        return pick if pick
      end

      active = engagements.select { |e| e.status == "active" }
      case active.size
      when 1
        active.first
      when 0
        non_cancelled = engagements.reject { |e| e.status == "cancelled" }
        non_cancelled.max_by { |e| [e.start_on || Date.new(1900, 1, 1), e.id] }
      else
        active.min_by(&:id)
      end
    end
  end
end
