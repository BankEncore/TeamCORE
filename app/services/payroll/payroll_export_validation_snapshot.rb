# frozen_string_literal: true

module Payroll
  class PayrollExportValidationSnapshot
    def self.call(agency:, pay_period:, batch:)
      missing_ts = Payroll::ClosureValidators::MissingTimesheets.call(agency:, pay_period:)
      pending = Payroll::ClosureValidators::PendingApprovals.call(agency:, pay_period:)

      row_scope = batch.payroll_input_rows
      dup_codes = duplicate_earning_warnings(row_scope)

      {
        "generated_at" => Time.current.utc.iso8601,
        "payroll_input_row_count" => row_scope.count,
        "distinct_engagement_count" => row_scope.distinct.count(:engagement_id),
        "closure_missing_timesheets_blocking" => missing_ts.blocking?,
        "closure_missing_timesheets_violations" => missing_ts.violations.first(100),
        "closure_pending_approvals_blocking" => pending.blocking?,
        "closure_pending_approvals_violations" => pending.violations,
        "duplicate_earning_code_warnings" => dup_codes
      }
    end

    def self.duplicate_earning_warnings(row_scope)
      counts =
        row_scope.group(:engagement_id, :earning_code).count.select { |_, ct| ct > 1 }
      counts.keys.first(50).map { |(eng_id, code)| "engagement #{eng_id} earning #{code} appears multiple times" }
    end
    private_class_method :duplicate_earning_warnings
  end
end
