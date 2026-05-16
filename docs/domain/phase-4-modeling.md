# Phase 4 — data modeling notes

**Status:** Locked decisions implemented in `db/migrate/20260516120000_phase4_compensation_settlement.rb` and `app/models/`.  
**Epics:** TC-13 through TC-19 — **link issue/PR descriptions to this file** and to [phase-4-developer-brief.md](../roadmap/phase-4-developer-brief.md).  
**Authoritative product/rules:** [phase-4-developer-brief.md](../roadmap/phase-4-developer-brief.md)  
**ERD (code truth):** [model-erd.md](model-erd.md) — update in the same PR as new `app/models` / migrations.

## Purpose

This document records **locked Phase 4 architecture decisions** for persistence and boundaries. It is not a full technical spec; implementation details live in migrations, models, services, and the developer brief.

**Engagement is the financial anchor** for plan assignment, revenue inputs, commission calculations, contractor charges, and settlement lines (brief Section 4).

**Scope guard:** Phase 4 models are **operational workforce / payment-support** records, not a general ledger or full AP/AR system (brief Sections 1 and 14).

---

## 1. Compensation plan shape (TC-13)

### Decided

| Concept | Role |
| --- | --- |
| **Catalog** | Reusable per-agency plan definitions. |
| **Assignment** | Authoritative **engagement-scoped** row with effective dating. |
| **Snapshots** | Assignment stores terms used for calculations so catalog edits do not rewrite history. |

### As implemented

**`CompensationPlan`**

- `agency_id`, `name`, `plan_type`, `status` (defaults to `active`)
- Money / rate defaults: `salary_annual_cents`, `hourly_rate_cents`, `default_commission_rate_bps`, `minimum_commission_amount_cents`, `minimum_commission_basis`, `recovery_rule`

**`CompensationPlanAssignment`**

- `agency_id`, `engagement_id`, `compensation_plan_id`
- `effective_start_on`, `effective_end_on`
- Snapshots: `snapshot_plan_name`, `snapshot_plan_type`, `snapshot_commission_rate_bps`, `snapshot_minimum_basis`, `snapshot_minimum_amount_cents`, `snapshot_recovery_rule`, `snapshot_salary_annual_cents`, `snapshot_hourly_rate_cents`

### Explicitly deferred

- Component/stacked compensation engine, STI hierarchy explosion, formula/DSL, booking-level commission decomposition.

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `compensation_plans`, `compensation_plan_assignments` in `Phase4CompensationSettlement` migration. |

---

## 2. Scheduling and period records

### Decided

- **Shared scheduling vocabulary** optional and thin at first (e.g. `ScheduleTemplate`: frequency, cadence, anchor, timezone). Must not block TC-13/14.
- **Separate operational records** for:
  - **Employee / pay-period-centric** work (revenue, commission, **minimum commission draw** — TC-14–TC-16).
  - **Contractor settlement-centric** work (`ContractorSettlementRun` with explicit period `start_on` / `end_on`, brief Section 11).
- **No** single unified `FinancialPeriod` table owning **both** payroll and contractor settlement **lifecycle** in MVP.

### As implemented

**Pay-period side**

- **`PayPeriod`** (`agency_id`, `start_on`, `end_on`, `label`) — optional FK on `RevenueInput` and `CommissionCalculation`.
- No `PayrollRun` table in Phase 4 (reserved for Phase 5 product language).

**Settlement side**

- **`ContractorSettlementRun`** (`agency_id`, `period_start_on`, `period_end_on`, `status`) — contractor settlement period bounds on the run.
- **`ContractorSettlementLine`** belongs to run + `engagement`; snapshot totals and `net_settlement_cents` (MVP ≥ 0).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `pay_periods`, `contractor_settlement_runs`, `contractor_settlement_lines`; `revenue_inputs.pay_period_id`, `commission_calculations.pay_period_id`. |

---

