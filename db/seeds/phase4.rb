# frozen_string_literal: true

# Phase 4 demo financials: compensation catalog, assignments, pay periods, revenue,
# commission + draw (employee), contractor charges / waiver, settlement compose (hybrid lineage).
# Idempotent for typical re-runs. Requires baseline db/seeds.rb (Example Agency + demo engagements).

agency = Agency.find_by(code: "example")
return unless agency

admin_user = User.find_by(email: "admin@example.com")

jane_eng = Engagement.joins(team_member: :party).find_by!(
  agency:,
  relationship_type: "employee",
  parties: { external_reference: "demo_jane_employee" }
)

robert_eng = Engagement.joins(team_member: :party).find_by!(
  agency:,
  relationship_type: "individual_contractor",
  parties: { external_reference: "demo_robert_contractor" }
)

co_eng = Engagement.joins(team_member: :party).find_by!(
  agency:,
  relationship_type: "contractor_organization",
  parties: { external_reference: "demo_contractor_organization" }
)

demo_anchor = Date.new(2024, 1, 1)

employee_plan = CompensationPlan.find_or_initialize_by(agency:, name: "Demo employee commission + minimum")
employee_plan.assign_attributes(
  plan_type: "commission_only",
  status: "active",
  default_commission_rate_bps: 1000,
  minimum_commission_basis: "fixed_amount",
  minimum_commission_amount_cents: 200_000,
  recovery_rule: "recover_from_excess_commission"
)
employee_plan.save!

contractor_plan = CompensationPlan.find_or_initialize_by(agency:, name: "Demo contractor flat commission")
contractor_plan.assign_attributes(
  plan_type: "commission_only",
  status: "active",
  default_commission_rate_bps: 800
)
contractor_plan.save!

[
  [ jane_eng, employee_plan ],
  [ robert_eng, contractor_plan ],
  [ co_eng, contractor_plan ]
].each do |eng, plan|
  assignment = CompensationPlanAssignment.find_or_initialize_by(engagement: eng, effective_start_on: demo_anchor)
  assignment.assign_attributes(
    agency:,
    compensation_plan: plan,
    effective_end_on: nil,
    snapshot_plan_name: plan.name,
    snapshot_plan_type: plan.plan_type,
    snapshot_commission_rate_bps: plan.default_commission_rate_bps,
    snapshot_minimum_basis: plan.minimum_commission_basis,
    snapshot_minimum_amount_cents: plan.minimum_commission_amount_cents,
    snapshot_recovery_rule: plan.recovery_rule,
    snapshot_salary_annual_cents: plan.salary_annual_cents,
    snapshot_hourly_rate_cents: plan.hourly_rate_cents
  )
  assignment.save!
end

pp1 = PayPeriod.find_or_initialize_by(agency:, start_on: Date.new(2024, 1, 1), end_on: Date.new(2024, 1, 15))
pp1.assign_attributes(label: "2024-01-01 — 01/15 demo")
pp1.save!

pp2 = PayPeriod.find_or_initialize_by(agency:, start_on: Date.new(2024, 1, 16), end_on: Date.new(2024, 1, 31))
pp2.assign_attributes(label: "2024-01-16 — 01/31 demo")
pp2.save!

jane_low = RevenueInput.find_or_initialize_by(
  agency:,
  engagement: jane_eng,
  pay_period: pp1,
  period_start_on: pp1.start_on,
  period_end_on: pp1.end_on,
  source_type: "manual"
)
jane_low.assign_attributes(
  commissionable_revenue_cents: 1_500_000,
  notes: "Phase 4 seed: commission below minimum (draw)"
)
jane_low.save!
Financials::ApplyCommissionAndDraw.call(revenue_input: jane_low, actor: admin_user)

jane_high = RevenueInput.find_or_initialize_by(
  agency:,
  engagement: jane_eng,
  pay_period: pp2,
  period_start_on: pp2.start_on,
  period_end_on: pp2.end_on,
  source_type: "manual"
)
jane_high.assign_attributes(
  commissionable_revenue_cents: 5_000_000,
  notes: "Phase 4 seed: commission above minimum (draw recovery)"
)
jane_high.save!
Financials::ApplyCommissionAndDraw.call(revenue_input: jane_high, actor: admin_user)

