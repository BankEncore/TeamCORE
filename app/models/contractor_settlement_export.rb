# frozen_string_literal: true

class ContractorSettlementExport < ApplicationRecord
  FILE_FORMATS = PayrollExport::FILE_FORMATS

  attribute :validation_summary, :json, default: nil

  belongs_to :contractor_settlement_run
  belongs_to :exported_by,
    class_name: "User",
    inverse_of: :exported_contractor_settlement_exports,
    optional: true

  has_one_attached :export_file

  validates :exported_at, presence: true
  validates :file_format, presence: true, inclusion: { in: FILE_FORMATS }
  validates :export_sequence, numericality: { only_integer: true, greater_than: 0 }
  validate :only_one_final_export_per_run

  before_validation :assign_defaults_and_sequence, on: :create
  before_update :prevent_record_updates

  scope :ordered, -> { order(:export_sequence) }

  def suggested_download_filename
    original_filename.presence || default_download_filename
  end

  private

  def assign_defaults_and_sequence
    self.exported_at ||= Time.current
    return unless contractor_settlement_run

    max_seq = ContractorSettlementExport.where(contractor_settlement_run_id:).maximum(:export_sequence)
    self.export_sequence = max_seq.to_i + 1
  end

  def only_one_final_export_per_run
    return unless is_final?
    return if contractor_settlement_run_id.blank?

    scope = ContractorSettlementExport.where(contractor_settlement_run_id:, is_final: true)
    scope = scope.where.not(id:) if persisted?

    errors.add(:is_final, "already recorded for this settlement run") if scope.exists?
  end

  def prevent_record_updates
    errors.add(:base, "Settlement exports are immutable; generate a new export.")
    throw(:abort)
  end

  def default_download_filename
    ext = file_format == "xlsx" ? "xlsx" : "csv"
    "contractor_settlement_run_#{contractor_settlement_run_id}_seq_#{export_sequence}.#{ext}"
  end
end
