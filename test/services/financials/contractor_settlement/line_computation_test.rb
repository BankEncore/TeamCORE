# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementLineComputationTest < ActiveSupport::TestCase
  test "compute validates sequential availability and net non negative" do
    rows = [
      { contractor_charge_id: 1, open_balance_cents: 50, deduct_now_cents: 30 },
      { contractor_charge_id: 2, open_balance_cents: 80, deduct_now_cents: 70 }
    ]

    result =
      Financials::ContractorSettlement::LineComputation.compute!(
        gross_commission_cents: 100,
        manual_positive_cents: 0,
        manual_negative_cents: 0,
        charge_deductions: rows
      )

    assert_equal 100, result.gross_commission_cents
    assert_equal 100, result.total_charge_deductions_cents
    assert_equal 0, result.net_settlement_cents
    assert_equal 2, result.charge_rows.size
  end

  test "compute rejects deduction exceeding open balance" do
    err = assert_raises(ArgumentError) do
      Financials::ContractorSettlement::LineComputation.compute!(
        gross_commission_cents: 100,
        manual_positive_cents: 0,
        manual_negative_cents: 0,
        charge_deductions: [ { contractor_charge_id: 1, open_balance_cents: 10, deduct_now_cents: 20 } ]
      )
    end
    assert_match(/open balance/i, err.message)
  end

  test "compute rejects deductions exceeding running availability" do
    err = assert_raises(ArgumentError) do
      Financials::ContractorSettlement::LineComputation.compute!(
        gross_commission_cents: 50,
        manual_positive_cents: 0,
        manual_negative_cents: 0,
        charge_deductions: [
          { contractor_charge_id: 1, open_balance_cents: 40, deduct_now_cents: 40 },
          { contractor_charge_id: 2, open_balance_cents: 40, deduct_now_cents: 20 }
        ]
      )
    end
    assert_match(/available settlement/i, err.message)
  end

  test "compute rejects manual adjustments driving negative before charges" do
    err = assert_raises(ArgumentError) do
      Financials::ContractorSettlement::LineComputation.compute!(
        gross_commission_cents: 50,
        manual_positive_cents: 0,
        manual_negative_cents: 60,
        charge_deductions: []
      )
    end
    assert_match(/Manual adjustments/i, err.message)
  end

  test "propose_waterfall caps each charge by remaining available" do
    ch1 = Struct.new(:id, :open_balance_cents).new(1, 500_000)
    ch2 = Struct.new(:id, :open_balance_cents).new(2, 500_000)

    result =
      Financials::ContractorSettlement::LineComputation.propose_waterfall!(
        gross_commission_cents: 200_000,
        manual_positive_cents: 0,
        manual_negative_cents: 0,
        charges_in_order: [ ch1, ch2 ]
      )

    assert_equal 200_000, result.total_charge_deductions_cents
    assert_equal 0, result.net_settlement_cents
    assert_equal 200_000, result.charge_rows.sum(&:deduct_now_cents)
  end
end
