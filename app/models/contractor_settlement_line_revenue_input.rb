# frozen_string_literal: true

class ContractorSettlementLineRevenueInput < ApplicationRecord
  belongs_to :contractor_settlement_line
  belongs_to :revenue_input
end
