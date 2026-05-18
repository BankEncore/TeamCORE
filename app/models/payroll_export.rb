# frozen_string_literal: true

class PayrollExport < ApplicationRecord
  FILE_FORMATS = %w[csv xlsx].freeze

  belongs_to :pay_period
  belongs_to :exported_by, class_name: "User", inverse_of: :exported_payroll_exports, optional: true
  has_one :payroll_input_batch, dependent: :restrict_with_exception

  validates :exported_at, presence: true
  validates :file_format, presence: true, inclusion: { in: FILE_FORMATS }
  validates :export_sequence, numericality: { only_integer: true, greater_than: 0 }
  validate :only_one_final_export_per_pay_period

  before_validation :assign_defaults_and_sequence, on: :create

  scope :ordered, -> { order(:export_sequence) }

  private

  def assign_defaults_and_sequence
    self.exported_at ||= Time.current
    return unless pay_period

    max_seq = PayrollExport.where(pay_period_id: pay_period_id).maximum(:export_sequence)
    self.export_sequence = max_seq.to_i + 1
  end

  def only_one_final_export_per_pay_period
    return unless is_final?
    return if pay_period_id.blank?

    scope = PayrollExport.where(pay_period_id:, is_final: true)
    scope = scope.where.not(id:) if persisted?

    errors.add(:is_final, "already recorded for this pay period") if scope.exists?
  end
end
