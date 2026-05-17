# frozen_string_literal: true

module Payroll
  # Contract-first aggregator; time and leave sources are stubbed until later Phase 5 epics.
  class PayrollSummaryAggregator
    def initialize(agency:, pay_period:, **_sources)
      @agency = agency
      @pay_period = pay_period
    end

    # Future: accept engagement / employee scope and concrete hour providers.
    def call
      PayrollSummary.empty
    end

    private

    attr_reader :agency, :pay_period
  end
end
