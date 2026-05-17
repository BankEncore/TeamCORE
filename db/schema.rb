# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_17_140000) do
  create_table "agencies", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_agencies_on_code", unique: true
  end

  create_table "agency_payroll_configurations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "pay_schedule_anchor_on"
    t.string "payroll_frequency", null: false
    t.string "payroll_timezone", default: "Etc/UTC", null: false
    t.datetime "updated_at", null: false
    t.decimal "weekly_overtime_threshold_hours", precision: 8, scale: 2, default: "40.0", null: false
    t.integer "workweek_starts_on", default: 1, null: false
    t.index ["agency_id"], name: "index_agency_payroll_configurations_on_agency_id", unique: true
  end

  create_table "commission_calculations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "calculated_commission_cents", default: 0, null: false
    t.integer "commission_rate_bps", null: false
    t.bigint "commissionable_revenue_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "draw_added_cents", default: 0, null: false
    t.bigint "draw_recovery_cents", default: 0, null: false
    t.bigint "ending_draw_balance_cents", default: 0, null: false
    t.bigint "engagement_id", null: false
    t.bigint "gross_commission_pay_cents", default: 0, null: false
    t.bigint "pay_period_id"
    t.bigint "revenue_input_id"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_commission_calculations_on_agency_id"
    t.index ["engagement_id", "pay_period_id"], name: "index_commission_calcs_on_engagement_pay_period"
    t.index ["engagement_id"], name: "index_commission_calculations_on_engagement_id"
    t.index ["pay_period_id"], name: "index_commission_calculations_on_pay_period_id"
    t.index ["revenue_input_id"], name: "index_commission_calculations_on_revenue_input_id"
  end

  create_table "commission_draw_balances", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_commission_draw_balances_on_agency_id"
    t.index ["engagement_id"], name: "index_commission_draw_balances_on_engagement_id"
    t.index ["engagement_id"], name: "index_draw_balances_unique_engagement", unique: true
  end

  create_table "compensation_plan_assignments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "compensation_plan_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_end_on"
    t.date "effective_start_on", null: false
    t.bigint "engagement_id", null: false
    t.integer "snapshot_commission_rate_bps"
    t.bigint "snapshot_hourly_rate_cents"
    t.bigint "snapshot_minimum_amount_cents"
    t.string "snapshot_minimum_basis"
    t.string "snapshot_plan_name", null: false
    t.string "snapshot_plan_type", null: false
    t.string "snapshot_recovery_rule"
    t.bigint "snapshot_salary_annual_cents"
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_compensation_plan_assignments_on_agency_id"
    t.index ["compensation_plan_id"], name: "index_compensation_plan_assignments_on_compensation_plan_id"
    t.index ["engagement_id", "effective_start_on"], name: "index_comp_plan_assignments_on_engagement_and_start"
    t.index ["engagement_id"], name: "index_compensation_plan_assignments_on_engagement_id"
  end

  create_table "compensation_plans", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.integer "default_commission_rate_bps"
    t.bigint "hourly_rate_cents"
    t.bigint "minimum_commission_amount_cents"
    t.string "minimum_commission_basis"
    t.string "name", null: false
    t.string "plan_type", null: false
    t.string "recovery_rule"
    t.bigint "salary_annual_cents"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "status"], name: "index_compensation_plans_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_compensation_plans_on_agency_id"
  end

  create_table "contractor_charge_recoveries", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "actor_id"
    t.bigint "agency_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "contractor_charge_id", null: false
    t.bigint "contractor_settlement_line_id"
    t.datetime "created_at", null: false
    t.text "notes"
    t.date "occurred_on", null: false
    t.string "reference"
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_contractor_charge_recoveries_on_actor_id"
    t.index ["agency_id"], name: "index_contractor_charge_recoveries_on_agency_id"
    t.index ["contractor_charge_id"], name: "index_contractor_charge_recoveries_on_contractor_charge_id"
    t.index ["contractor_settlement_line_id"], name: "idx_on_contractor_settlement_line_id_66d99f6593"
  end

  create_table "contractor_charge_waivers", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "agency_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "contractor_charge_id", null: false
    t.datetime "created_at", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_contractor_charge_waivers_on_actor_id"
    t.index ["agency_id"], name: "index_contractor_charge_waivers_on_agency_id"
    t.index ["contractor_charge_id"], name: "index_contractor_charge_waivers_on_contractor_charge_id"
  end

  create_table "contractor_charges", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "charge_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on"
    t.bigint "engagement_id", null: false
    t.bigint "open_balance_cents", null: false
    t.bigint "original_amount_cents", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_contractor_charges_on_agency_id"
    t.index ["engagement_id", "status"], name: "index_contractor_charges_on_engagement_and_status"
    t.index ["engagement_id"], name: "index_contractor_charges_on_engagement_id"
  end

  create_table "contractor_settlement_line_commission_calculations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "commission_calculation_id", null: false
    t.bigint "contractor_settlement_line_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commission_calculation_id"], name: "idx_on_commission_calculation_id_68974ec53d"
    t.index ["contractor_settlement_line_id", "commission_calculation_id"], name: "index_settlement_line_comm_calc_unique", unique: true
    t.index ["contractor_settlement_line_id"], name: "idx_on_contractor_settlement_line_id_3c31823aed"
  end

  create_table "contractor_settlement_line_revenue_inputs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "contractor_settlement_line_id", null: false
    t.datetime "created_at", null: false
    t.bigint "revenue_input_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contractor_settlement_line_id", "revenue_input_id"], name: "index_settlement_line_revenue_unique", unique: true
    t.index ["contractor_settlement_line_id"], name: "idx_on_contractor_settlement_line_id_11bf46bd30"
    t.index ["revenue_input_id"], name: "idx_on_revenue_input_id_2279910aa4"
  end

  create_table "contractor_settlement_lines", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "charge_deductions_cents", default: 0, null: false
    t.bigint "contractor_settlement_run_id", null: false
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.bigint "gross_commission_cents", default: 0, null: false
    t.bigint "manual_adjustment_negative_cents", default: 0, null: false
    t.bigint "manual_adjustment_positive_cents", default: 0, null: false
    t.bigint "net_settlement_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_contractor_settlement_lines_on_agency_id"
    t.index ["contractor_settlement_run_id"], name: "idx_on_contractor_settlement_run_id_f6e1bef308"
    t.index ["engagement_id"], name: "index_contractor_settlement_lines_on_engagement_id"
  end

  create_table "contractor_settlement_run_events", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "actor_id"
    t.bigint "contractor_settlement_run_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_contractor_settlement_run_events_on_actor_id"
    t.index ["contractor_settlement_run_id"], name: "idx_on_contractor_settlement_run_id_26862ac2e4"
  end

  create_table "contractor_settlement_runs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "period_end_on", null: false
    t.date "period_start_on", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "period_start_on", "period_end_on"], name: "index_settlement_runs_on_agency_and_period"
    t.index ["agency_id"], name: "index_contractor_settlement_runs_on_agency_id"
  end

  create_table "daily_worked_hours", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.decimal "hours", precision: 8, scale: 2, null: false
    t.text "notes"
    t.integer "source", default: 0, null: false
    t.datetime "updated_at", null: false
    t.date "work_date", null: false
    t.index ["engagement_id", "work_date"], name: "index_daily_worked_hours_on_engagement_and_work_date", unique: true
    t.index ["engagement_id"], name: "index_daily_worked_hours_on_engagement_id"
  end

  create_table "departments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_department_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_departments_on_agency_id_and_code", unique: true
    t.index ["agency_id", "status"], name: "index_departments_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_departments_on_agency_id"
    t.index ["parent_department_id"], name: "index_departments_on_parent_department_id"
  end

  create_table "document_records", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "byte_size"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.bigint "document_type_id", null: false
    t.bigint "engagement_id"
    t.date "expires_on"
    t.string "filename"
    t.date "issued_on"
    t.bigint "party_id"
    t.text "rejection_reason"
    t.string "status", default: "submitted", null: false
    t.string "storage_key"
    t.date "submitted_on"
    t.bigint "team_member_id"
    t.datetime "updated_at", null: false
    t.text "verification_notes"
    t.bigint "verified_by_id"
    t.date "verified_on"
    t.index ["agency_id", "document_type_id"], name: "index_document_records_on_agency_id_and_document_type_id"
    t.index ["agency_id", "engagement_id"], name: "index_document_records_on_agency_id_and_engagement_id"
    t.index ["agency_id", "expires_on"], name: "index_document_records_on_agency_id_and_expires_on"
    t.index ["agency_id", "status"], name: "index_document_records_on_agency_id_and_status"
    t.index ["agency_id", "team_member_id"], name: "index_document_records_on_agency_id_and_team_member_id"
    t.index ["agency_id"], name: "index_document_records_on_agency_id"
    t.index ["document_type_id"], name: "index_document_records_on_document_type_id"
    t.index ["engagement_id"], name: "index_document_records_on_engagement_id"
    t.index ["party_id"], name: "index_document_records_on_party_id"
    t.index ["team_member_id"], name: "index_document_records_on_team_member_id"
    t.index ["verified_by_id"], name: "index_document_records_on_verified_by_id"
  end

  create_table "document_requirements", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "document_type_id", null: false
    t.boolean "expiration_required", default: false, null: false
    t.integer "expiring_soon_days"
    t.string "name"
    t.string "relationship_type", default: "any", null: false
    t.boolean "required", default: true, null: false
    t.string "requirement_scope", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.boolean "verification_required", default: false, null: false
    t.index ["agency_id", "document_type_id", "requirement_scope", "relationship_type"], name: "idx_document_requirements_agency_type_scope_rel", unique: true
    t.index ["agency_id", "relationship_type"], name: "index_document_requirements_on_agency_id_and_relationship_type"
    t.index ["agency_id", "requirement_scope"], name: "index_document_requirements_on_agency_id_and_requirement_scope"
    t.index ["agency_id", "status"], name: "index_document_requirements_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_document_requirements_on_agency_id"
    t.index ["document_type_id"], name: "index_document_requirements_on_document_type_id"
  end

  create_table "document_types", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "category", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "default_expiring_soon_days"
    t.text "description"
    t.string "name", null: false
    t.boolean "requires_expiration_date", default: false, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.boolean "verification_required", default: false, null: false
    t.index ["agency_id", "category"], name: "index_document_types_on_agency_id_and_category"
    t.index ["agency_id", "code"], name: "index_document_types_on_agency_id_and_code", unique: true
    t.index ["agency_id", "status"], name: "index_document_types_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_document_types_on_agency_id"
  end

  create_table "draw_balance_events", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "actor_id"
    t.bigint "agency_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "commission_calculation_id"
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.string "event_type", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_draw_balance_events_on_actor_id"
    t.index ["agency_id"], name: "index_draw_balance_events_on_agency_id"
    t.index ["commission_calculation_id"], name: "index_draw_balance_events_on_commission_calculation_id"
    t.index ["engagement_id"], name: "index_draw_balance_events_on_engagement_id"
  end

  create_table "engagement_organization_placements", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.date "effective_end_on"
    t.date "effective_start_on", null: false
    t.bigint "engagement_id", null: false
    t.bigint "location_id"
    t.text "notes"
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_engagement_organization_placements_on_agency_id"
    t.index ["department_id"], name: "index_engagement_organization_placements_on_department_id"
    t.index ["engagement_id", "effective_start_on"], name: "index_eop_on_engagement_and_effective_start"
    t.index ["engagement_id"], name: "index_engagement_organization_placements_on_engagement_id"
    t.index ["location_id"], name: "index_engagement_organization_placements_on_location_id"
    t.index ["team_id"], name: "index_engagement_organization_placements_on_team_id"
  end

  create_table "engagement_supervision_assignments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_end_on"
    t.date "effective_start_on", null: false
    t.bigint "engagement_id", null: false
    t.text "notes"
    t.string "relationship_type", default: "primary_reports_to", null: false
    t.bigint "supervisor_engagement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_engagement_supervision_assignments_on_agency_id"
    t.index ["engagement_id", "effective_start_on"], name: "index_esa_on_engagement_and_effective_start"
    t.index ["engagement_id"], name: "index_engagement_supervision_assignments_on_engagement_id"
    t.index ["supervisor_engagement_id"], name: "idx_on_supervisor_engagement_id_434e66448a"
  end

  create_table "engagements", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "end_on"
    t.date "expected_end_on"
    t.text "notes"
    t.string "relationship_type", null: false
    t.date "renewal_on"
    t.date "start_on"
    t.string "status", default: "draft", null: false
    t.bigint "team_member_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["agency_id", "relationship_type", "status"], name: "idx_on_agency_id_relationship_type_status_5288784361"
    t.index ["agency_id", "team_member_id", "relationship_type"], name: "idx_on_agency_id_team_member_id_relationship_type_4125b72122"
    t.index ["agency_id", "team_member_id"], name: "index_engagements_on_agency_id_and_team_member_id"
    t.index ["agency_id"], name: "index_engagements_on_agency_id"
    t.index ["team_member_id"], name: "index_engagements_on_team_member_id"
  end

  create_table "locations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location_type", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_locations_on_agency_id_and_code", unique: true
    t.index ["agency_id", "location_type"], name: "index_locations_on_agency_id_and_location_type"
    t.index ["agency_id", "status"], name: "index_locations_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_locations_on_agency_id"
  end

  create_table "organization_profiles", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "legal_name"
    t.string "organization_kind", null: false
    t.bigint "party_id", null: false
    t.string "trade_name"
    t.datetime "updated_at", null: false
    t.index ["organization_kind"], name: "index_organization_profiles_on_organization_kind"
    t.index ["party_id"], name: "index_organization_profiles_on_party_id", unique: true
  end

  create_table "parties", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "external_reference"
    t.text "notes"
    t.string "party_type", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "party_type"], name: "index_parties_on_agency_id_and_party_type"
    t.index ["agency_id", "status"], name: "index_parties_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_parties_on_agency_id"
  end

  create_table "party_contact_methods", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "contact_type", null: false
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false, null: false
    t.string "label"
    t.text "normalized_value"
    t.bigint "party_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["party_id", "contact_type"], name: "index_party_contact_methods_on_party_id_and_contact_type"
    t.index ["party_id"], name: "index_party_contact_methods_on_party_id"
  end

  create_table "party_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_end_date"
    t.date "effective_start_date"
    t.text "notes"
    t.string "relationship_type", null: false
    t.bigint "source_party_id", null: false
    t.string "status", default: "active", null: false
    t.bigint "target_party_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "source_party_id", "relationship_type"], name: "index_party_relationships_on_agency_source_type"
    t.index ["agency_id"], name: "index_party_relationships_on_agency_id"
    t.index ["source_party_id"], name: "index_party_relationships_on_source_party_id"
    t.index ["target_party_id"], name: "index_party_relationships_on_target_party_id"
  end

  create_table "pay_periods", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "closed_at"
    t.bigint "closed_by_id"
    t.datetime "created_at", null: false
    t.date "end_on", null: false
    t.string "label"
    t.string "payroll_frequency", default: "legacy", null: false
    t.date "start_on", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "start_on", "end_on"], name: "index_pay_periods_on_agency_and_bounds"
    t.index ["agency_id"], name: "index_pay_periods_on_agency_id"
    t.index ["closed_by_id"], name: "index_pay_periods_on_closed_by_id"
  end

  create_table "payroll_earning_codes", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "category", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_payroll_earning_codes_on_code", unique: true
  end

  create_table "payroll_exports", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "export_sequence", null: false
    t.datetime "exported_at", null: false
    t.bigint "exported_by_id"
    t.string "file_format", null: false
    t.boolean "is_final", default: false, null: false
    t.text "notes"
    t.bigint "pay_period_id", null: false
    t.string "storage_reference"
    t.datetime "updated_at", null: false
    t.index ["exported_by_id"], name: "index_payroll_exports_on_exported_by_id"
    t.index ["pay_period_id", "export_sequence"], name: "index_payroll_exports_on_pay_period_and_sequence", unique: true
    t.index ["pay_period_id"], name: "index_payroll_exports_on_pay_period_id"
  end

  create_table "person_profiles", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.bigint "party_id", null: false
    t.string "preferred_name"
    t.string "suffix"
    t.datetime "updated_at", null: false
    t.index ["party_id"], name: "index_person_profiles_on_party_id", unique: true
  end

  create_table "revenue_inputs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.bigint "commissionable_revenue_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.bigint "gross_sales_cents"
    t.text "notes"
    t.bigint "pay_period_id"
    t.date "period_end_on", null: false
    t.date "period_start_on", null: false
    t.string "source_type", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_revenue_inputs_on_agency_id"
    t.index ["engagement_id", "pay_period_id"], name: "index_revenue_inputs_on_engagement_and_pay_period"
    t.index ["engagement_id"], name: "index_revenue_inputs_on_engagement_id"
    t.index ["pay_period_id"], name: "index_revenue_inputs_on_pay_period_id"
  end

  create_table "team_members", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.bigint "party_id", null: false
    t.string "status", default: "active", null: false
    t.string "team_member_number"
    t.datetime "updated_at", null: false
    t.index ["agency_id", "party_id"], name: "index_team_members_on_agency_and_party_unique", unique: true
    t.index ["agency_id", "team_member_number"], name: "index_team_members_on_agency_and_number_unique", unique: true
    t.index ["agency_id"], name: "index_team_members_on_agency_id"
    t.index ["party_id"], name: "index_team_members_on_party_id"
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.text "description"
    t.bigint "location_id"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_teams_on_agency_id_and_code", unique: true
    t.index ["agency_id", "department_id"], name: "index_teams_on_agency_id_and_department_id"
    t.index ["agency_id", "location_id"], name: "index_teams_on_agency_id_and_location_id"
    t.index ["agency_id", "status"], name: "index_teams_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_teams_on_agency_id"
    t.index ["department_id"], name: "index_teams_on_department_id"
    t.index ["location_id"], name: "index_teams_on_location_id"
  end

  create_table "user_agencies", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["agency_id"], name: "index_user_agencies_on_agency_id"
    t.index ["user_id", "agency_id"], name: "index_user_agencies_on_user_id_and_agency_id", unique: true
    t.index ["user_id"], name: "index_user_agencies_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weekly_timesheets", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "engagement_id", null: false
    t.datetime "rejected_at"
    t.bigint "rejected_by_id"
    t.text "rejection_reason"
    t.string "status", default: "draft", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.date "week_end_on", null: false
    t.date "week_start_on", null: false
    t.index ["approved_by_id"], name: "index_weekly_timesheets_on_approved_by_id"
    t.index ["engagement_id", "week_start_on"], name: "index_weekly_timesheets_on_engagement_and_week_start", unique: true
    t.index ["engagement_id"], name: "index_weekly_timesheets_on_engagement_id"
    t.index ["rejected_by_id"], name: "index_weekly_timesheets_on_rejected_by_id"
  end

  add_foreign_key "agency_payroll_configurations", "agencies"
  add_foreign_key "commission_calculations", "agencies"
  add_foreign_key "commission_calculations", "engagements"
  add_foreign_key "commission_calculations", "pay_periods"
  add_foreign_key "commission_calculations", "revenue_inputs"
  add_foreign_key "commission_draw_balances", "agencies"
  add_foreign_key "commission_draw_balances", "engagements"
  add_foreign_key "compensation_plan_assignments", "agencies"
  add_foreign_key "compensation_plan_assignments", "compensation_plans"
  add_foreign_key "compensation_plan_assignments", "engagements"
  add_foreign_key "compensation_plans", "agencies"
  add_foreign_key "contractor_charge_recoveries", "agencies"
  add_foreign_key "contractor_charge_recoveries", "contractor_charges"
  add_foreign_key "contractor_charge_recoveries", "contractor_settlement_lines"
  add_foreign_key "contractor_charge_recoveries", "users", column: "actor_id"
  add_foreign_key "contractor_charge_waivers", "agencies"
  add_foreign_key "contractor_charge_waivers", "contractor_charges"
  add_foreign_key "contractor_charge_waivers", "users", column: "actor_id"
  add_foreign_key "contractor_charges", "agencies"
  add_foreign_key "contractor_charges", "engagements"
  add_foreign_key "contractor_settlement_line_commission_calculations", "commission_calculations"
  add_foreign_key "contractor_settlement_line_commission_calculations", "contractor_settlement_lines"
  add_foreign_key "contractor_settlement_line_revenue_inputs", "contractor_settlement_lines"
  add_foreign_key "contractor_settlement_line_revenue_inputs", "revenue_inputs"
  add_foreign_key "contractor_settlement_lines", "agencies"
  add_foreign_key "contractor_settlement_lines", "contractor_settlement_runs"
  add_foreign_key "contractor_settlement_lines", "engagements"
  add_foreign_key "contractor_settlement_run_events", "contractor_settlement_runs"
  add_foreign_key "contractor_settlement_run_events", "users", column: "actor_id"
  add_foreign_key "contractor_settlement_runs", "agencies"
  add_foreign_key "daily_worked_hours", "engagements"
  add_foreign_key "departments", "agencies"
  add_foreign_key "departments", "departments", column: "parent_department_id"
  add_foreign_key "document_records", "agencies"
  add_foreign_key "document_records", "document_types"
  add_foreign_key "document_records", "engagements"
  add_foreign_key "document_records", "parties"
  add_foreign_key "document_records", "team_members"
  add_foreign_key "document_records", "users", column: "verified_by_id"
  add_foreign_key "document_requirements", "agencies"
  add_foreign_key "document_requirements", "document_types"
  add_foreign_key "document_types", "agencies"
  add_foreign_key "draw_balance_events", "agencies"
  add_foreign_key "draw_balance_events", "commission_calculations"
  add_foreign_key "draw_balance_events", "engagements"
  add_foreign_key "draw_balance_events", "users", column: "actor_id"
  add_foreign_key "engagement_organization_placements", "agencies"
  add_foreign_key "engagement_organization_placements", "departments"
  add_foreign_key "engagement_organization_placements", "engagements"
  add_foreign_key "engagement_organization_placements", "locations"
  add_foreign_key "engagement_organization_placements", "teams"
  add_foreign_key "engagement_supervision_assignments", "agencies"
  add_foreign_key "engagement_supervision_assignments", "engagements"
  add_foreign_key "engagement_supervision_assignments", "engagements", column: "supervisor_engagement_id"
  add_foreign_key "engagements", "agencies"
  add_foreign_key "engagements", "team_members"
  add_foreign_key "locations", "agencies"
  add_foreign_key "organization_profiles", "parties"
  add_foreign_key "parties", "agencies"
  add_foreign_key "party_contact_methods", "parties"
  add_foreign_key "party_relationships", "agencies"
  add_foreign_key "party_relationships", "parties", column: "source_party_id"
  add_foreign_key "party_relationships", "parties", column: "target_party_id"
  add_foreign_key "pay_periods", "agencies"
  add_foreign_key "pay_periods", "users", column: "closed_by_id"
  add_foreign_key "payroll_exports", "pay_periods"
  add_foreign_key "payroll_exports", "users", column: "exported_by_id"
  add_foreign_key "person_profiles", "parties"
  add_foreign_key "revenue_inputs", "agencies"
  add_foreign_key "revenue_inputs", "engagements"
  add_foreign_key "revenue_inputs", "pay_periods"
  add_foreign_key "team_members", "agencies"
  add_foreign_key "team_members", "parties"
  add_foreign_key "teams", "agencies"
  add_foreign_key "teams", "departments"
  add_foreign_key "teams", "locations"
  add_foreign_key "user_agencies", "agencies"
  add_foreign_key "user_agencies", "users"
  add_foreign_key "weekly_timesheets", "engagements"
  add_foreign_key "weekly_timesheets", "users", column: "approved_by_id"
  add_foreign_key "weekly_timesheets", "users", column: "rejected_by_id"
end
