# frozen_string_literal: true

class Tc27PayrollInputWorkflow < ActiveRecord::Migration[8.1]
  # Idempotent for Docker/db:prepare after a partial run (MySQL commits DDL per statement;
  # a mid-migration failure can leave tables behind without a schema_migrations row).
  def up
    unless table_exists?(:payroll_adjustment_codes)
      create_table :payroll_adjustment_codes do |t|
        t.references :agency, null: false, foreign_key: true
        t.string :code, null: false
        t.string :name, null: false
        t.string :direction, null: false
        t.boolean :active, null: false, default: true
        t.timestamps
      end
      add_index :payroll_adjustment_codes, %i[agency_id code], unique: true
    end

    unless table_exists?(:payroll_input_batches)
      create_table :payroll_input_batches do |t|
        t.references :agency, null: false, foreign_key: true
        t.references :pay_period, null: false, foreign_key: true
        t.string :status, null: false
        t.string :reference_number, null: false
        t.integer :reference_sequence, null: false, default: 1
        t.bigint :supersedes_batch_id
        t.bigint :superseded_by_batch_id
        t.datetime :reversed_at
        t.references :reversed_by, foreign_key: { to_table: :users }
        t.text :reversal_reason
        t.references :payroll_export, foreign_key: true
        t.datetime :finalized_at
        t.references :finalized_by, foreign_key: { to_table: :users }
        t.datetime :exported_at
        t.references :exported_by, foreign_key: { to_table: :users }
        t.timestamps
      end

      add_foreign_key :payroll_input_batches, :payroll_input_batches, column: :supersedes_batch_id
      add_foreign_key :payroll_input_batches, :payroll_input_batches, column: :superseded_by_batch_id

      add_index :payroll_input_batches, %i[agency_id pay_period_id status]
    end

    unless table_exists?(:payroll_input_rows)
      create_table :payroll_input_rows do |t|
        t.references :payroll_input_batch, null: false, foreign_key: true
        t.references :engagement, null: false, foreign_key: true
        t.string :earning_code, null: false
        t.string :direction, null: false, default: "earning"
        t.decimal :hours, precision: 12, scale: 4
        t.decimal :amount, precision: 14, scale: 4
        t.string :currency, null: false, default: "USD"
        t.string :source_type
        t.bigint :source_id
        t.json :metadata
        t.timestamps
      end
      add_index :payroll_input_rows, %i[payroll_input_batch_id engagement_id]
      add_index :payroll_input_rows, %i[source_type source_id]
    end

    unless table_exists?(:payroll_input_adjustments)
      create_table :payroll_input_adjustments do |t|
        t.references :payroll_input_batch, null: false, foreign_key: true
        t.references :payroll_adjustment_code, null: false, foreign_key: true
        t.references :engagement, null: false, foreign_key: true
        t.decimal :hours, precision: 12, scale: 4
        t.decimal :amount, precision: 14, scale: 4
        t.string :currency, null: false, default: "USD"
        t.text :notes
        t.timestamps
      end
    end

    unless table_exists?(:pay_period_closure_events)
      create_table :pay_period_closure_events do |t|
        t.references :pay_period, null: false, foreign_key: true
        t.references :payroll_input_batch, foreign_key: true
        t.string :event_type, null: false
        t.references :actor, null: false, foreign_key: { to_table: :users }
        t.datetime :occurred_at, null: false
        t.string :source, null: false
        t.boolean :override_validation, null: false, default: false
        t.text :override_reason
        t.json :metadata
        t.timestamps
      end
      # pay_period_id index already created by t.references :pay_period above
    end
  end

  def down
    if table_exists?(:pay_period_closure_events)
      drop_table :pay_period_closure_events
    end
    if table_exists?(:payroll_input_adjustments)
      drop_table :payroll_input_adjustments
    end
    if table_exists?(:payroll_input_rows)
      drop_table :payroll_input_rows
    end
    if table_exists?(:payroll_input_batches)
      if foreign_key_exists?(:payroll_input_batches, column: :supersedes_batch_id)
        remove_foreign_key :payroll_input_batches, column: :supersedes_batch_id
      end
      if foreign_key_exists?(:payroll_input_batches, column: :superseded_by_batch_id)
        remove_foreign_key :payroll_input_batches, column: :superseded_by_batch_id
      end
      drop_table :payroll_input_batches
    end
    if table_exists?(:payroll_adjustment_codes)
      drop_table :payroll_adjustment_codes
    end
  end
end
