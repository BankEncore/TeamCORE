A good TC-23a breakdown should:

* keep foundational semantics ahead of implementation
* avoid prematurely building payroll-engine complexity
* separate configuration from operational workflows
* isolate overtime logic from exports/imports
* leave downstream epics cleanly dependent on TC-23a

I would structure TC-23a into:

* planning/specification tasks
* foundational infrastructure
* operational period generation
* overtime/payroll summary foundations
* closure/export posture
* reporting/read-model support
* hardening/tests

---

# Recommended TC-23a Breakdown

## TC-23a.01 — Payroll Calendar and Workweek ADR

**Type:** `adr` / `architecture`
**Purpose:** Formalize TC-23a operational semantics.

### Deliverables

* ADR
* glossary updates
* operational vocabulary
* future-boundary documentation

### Covers

* workweek vs pay period
* payroll frequencies
* overtime posture
* export posture
* lifecycle semantics
* contractor separation

This is effectively the governance/specification anchor.

---

# TC-23a.02 — Agency Payroll Configuration Foundation

**Type:** `feature`

## Purpose

Introduce agency-level payroll/work-calendar configuration.

### Suggested scope

* payroll frequency
* workweek start day
* payroll timezone
* overtime threshold

### Deliverables

* migration(s)
* model/config structure
* validations
* admin UI
* tests

### Notes

Keep lightweight and employee-focused.

Avoid:

* payroll groups
* multiple schedules
* jurisdiction engines

---

# TC-23a.03 — Pay Period Model and Lifecycle

**Type:** `feature`

## Purpose

Implement persisted employee payroll periods.

### Suggested scope

* PayPeriod model
* automatic generation
* open/closed lifecycle
* semimonthly handling
* validations
* current/open-period helpers

### Deliverables

* migrations
* model
* generator service
* lifecycle helpers
* tests

### Important

Do NOT introduce:

* PayrollRun
* PayrollBatch
* reconciliation engines

---

# TC-23a.04 — Pay Period Generation Service

**Type:** `feature`

## Purpose

Generate payroll periods automatically from agency configuration.

### Suggested scope

* weekly generation
* biweekly generation
* semimonthly generation
* monthly generation
* duplicate prevention
* future-period generation strategy

### Deliverables

* generation service
* tests
* rake/admin task
* validation coverage

### Important

This should remain deterministic and idempotent.

---

# TC-23a.05 — Workweek and Overtime Foundation

**Type:** `feature`

## Purpose

Implement foundational overtime/workweek aggregation behavior.

### Suggested scope

* workweek boundary helpers
* weekly aggregation
* worked-hours distinction
* overtime threshold handling
* overtime calculations
* leave exclusion from OT

### Deliverables

* overtime calculator/service
* workweek helper utilities
* tests

### Important

Must leave room for:

* daily OT
* double-time
* jurisdiction rules

without implementing them now.

---

# TC-23a.06 — Payroll Summary Aggregation Foundation

**Type:** `feature`

## Purpose

Implement payroll-summary aggregation structures used by downstream payroll workflows.

### Suggested scope

* regular hours
* overtime hours
* leave hours
* total paid hours

### Deliverables

* aggregation service
* summary presenter/read model
* tests

### Important

Initially derived dynamically.

Avoid snapshot-heavy infrastructure initially.

---

# TC-23a.07 — Payroll Export Tracking Foundation

**Type:** `feature`

## Purpose

Track payroll export history and finalized export posture.

### Suggested scope

* PayrollExport model
* export history
* draft exports
* finalized export semantics
* export linkage to pay periods

### Deliverables

* migrations
* export-tracking models
* basic UI/history
* tests

### Important

This is NOT full payroll-run infrastructure.

Keep lightweight.

---

# TC-23a.08 — Pay Period Closure and Validation

**Type:** `feature`

## Purpose

Implement pay-period closure workflows and validation posture.

### Suggested scope

* closure validation
* missing-timesheet checks
* pending-approval checks
* override support
* capability-based closure

### Deliverables

* closure service
* validation services
* tests

### Important

Closure means:

```text id="gghs4k"
payroll-processing complete
```

—not financial close.

---

# TC-23a.09 — Reporting and Operational Visibility Foundations

**Type:** `feature`

## Purpose

Provide lightweight operational visibility/read models for payroll periods.

### Suggested scope

* current pay period
* missing timesheets
* pending approvals
* overtime visibility
* export history
* employee payroll summaries

### Deliverables

* query/read-model helpers
* lightweight reporting surfaces
* Team360 hooks

### Important

This should support downstream Team360/reporting work, not replace it.

---

# TC-23a.10 — Permissions and Capability Hooks

**Type:** `feature` / `hardening`

## Purpose

Introduce capability hooks for:

* period closure
* overrides
* export authority

### Deliverables

* policy hooks
* capability checks
* tests

### Important

Remain lightweight until broader Phase 6 permission hardening.

---

# TC-23a.11 — Seed Data and Test Fixtures

**Type:** `test` / `infra`

## Purpose

Provide realistic payroll/workweek/pay-period fixtures.

### Suggested scope

* weekly periods
* biweekly periods
* semimonthly periods
* overtime scenarios
* PTO scenarios
* cross-week aggregation scenarios

### Important

Especially important for:

* overtime edge cases
* semimonthly boundaries
* future payroll reporting

---

# Suggested sequencing

## Planning/governance

1. TC-23a.01 ADR + glossary

---

## Core infrastructure

2. TC-23a.02 Payroll configuration
3. TC-23a.03 PayPeriod model
4. TC-23a.04 Generation service

---

## Operational calculations

5. TC-23a.05 Workweek/overtime foundation
6. TC-23a.06 Payroll summary foundation

---

## Operational workflows

7. TC-23a.07 Export tracking
8. TC-23a.08 Closure/validation

---

## Visibility/hardening

9. TC-23a.09 Reporting foundations
10. TC-23a.10 Capability hooks
11. TC-23a.11 Seeds/tests

---

# One recommendation

Keep TC-23a intentionally operational.

Whenever implementation starts drifting toward:

* payroll accounting
* reconciliation engines
* ledger semantics
* payroll batch orchestration
* tax-processing behavior

that probably belongs:

* later
* elsewhere
* or not in TeamCORE at all.
