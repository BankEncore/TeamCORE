# frozen_string_literal: true

module Documents
  AlertResult = Data.define(
    :alert_type,
    :severity,
    :requirement_outcome,
    :record_review_status,
    :document_requirement_id,
    :document_type_id,
    :document_record_id,
    :engagement_id,
    :team_member_id,
    :expires_on,
    :days_until_expiration,
    :rejection_reason,
    :message
  )
end
