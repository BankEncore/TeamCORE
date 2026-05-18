# frozen_string_literal: true

require "test_helper"

class PayrollExportTest < ActiveSupport::TestCase
  setup do
    @agency, @user = p4_agency_user!
    @pay_period = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 2, 1),
      end_on: Date.new(2025, 2, 15),
      payroll_frequency: "legacy",
      status: "open"
    )
  end

  test "assigns monotonic export_sequence per pay period" do
    ex1 = PayrollExport.create!(pay_period: @pay_period, file_format: "csv", is_final: false, exported_by: @user)
    ex2 = PayrollExport.create!(pay_period: @pay_period, file_format: "csv", is_final: false, exported_by: @user)
    assert_equal 1, ex1.export_sequence
    assert_equal 2, ex2.export_sequence
  end

  test "allows only one final export per pay period" do
    PayrollExport.create!(pay_period: @pay_period, file_format: "csv", is_final: true, exported_by: @user)
    dup = PayrollExport.new(pay_period: @pay_period, file_format: "xlsx", is_final: true, exported_by: @user)
    assert_not dup.valid?
  end

  test "records are immutable after insert" do
    ex = PayrollExport.create!(pay_period: @pay_period, file_format: "csv", is_final: false, exported_by: @user)
    assert_not ex.update(notes: "x")
    assert_includes ex.errors[:base].join, "immutable"
  end
end
