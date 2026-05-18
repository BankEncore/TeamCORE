# frozen_string_literal: true

class Tc20PayrollSettlementExportFiles < ActiveRecord::Migration[8.1]
  def change
    change_table :payroll_exports, bulk: true do |t|
      t.bigint :payroll_input_batch_id, null: true
      t.string :content_sha256, limit: 64
      t.bigint :byte_size
      t.string :original_filename
      t.json :validation_summary
    end

    add_foreign_key :payroll_exports, :payroll_input_batches, column: :payroll_input_batch_id
    add_index :payroll_exports, :payroll_input_batch_id

    create_table :contractor_settlement_exports do |t|
      t.references :contractor_settlement_run, null: false, foreign_key: true
      t.integer :export_sequence, null: false
      t.datetime :exported_at, null: false
      t.references :exported_by, foreign_key: { to_table: :users }
      t.string :file_format, null: false
      t.boolean :is_final, null: false, default: false
      t.text :notes
      t.string :content_sha256, limit: 64
      t.bigint :byte_size
      t.string :original_filename
      t.json :validation_summary
      t.timestamps
    end

    add_index :contractor_settlement_exports,
      %i[contractor_settlement_run_id export_sequence],
      unique: true,
      name: "index_settlement_exports_on_run_and_sequence"
  end
end
