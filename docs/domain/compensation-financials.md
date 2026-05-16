# Compensation & revenue financials — TeamCORE

**Epics:** **TC-13** — Compensation plan assignment · **TC-14** — Revenue inputs · **TC-15** — Flat-rate commission · **TC-16** — Minimum commission draw (employee-only).

**Purpose:** Locked persistence and service boundaries for **engagement-scoped** compensation catalogs, effective assignments, optional pay periods, revenue capture, commission calculation, and **employee-only** minimum draw accrual/recovery. This is **not** a payroll tax engine or full payroll run (Phase 5).

**Product rules:** [phase-4-developer-brief.md](../roadmap/phase-4-developer-brief.md) (§5–§8, §12 compensation).  
**Adjacent domains:** [contractor-charges.md](contractor-charges.md), [contractor-settlement.md](contractor-settlement.md) · **Modeling hub:** [workforce-financial-modeling.md](workforce-financial-modeling.md) · **ERD:** [model-erd.md](model-erd.md)  
**Migration (DDL):** `db/migrate/20260516120000_phase4_compensation_settlement.rb`

**Engagement is the anchor** for plan assignment, revenue inputs, and commission calculations (brief §4).

**Scope guard:** Operational workforce / payment-support records, not a general ledger (brief §1, §14).

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
| 2026-05-16 | `compensation_plans`, `compensation_plan_assignments` in initial workforce-financials migration. |

---

## 2. Pay periods (commission / employee rail)

### Decided

- **Shared scheduling vocabulary** optional and thin at first (e.g. `ScheduleTemplate`). Must not block TC-13/14.
- **Operational record:** **`PayPeriod`** supports **employee / pay-period-centric** revenue and commission (TC-14–TC-16).
- **No** single unified `FinancialPeriod` owning both payroll lifecycle and contractor settlement lifecycle in MVP (settlement periods live on **`ContractorSettlementRun`** — [contractor-settlement.md](contractor-settlement.md)).

### As implemented

- **`PayPeriod`** (`agency_id`, `start_on`, `end_on`, `label`) — optional FK on `RevenueInput` and `CommissionCalculation`.
- No `PayrollRun` table in this rail (reserved for Phase 5 payroll product language).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `pay_periods`; `revenue_inputs.pay_period_id`, `commission_calculations.pay_period_id`. |

---

## 3. Revenue inputs & import MVP (TC-14)

### Decided

- MVP supports **manual and imported** inputs (brief).
- **Import MVP:** admin **CSV upload**, column mapping, corrections before commit.
- **Out of scope for MVP import:** vendor APIs, booking systems, scheduled sync, heavy normalization.

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `Admin::Engagements::RevenueInputsController#import_csv`; expected headers include period dates and commissionable revenue (see controller/view). |

---

## 4. Commission calculation & lock (TC-15)

### As implemented

- **`CommissionCalculation`** — agency, engagement, optional `pay_period_id`, optional `revenue_input_id`; rate and money columns; **`status`** `draft` \| `finalized`.
- **`Financials::ApplyCommissionAndDraw`** produces/updates a **draft** calculation from `RevenueInput` and assignment terms; **raises** if an existing calculation for that revenue input is **finalized** (recalc blocked).
- Admin **`CommissionCalculationsController#finalize`** sets **`draft` → `finalized`** from the engagement commission index (recalc and revenue edits then respect the lock).
- Admin revenue UI: **edit** / **calculate** blocked while finalized; revenue index hides **Calc** for those rows.

### Explicitly deferred

- Booking-level commission, multi-rate stacks, external booking systems.

---

## 5. Minimum commission draw (TC-16)

### Decided

- **Employee-only** accrual and recovery in the **compensation** rail — **not** as contractor settlement deductions ([relationship-type guards](#relationship-type-guards) below, brief §8).

### As implemented

- **`CommissionDrawBalance`** — engagement-scoped running balance.
- **`DrawBalanceEvent`** — `event_type`, `amount_cents`, optional `commission_calculation_id`, `actor_id` (see [Operational history](#operational-history-tc-16)).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `commission_draw_balances`, `draw_balance_events`. |

---

## Operational history (TC-16)

**Do not** use one catch-all `FinancialAuditEvent` with opaque JSON for draw explainability (see [workforce-financial-modeling.md](workforce-financial-modeling.md) — cross-domain audit posture).

| Area | Table / model |
| --- | --- |
| TC-16 | `DrawBalanceEvent` |

---

## Relationship-type guards

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

## Lifecycle storage (Rails vs DB)

- Prefer **Ruby validations** and **constants** for `CommissionCalculation#status` early.
- **Defer** native DB enums and broad CHECK constraints until lifecycle semantics stabilize.

---

## Team360 read surfaces (compensation)

- **`Team360::ProfileAssembler#build_workforce_financial`** exposes assignment summary and (when eligible) **draw balance**; **coarse draw visibility** via **`User#team360_show_employee_draw_balance?`** (default `true` until TC-29/30).
- **Admin shortcut links** in payload: revenue inputs, commission calculations (see assembler).
- Team360 does **not** own workflow; mutation stays in admin (see [team360.md](team360.md)).

---

## References

Locked decisions align with engineering execution notes (`.cursor/plans/` when used). Link **GitHub issues/PRs** for TC-13–TC-16 here and to the [developer brief](../roadmap/phase-4-developer-brief.md).

## Related docs

- [engagement.md](engagement.md) — relationship types (financial anchor)
- [team360.md](team360.md) — read aggregation
- [../product/overview.md](../product/overview.md) — employee draw vs contractor settlement
