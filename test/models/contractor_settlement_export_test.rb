# frozen_string_literal: true

require "test_helper"

class ContractorSettlementExportTest < ActiveSupport::TestCase
  setup do
    @agency, @user = p4_agency_user!
    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2025, 8, 1),
      period_end_on: Date.new(2025, 8, 31),
      status: "finalized"
    )
  end

  test "assigns monotonic export_sequence per run" do
    ex1 = ContractorSettlementExport.create!(contractor_settlement_run: @run, file_format: "csv", is_final: false, exported_by: @user)
    ex2 = ContractorSettlementExport.create!(contractor_settlement_run: @run, file_format: "csv", is_final: false, exported_by: @user)
    assert_equal 1, ex1.export_sequence
    assert_equal 2, ex2.export_sequence
  end

  test "allows only one final export per run" do
    ContractorSettlementExport.create!(contractor_settlement_run: @run, file_format: "csv", is_final: true, exported_by: @user)
    dup = ContractorSettlementExport.new(contractor_settlement_run: @run, file_format: "xlsx", is_final: true, exported_by: @user)
    assert_not dup.valid?
  end

  test "records are immutable after insert" do
    ex = ContractorSettlementExport.create!(contractor_settlement_run: @run, file_format: "csv", is_final: false, exported_by: @user)
    assert_not ex.update(notes: "x")
    assert_includes ex.errors[:base].join, "immutable"
  end
end
