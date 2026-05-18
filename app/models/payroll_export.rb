# frozen_string_literal: true

class PayrollExport < ApplicationRecord
  FILE_FORMATS = %w[csv xlsx].freeze

  attribute :validation_summary, :json, default: nil

  belongs_to :pay_period
  belongs_to :exported_by, class_name: "User", inverse_of: :exported_payroll_exports, optional: true
  belongs_to :input_batch, class_name: "PayrollInputBatch", foreign_key: :payroll_input_batch_id, optional: true,
    inverse_of: :source_payroll_exports
  has_one :payroll_input_batch, foreign_key: :payroll_export_id, inverse_of: :payroll_export, dependent: :restrict_with_exception

  has_one_attached :export_file

  validates :exported_at, presence: true
  validates :file_format, presence: true, inclusion: { in: FILE_FORMATS }
  validates :export_sequence, numericality: { only_integer: true, greater_than: 0 }
  validate :only_one_final_export_per_pay_period
  validate :input_batch_pay_period_alignment

  before_validation :assign_defaults_and_sequence, on: :create
  before_update :prevent_record_updates

  scope :ordered, -> { order(:export_sequence) }

  def suggested_download_filename
    original_filename.presence || default_download_filename
  end

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

  def input_batch_pay_period_alignment
    return if payroll_input_batch_id.blank?

    return if input_batch&.pay_period_id == pay_period_id

    errors.add(:payroll_input_batch_id, "must belong to the same pay period")
  end

  def prevent_record_updates
    errors.add(:base, "Payroll exports are immutable; generate a new export.")
    throw(:abort)
  end

  def default_download_filename
    ext = file_format == "xlsx" ? "xlsx" : "csv"
    "payroll_export_pay_period_#{pay_period_id}_seq_#{export_sequence}.#{ext}"
  end
end
