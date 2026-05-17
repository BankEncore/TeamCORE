# frozen_string_literal: true

class Tc25EmployeeLeaveTracking < ActiveRecord::Migration[8.1]
  def up
    create_table :leave_types do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :paid, default: false, null: false
      t.boolean :balance_tracked, default: false, null: false
      t.boolean :active, default: true, null: false
      t.text :description
      t.references :payroll_earning_code, foreign_key: true
      t.timestamps
    end
    add_index :leave_types, [ :agency_id, :code ], unique: true

    create_table :leave_requests do |t|
      t.references :engagement, null: false, foreign_key: true
      t.references :leave_type, null: false, foreign_key: true
      t.date :start_on
      t.date :end_on
      t.string :status, default: "draft", null: false
      t.datetime :submitted_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.text :review_notes
      t.text :notes
      t.text :cancellation_reason
      t.timestamps
    end
    add_index :leave_requests, [ :engagement_id, :status ]

    create_table :leave_request_days do |t|
      t.references :leave_request, null: false, foreign_key: true
      t.date :leave_date, null: false
      t.decimal :hours, precision: 8, scale: 2, null: false
      t.timestamps
    end
    add_index :leave_request_days, [ :leave_request_id, :leave_date ], unique: true, name: "index_leave_request_days_on_request_and_date"

    create_table :leave_request_approval_events do |t|
      t.references :leave_request, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.datetime :occurred_at, null: false
      t.string :transition_from, null: false
      t.string :transition_to, null: false
      t.string :event_type, null: false
      t.json :metadata
      t.timestamps
    end
    add_index :leave_request_approval_events, [ :leave_request_id, :occurred_at ], order: { occurred_at: :desc },
      name: "index_leave_request_approval_events_on_req_and_time"

    create_table :leave_balances do |t|
      t.references :engagement, null: false, foreign_key: true
      t.references :leave_type, null: false, foreign_key: true
      t.decimal :balance_hours, precision: 10, scale: 2, default: "0.0", null: false
      t.timestamps
    end
    add_index :leave_balances, [ :engagement_id, :leave_type_id ], unique: true

    create_table :leave_balance_adjustments do |t|
      t.references :leave_balance, null: false, foreign_key: true
      t.decimal :adjustment_hours, precision: 10, scale: 2, null: false
      t.text :reason, null: false
      t.references :adjusted_by, null: false, foreign_key: { to_table: :users }
      t.datetime :adjusted_at, null: false
      t.timestamps
    end

    Agency.reset_column_information
    say_with_time "Seed default leave types per agency" do
      Agency.find_each do |agency|
        LeaveType.seed_defaults_for_agency!(agency)
      end
    end
  end

  def down
    drop_table :leave_balance_adjustments
    drop_table :leave_balances
    drop_table :leave_request_approval_events
    drop_table :leave_request_days
    drop_table :leave_requests
    drop_table :leave_types
  end
end