robert_manual = RevenueInput.find_or_initialize_by(
  agency:,
  engagement: robert_eng,
  period_start_on: pp1.start_on,
  period_end_on: pp1.end_on,
  source_type: "manual"
)
robert_manual.assign_attributes(
  commissionable_revenue_cents: 2_500_000,
  notes: "Phase 4 seed: contractor manual revenue"
)
robert_manual.save!
Financials::ApplyCommissionAndDraw.call(revenue_input: robert_manual, actor: admin_user)

robert_imported = RevenueInput.find_or_initialize_by(
  agency:,
  engagement: robert_eng,
  period_start_on: pp2.start_on,
  period_end_on: pp2.end_on,
  source_type: "imported_csv"
)
robert_imported.assign_attributes(
  commissionable_revenue_cents: 1_000_000,
  notes: "Phase 4 seed: contractor imported_csv row"
)
robert_imported.save!
Financials::ApplyCommissionAndDraw.call(revenue_input: robert_imported, actor: admin_user)

co_rev = RevenueInput.find_or_initialize_by(
  agency:,
  engagement: co_eng,
  period_start_on: pp1.start_on,
  period_end_on: pp1.end_on,
  source_type: "manual"
)
co_rev.assign_attributes(
  commissionable_revenue_cents: 3_000_000,
  notes: "Phase 4 seed: contractor org revenue"
)
co_rev.save!
Financials::ApplyCommissionAndDraw.call(revenue_input: co_rev, actor: admin_user)

equipment_charge = ContractorCharge.find_or_initialize_by(
  agency:,
  engagement: robert_eng,
  charge_type: "phase4_seed_equipment"
)
if equipment_charge.new_record?
  equipment_charge.assign_attributes(
    original_amount_cents: 50_000,
    open_balance_cents: 50_000,
    status: "open",
    due_on: Date.new(2024, 2, 1),
    description: "Demo equipment retainer (Phase 4 seed)"
  )
  equipment_charge.save!
end

training_charge = ContractorCharge.find_or_initialize_by(
  agency:,
  engagement: robert_eng,
  charge_type: "phase4_seed_training"
)
if training_charge.new_record?
  training_charge.assign_attributes(
    original_amount_cents: 20_000,
    open_balance_cents: 20_000,
    status: "open",
    due_on: Date.new(2024, 3, 1),
    description: "Demo training fee (Phase 4 seed)"
  )
  training_charge.save!
  ContractorChargeWaiver.create!(
    agency:,
    contractor_charge: training_charge,
    actor: admin_user,
    amount_cents: 5_000,
    reason: "Phase 4 seed partial waiver"
  )
end

settlement_run = ContractorSettlementRun.find_or_initialize_by(
  agency:,
  period_start_on: pp1.start_on,
  period_end_on: pp2.end_on
)
if settlement_run.new_record?
  settlement_run.status = "draft"
end
settlement_run.save!

unless settlement_run.contractor_settlement_lines.where(engagement_id: robert_eng.id).exists?
  Financials::ContractorSettlement::ComposeLine.call(
    run: settlement_run,
    engagement: robert_eng,
    actor: admin_user,
    revenue_input_ids: [ robert_manual.id, robert_imported.id ],
    commission_calculation_ids: [],
    contractor_charge_ids: [ equipment_charge.id ]
  )
end

unless settlement_run.contractor_settlement_lines.where(engagement_id: co_eng.id).exists?
  Financials::ContractorSettlement::ComposeLine.call(
    run: settlement_run,
    engagement: co_eng,
    actor: admin_user,
    revenue_input_ids: [ co_rev.id ],
    commission_calculation_ids: [],
    contractor_charge_ids: []
  )
end

unless settlement_run.contractor_settlement_run_events.where(event_type: "calculated").exists?
  ContractorSettlementRunEvent.create!(
    contractor_settlement_run: settlement_run,
    event_type: "calculated",
    actor: admin_user,
    reason: "Phase 4 seed: lines composed"
  )
end
