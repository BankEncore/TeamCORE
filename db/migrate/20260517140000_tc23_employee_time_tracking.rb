# frozen_string_literal: true

class Tc23EmployeeTimeTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_timesheets do |t|
      t.references :engagement, null: false, foreign_key: true
      t.date :week_start_on, null: false
      t.date :week_end_on, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :submitted_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :rejected_by, foreign_key: { to_table: :users }
      t.text :rejection_reason
      t.timestamps
    end
    add_index :weekly_timesheets, %i[engagement_id week_start_on], unique: true,
      name: "index_weekly_timesheets_on_engagement_and_week_start"

    create_table :daily_worked_hours do |t|
      t.references :engagement, null: false, foreign_key: true
      t.date :work_date, null: false
      t.decimal :hours, precision: 8, scale: 2, null: false
      t.text :notes
      t.integer :source, null: false, default: 0
      t.timestamps
    end
    add_index :daily_worked_hours, %i[engagement_id work_date], unique: true,
      name: "index_daily_worked_hours_on_engagement_and_work_date"
  end
end
