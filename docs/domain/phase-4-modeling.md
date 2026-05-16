# Phase 4 — data modeling notes

**Status:** Draft scaffold (decisions agreed; names and migrations filled in during implementation)  
**Epics:** TC-13 through TC-19  
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

### Sketch (fill in exact columns in migrations)

**`CompensationPlan` (TBD final name)**

- `agency_id` (required)
- Human-facing identity: name, code (if any), `status`
- `plan_type` (or equivalent enum in Ruby)
- Defaults for MVP rails: salary/hourly/flat commission/minimum draw fields as product requires
- Money in **cents**; commission rates in **basis points** (brief Section 5)

**`CompensationPlanAssignment` (TBD final name)**

- `agency_id`, `engagement_id`, `compensation_plan_id`
- `effective_start_on` (required), `effective_end_on` (optional; open-ended if null)
- **Snapshot fields** (examples): `snapshot_plan_name`, `snapshot_commission_rate_bps`, `snapshot_minimum_basis`, `snapshot_minimum_amount_cents`, recovery rule snapshot as needed

### Explicitly deferred

- Component/stacked compensation engine, STI hierarchy explosion, formula/DSL, booking-level commission decomposition.

### Implementation log

| Date | Notes |
| --- | --- |
| _TBD_ | Migration(s), model names if different from above |

---

## 2. Scheduling and period records

### Decided

- **Shared scheduling vocabulary** optional and thin at first (e.g. `ScheduleTemplate`: frequency, cadence, anchor, timezone). Must not block TC-13/14.
- **Separate operational records** for:
  - **Employee / pay-period-centric** work (revenue, commission, **minimum commission draw** — TC-14–TC-16).
  - **Contractor settlement-centric** work (`ContractorSettlementRun` with explicit period `start_on` / `end_on`, brief Section 11).
- **No** single unified `FinancialPeriod` table owning **both** payroll and contractor settlement **lifecycle** in MVP.

### Sketch (names TBD)

**Payroll / pay-period side (examples)**

- `PayPeriod` and/or `PayrollRun` — _choose names that avoid collision with Phase 5 payroll run product language_
- FK target for `RevenueInput`, `CommissionCalculation` (employee-context rows)

**Settlement side**

- `SettlementPeriod` (optional) and/or **`ContractorSettlementRun`**
- Settlement lines belong to contractor engagements and reference settlement period bounds as in the brief

### Implementation log

| Date | Notes |
| --- | --- |
| _TBD_ | Chosen table names; FK matrix (which model points to which period/run) |

---

## 3. Settlement lineage (TC-19) — hybrid

### Decided

- **`ContractorSettlementLine`** (or equivalent) stores **snapshot totals** (e.g. gross commission, charge deductions, adjustments, **net ≥ 0** in MVP).
- **Plus** persisted **links** to selected sources (join or child tables), not only derived-on-read.

### Illustrative join / child concepts (rename as implemented)

| Concept | Purpose |
| --- | --- |
| Line ↔ revenue input | Which period revenue rows were selected |
| Line ↔ commission calculation | Which calculation(s) fed the line |
| Line ↔ charge recovery / deduction | Applied contractor charge amounts |
| Manual adjustment rows | Positive/negative adjustments per brief |

### Anti-patterns

- Snapshot-only lines with no source linkage (weak audit trail).
- No snapshots (finalized totals change when sources change).

### Implementation log

| Date | Notes |
| --- | --- |
| _TBD_ | Actual table names; uniqueness rules; finalize vs draft behavior |

---

## 4. Operational history (no generic financial blob)

### Decided

- **Do not** use one catch-all `FinancialAuditEvent` with opaque JSON for Phase 4.
- Use **targeted**, queryable history where the product requires explainability (brief Section 13).

### Sketch

| Area | Targeted concept (illustrative) |
| --- | --- |
| TC-16 | `DrawBalanceEvent` (draw added, recovery, forgiveness, correction) |
| TC-17 / TC-18 | `ContractorChargeRecovery`, `ContractorChargeWaiver` (or equivalent) |
| TC-19 | Settlement status / lifecycle events (finalized, voided, payment recorded) |

### Implementation log

| Date | Notes |
| --- | --- |
| _TBD_ | Actor attribution (`user_id`), timestamps, reasons, amount columns |

---

## 5. TC-14 revenue inputs — import MVP

### Decided

- MVP supports **manual and imported** inputs (brief).
- **Import MVP:** admin **CSV upload**, column mapping, **preview/review**, corrections before commit.
- **Out of scope for MVP import:** vendor APIs, booking systems, scheduled sync, heavy normalization.

### Implementation log

| Date | Notes |
| --- | --- |
| _TBD_ | CSV format assumptions, required columns, idempotency / duplicate handling |

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

Locked decisions are mirrored in the Cursor plan **Phase 4 execution plan** (repo-local `.cursor/plans/phase_4_execution_plan_*.plan.md` if present). Link GitHub epics to **this file** once implementation starts.

## Related docs

- [engagement.md](engagement.md) — relationship types and spine
- [team360.md](team360.md) — read-only aggregation; not workflow owner
- [../product/overview.md](../product/overview.md) — product boundaries (employee draw vs contractor settlement)
