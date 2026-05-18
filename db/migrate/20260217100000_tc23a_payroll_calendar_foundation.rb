# frozen_string_literal: true

class Tc23aPayrollCalendarFoundation < ActiveRecord::Migration[8.1]
  class MigrationAgency < ApplicationRecord
    self.table_name = "agencies"
  end

  def up
    create_table :agency_payroll_configurations do |t|
      t.references :agency, null: false, foreign_key: true, index: { unique: true }
      t.string :payroll_frequency, null: false
      t.integer :workweek_starts_on, null: false, default: 1
      t.string :payroll_timezone, null: false, default: "Etc/UTC"
      t.decimal :weekly_overtime_threshold_hours, precision: 8, scale: 2, null: false, default: 40
      t.date :pay_schedule_anchor_on
      t.timestamps
    end

    create_table :payroll_earning_codes do |t|
      t.string :code, null: false
      t.string :category, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :payroll_earning_codes, :code, unique: true

    add_column :pay_periods, :status, :string, null: false, default: "open"
    add_column :pay_periods, :payroll_frequency, :string, null: false, default: "legacy"
    add_reference :pay_periods, :closed_by, foreign_key: { to_table: :users }
    add_column :pay_periods, :closed_at, :datetime

    create_table :payroll_exports do |t|
      t.references :pay_period, null: false, foreign_key: true
      t.datetime :exported_at, null: false
      t.references :exported_by, foreign_key: { to_table: :users }
      t.boolean :is_final, null: false, default: false
      t.string :file_format, null: false
      t.integer :export_sequence, null: false
      t.string :storage_reference
      t.text :notes
      t.timestamps
    end
    add_index :payroll_exports, [ :pay_period_id, :export_sequence ], unique: true, name: "index_payroll_exports_on_pay_period_and_sequence"

    seed_payroll_earning_codes
    backfill_agency_payroll_configurations
  end

  def down
    remove_index :payroll_exports, name: "index_payroll_exports_on_pay_period_and_sequence"
    drop_table :payroll_exports

    remove_column :pay_periods, :closed_at
    remove_reference :pay_periods, :closed_by, foreign_key: true
    remove_column :pay_periods, :payroll_frequency
    remove_column :pay_periods, :status

    drop_table :payroll_earning_codes
    drop_table :agency_payroll_configurations
  end

  private

  def seed_payroll_earning_codes
    now = Time.current
    rows = [
      { code: "REG", category: "worked_regular", name: "Regular worked hours", position: 10 },
      { code: "OT", category: "worked_overtime", name: "Overtime worked hours", position: 20 },
      { code: "PTO", category: "payable_leave", name: "Paid time off", position: 30 },
      { code: "HOL", category: "payable_leave", name: "Holiday leave", position: 40 },
      { code: "SICK", category: "payable_leave", name: "Sick leave", position: 50 }
    ]
    rows.each do |row|
      next if payroll_earning_code_exists?(row[:code])

      execute <<-SQL.squish
        INSERT INTO payroll_earning_codes (code, category, name, position, created_at, updated_at)
        VALUES (#{quote(row[:code])}, #{quote(row[:category])}, #{quote(row[:name])}, #{row[:position].to_i},
                #{quote(now.utc.to_fs(:db))}, #{quote(now.utc.to_fs(:db))})
      SQL
    end
  end

  def payroll_earning_code_exists?(code)
    select_value("SELECT 1 FROM payroll_earning_codes WHERE code = #{quote(code)} LIMIT 1").present?
  end

  def backfill_agency_payroll_configurations
    MigrationAgency.find_each do |agency|
      next if agency_payroll_configuration_exists?(agency.id)

      execute <<-SQL.squish
        INSERT INTO agency_payroll_configurations
          (agency_id, payroll_frequency, workweek_starts_on, payroll_timezone, weekly_overtime_threshold_hours, pay_schedule_anchor_on, created_at, updated_at)
        VALUES (#{agency.id}, 'semimonthly', 1, 'Etc/UTC', 40, NULL, #{quote(Time.current.utc.to_fs(:db))}, #{quote(Time.current.utc.to_fs(:db))})
      SQL
    end
  end

  def agency_payroll_configuration_exists?(agency_id)
    select_value("SELECT 1 FROM agency_payroll_configurations WHERE agency_id = #{agency_id.to_i} LIMIT 1").present?
  end
end
