# frozen_string_literal: true

module EngagementFinancialContext
  extend ActiveSupport::Concern

  CONTRACTOR_FINANCIAL_TYPES = %w[individual_contractor contractor_organization].freeze

  def allows_contractor_charges_and_settlement?
    relationship_type.in?(CONTRACTOR_FINANCIAL_TYPES)
  end

  def allows_employee_commission_draw?
    relationship_type == "employee"
  end
end
