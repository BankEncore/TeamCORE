# frozen_string_literal: true

namespace :pay_periods do
  desc "Generate pay periods from agency payroll calendar (AGENCY_ID=1 ACTOR_USER_ID=1)"
  task generate: :environment do
    agency_id = ENV.fetch("AGENCY_ID")
    actor_id = ENV.fetch("ACTOR_USER_ID")
    agency = Agency.find(agency_id)
    actor = User.find(actor_id)
    months_ahead = ENV.fetch("HORIZON_MONTHS_AHEAD", "24").to_i
    months_back = ENV.fetch("HORIZON_MONTHS_BACK", "36").to_i
    result = Payroll::PayPeriodGenerationService.call(
      agency:,
      actor:,
      horizon_months_ahead: months_ahead,
      horizon_months_back: months_back
    )
    puts "created=#{result[:created]} ensured_total=#{result[:ensured_total]}"
  end
end
