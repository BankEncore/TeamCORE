# frozen_string_literal: true

module Payroll
  # Extension hook for commission/draw payroll-preparation lines (TC-27).
  # Returns empty candidates until revenue/settlement integration is wired.
  module CommissionDrawAssembly
    LineCandidate = Struct.new(
      :engagement_id,
      :earning_code,
      :direction,
      :hours,
      :amount,
      :currency,
      :metadata,
      keyword_init: true
    )

    module_function

    # @return [Array<LineCandidate>]
    def line_candidates(agency:, pay_period:, engagement_ids:)
      []
    end
  end
end
