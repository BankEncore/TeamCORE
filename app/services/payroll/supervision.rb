# frozen_string_literal: true

module Payroll
  module Supervision
    module_function

    # MVP direct-report check: primary_reports_to assignment covering as_of.
    def primary_supervises?(supervisor_engagement:, supervised_engagement:, as_of: Date.current)
      return false if supervisor_engagement.blank? || supervised_engagement.blank?

      EngagementSupervisionAssignment.where(
        engagement_id: supervised_engagement.id,
        supervisor_engagement_id: supervisor_engagement.id,
        relationship_type: "primary_reports_to"
      ).where("effective_start_on <= ?", as_of)
        .where("effective_end_on IS NULL OR effective_end_on >= ?", as_of)
        .exists?
    end
  end
end