## 3. Settlement lineage (TC-19) — hybrid

### Decided

- **`ContractorSettlementLine`** (or equivalent) stores **snapshot totals** (e.g. gross commission, charge deductions, adjustments, **net ≥ 0** in MVP).
- **Plus** persisted **links** to selected sources (join or child tables), not only derived-on-read.

### Join tables (as implemented)

| Table | Purpose |
| --- | --- |
| `contractor_settlement_line_revenue_inputs` | Line ↔ revenue input (unique pair) |
| `contractor_settlement_line_commission_calculations` | Line ↔ commission calculation (unique pair) |
| `contractor_charge_recoveries` | Charge recovery rows; optional `contractor_settlement_line_id` when applied in settlement |

Line-level adjustments: `manual_adjustment_positive_cents` / `manual_adjustment_negative_cents` on **`ContractorSettlementLine`**.

### Anti-patterns

- Snapshot-only lines with no source linkage (weak audit trail).
- No snapshots (finalized totals change when sources change).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | Hybrid totals on line + join rows; `Financials::ContractorSettlement::ComposeLine` caps deductions so net ≥ 0. Run `status` + `contractor_settlement_run_events` for lifecycle. |

---

## 4. Operational history (no generic financial blob)

### Decided

- **Do not** use one catch-all `FinancialAuditEvent` with opaque JSON for Phase 4.
- Use **targeted**, queryable history where the product requires explainability (brief Section 13).

### As implemented

| Area | Table / model |
| --- | --- |
| TC-16 | `DrawBalanceEvent` |
| TC-17 / TC-18 | `ContractorChargeRecovery`, `ContractorChargeWaiver` |
| TC-19 | `ContractorSettlementRunEvent` |

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `draw_balance_events` (`event_type`, `amount_cents`, optional `commission_calculation_id`, `actor_id` → users). `contractor_charge_waivers`, `contractor_charge_recoveries` with `actor` where applicable. `contractor_settlement_run_events` on runs. |

---

## 5. TC-14 revenue inputs — import MVP

### Decided

- MVP supports **manual and imported** inputs (brief).
- **Import MVP:** admin **CSV upload**, column mapping, **preview/review**, corrections before commit.
- **Out of scope for MVP import:** vendor APIs, booking systems, scheduled sync, heavy normalization.

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | Admin: `Admin::Engagements::RevenueInputsController#import_csv` — preview/commit flow; expected headers include period dates and commissionable revenue (see controller/view). Vendor APIs and sync out of scope. |

---

## 6. Relationship-type guards

Enforce at model/service boundary; consider a shared policy/helper later.

| Feature | Allowed `Engagement#relationship_type` |
| --- | --- |
| Minimum commission draw recovery (TC-16) | `employee` |
| Contractor charges (TC-17, TC-18) | `individual_contractor`, `contractor_organization` |
| Contractor settlement (TC-19) | `individual_contractor`, `contractor_organization` |
| TC-17 – TC-19 for `subcontractor` | **Out of scope** in MVP unless a later epic explicitly expands scope |
| Employee payroll input (Phase 5 posture) | `employee` |

**TC-16 must not** be implemented as contractor settlement deductions; it is **employee-only** compensation / payroll-input preparation.

---

## 7. Lifecycle storage (Rails vs DB)

- Prefer **Ruby validations** and **constants** for settlement/charge statuses early.
- **Defer** native DB enums and broad CHECK constraints until lifecycle semantics stabilize.

---

## References execution plan

Locked decisions match the **Phase 4 execution plan** (`.cursor/plans/`). **GitHub epic/issue descriptions** for TC-13–TC-19 should link here and to the developer brief for traceability.

## Related docs

- [engagement.md](engagement.md) — relationship types and spine
- [team360.md](team360.md) — read-only aggregation; not workflow owner
- [../product/overview.md](../product/overview.md) — product boundaries (employee draw vs contractor settlement)
