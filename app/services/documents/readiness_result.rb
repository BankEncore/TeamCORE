# frozen_string_literal: true

module Documents
  ReadinessResult = Data.define(
    :readiness_status,
    :as_of_date,
    :engagement_id,
    :requirements,
    :alerts
  )
end
