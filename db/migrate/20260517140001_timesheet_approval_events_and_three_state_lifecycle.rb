# frozen_string_literal: true

class TimesheetApprovalEventsAndThreeStateLifecycle < ActiveRecord::Migration[8.1]
  def up
    create_table :weekly_timesheet_approval_events do |t|
      t.references :weekly_timesheet, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.datetime :occurred_at, null: false
      t.string :transition_from, null: false
      t.string :transition_to, null: false
      t.string :event_type, null: false
      t.json :metadata
      t.timestamps
    end
    add_index :weekly_timesheet_approval_events, [ :weekly_timesheet_id, :occurred_at ], order: { occurred_at: :desc },
      name: "index_weekly_timesheet_approval_events_on_sheet_and_time"

    execute <<-SQL.squish
      UPDATE weekly_timesheets SET status = 'draft'
      WHERE status = 'rejected'
    SQL

    remove_foreign_key :weekly_timesheets, column: :rejected_by_id
    remove_reference :weekly_timesheets, :rejected_by
    remove_column :weekly_timesheets, :rejected_at, :datetime
    remove_column :weekly_timesheets, :rejection_reason, :text
  end

  def down
    add_column :weekly_timesheets, :rejection_reason, :text
    add_column :weekly_timesheets, :rejected_at, :datetime
    add_reference :weekly_timesheets, :rejected_by, foreign_key: { to_table: :users }

    drop_table :weekly_timesheet_approval_events
  end
end
