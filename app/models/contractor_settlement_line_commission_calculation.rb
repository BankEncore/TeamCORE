# frozen_string_literal: true

class ContractorSettlementLineCommissionCalculation < ApplicationRecord
  belongs_to :contractor_settlement_line
  belongs_to :commission_calculation
end
