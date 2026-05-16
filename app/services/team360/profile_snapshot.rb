# frozen_string_literal: true

module Team360
  # Read-model DTO for Team360#show. No persistence.
  ProfileSnapshot = Struct.new(
    :as_of_date,
    :focused_engagement_id,
    :identity,
    :contacts,
    :engagement_summaries,
    :current_engagement_ids,
    :organization_context,
    :readiness_result,
    :document_types_by_id,
    :records_by_id,
    :subcontractor_rows,
    keyword_init: true
  )
end
