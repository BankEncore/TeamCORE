# frozen_string_literal: true

class Phase4CompensationSettlement < ActiveRecord::Migration[8.1]
  def change
    create_table :pay_periods do |t|
      t.references :agency, null: false, foreign_key: true
      t.date :start_on, null: false
      t.date :end_on, null: false
      t.string :label
      t.timestamps
    end
    add_index :pay_periods, [:agency_id, :start_on, :end_on], name: "index_pay_periods_on_agency_and_bounds"

    create_table :compensation_plans do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :name, null: false
      t.string :plan_type, null: false
      t.string :status, default: "active", null: false
      t.bigint :salary_annual_cents
      t.bigint :hourly_rate_cents
      t.integer :default_commission_rate_bps
      t.string :minimum_commission_basis
      t.bigint :minimum_commission_amount_cents
      t.string :recovery_rule
      t.timestamps
    end
    add_index :compensation_plans, [:agency_id, :status], name: "index_compensation_plans_on_agency_id_and_status"

    create_table :compensation_plan_assignments do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.references :compensation_plan, null: false, foreign_key: true
      t.date :effective_start_on, null: false
      t.date :effective_end_on
      t.string :snapshot_plan_name, null: false
      t.string :snapshot_plan_type, null: false
      t.integer :snapshot_commission_rate_bps
      t.string :snapshot_minimum_basis
      t.bigint :snapshot_minimum_amount_cents
      t.string :snapshot_recovery_rule
      t.bigint :snapshot_salary_annual_cents
      t.bigint :snapshot_hourly_rate_cents
      t.timestamps
    end
    add_index :compensation_plan_assignments, [:engagement_id, :effective_start_on],
      name: "index_comp_plan_assignments_on_engagement_and_start"

    create_table :revenue_inputs do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.references :pay_period, foreign_key: true
      t.date :period_start_on, null: false
      t.date :period_end_on, null: false
      t.bigint :commissionable_revenue_cents, null: false
      t.bigint :gross_sales_cents
      t.string :source_type, null: false, default: "manual"
      t.text :notes
      t.timestamps
    end
    add_index :revenue_inputs, [:engagement_id, :pay_period_id], name: "index_revenue_inputs_on_engagement_and_pay_period"

    create_table :commission_calculations do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.references :pay_period, foreign_key: true
      t.references :revenue_input, foreign_key: true
      t.integer :commission_rate_bps, null: false
      t.bigint :commissionable_revenue_cents, null: false
      t.bigint :calculated_commission_cents, null: false, default: 0
      t.bigint :draw_added_cents, null: false, default: 0
      t.bigint :draw_recovery_cents, null: false, default: 0
      t.bigint :gross_commission_pay_cents, null: false, default: 0
      t.bigint :ending_draw_balance_cents, null: false, default: 0
      t.string :status, default: "draft", null: false
      t.timestamps
    end
    add_index :commission_calculations, [:engagement_id, :pay_period_id], name: "index_commission_calcs_on_engagement_pay_period"

    create_table :commission_draw_balances do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.bigint :balance_cents, null: false, default: 0
      t.timestamps
    end
    add_index :commission_draw_balances, :engagement_id, unique: true, name: "index_draw_balances_unique_engagement"

    create_table :draw_balance_events do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.references :commission_calculation, foreign_key: true
      t.string :event_type, null: false
      t.bigint :amount_cents, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.text :reason
      t.timestamps
    end

    create_table :contractor_charges do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.string :charge_type, null: false
      t.string :status, null: false, default: "draft"
      t.bigint :original_amount_cents, null: false
      t.bigint :open_balance_cents, null: false
      t.date :due_on
      t.text :description
      t.timestamps
    end
    add_index :contractor_charges, [:engagement_id, :status], name: "index_contractor_charges_on_engagement_and_status"

    create_table :contractor_charge_waivers do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :contractor_charge, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.text :reason
      t.timestamps
    end

    create_table :contractor_settlement_runs do |t|
      t.references :agency, null: false, foreign_key: true
      t.date :period_start_on, null: false
      t.date :period_end_on, null: false
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
    add_index :contractor_settlement_runs, [:agency_id, :period_start_on, :period_end_on],
      name: "index_settlement_runs_on_agency_and_period"

    create_table :contractor_settlement_lines do |t|
      t.references :contractor_settlement_run, null: false, foreign_key: true
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.bigint :gross_commission_cents, null: false, default: 0
      t.bigint :charge_deductions_cents, null: false, default: 0
      t.bigint :manual_adjustment_positive_cents, null: false, default: 0
      t.bigint :manual_adjustment_negative_cents, null: false, default: 0
      t.bigint :net_settlement_cents, null: false, default: 0
      t.timestamps
    end

    create_table :contractor_charge_recoveries do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :contractor_charge, null: false, foreign_key: true
      t.references :contractor_settlement_line, foreign_key: true, index: true
      t.string :source_type, null: false
      t.bigint :amount_cents, null: false
      t.date :occurred_on, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.string :reference
      t.text :notes
      t.timestamps
    end

    create_table :contractor_settlement_line_revenue_inputs do |t|
      t.references :contractor_settlement_line, null: false, foreign_key: true
      t.references :revenue_input, null: false, foreign_key: true
      t.timestamps
    end
    add_index :contractor_settlement_line_revenue_inputs,
      [:contractor_settlement_line_id, :revenue_input_id],
      unique: true, name: "index_settlement_line_revenue_unique"

    create_table :contractor_settlement_line_commission_calculations do |t|
      t.references :contractor_settlement_line, null: false, foreign_key: true
      t.references :commission_calculation, null: false, foreign_key: true
      t.timestamps
    end
    add_index :contractor_settlement_line_commission_calculations,
      [:contractor_settlement_line_id, :commission_calculation_id],
      unique: true, name: "index_settlement_line_comm_calc_unique"

    create_table :contractor_settlement_run_events do |t|
      t.references :contractor_settlement_run, null: false, foreign_key: true
      t.string :event_type, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.text :reason
      t.timestamps
    end
  end
end
