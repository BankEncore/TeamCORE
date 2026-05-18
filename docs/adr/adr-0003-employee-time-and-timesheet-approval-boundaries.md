# ADR-0003: Employee time capture and timesheet approval boundaries (TC-23 / TC-24)

## Status

Proposed

---

## Context

Phase 5 employee payroll workflows require:

- daily worked-hour capture
- weekly timesheet grouping
- supervisor approval
- overtime visibility
- payroll-preparation readiness

before worked hours are treated as payroll-eligible, without turning TeamCORE into a payroll processor.

[ADR-0002](./adr-0002-payroll-period-and-workweek-foundations) establishes:

- pay periods
- workweeks
- timezone posture
- weekly overtime posture
- payroll-period lifecycle
- MVP daily-hours-based time entry

ADR-0002 intentionally does not define:

- time-entry workflow ownership
- submission/approval boundaries
- locking behavior
- overtime visibility semantics
- aggregation responsibilities between TC-23, TC-24, and TC-27

Without an explicit boundary, ownership drifts:

- TC-23 and TC-24 both claim approval behavior
- daily rows and timesheets gain duplicate lifecycle semantics
- overtime visibility becomes ambiguous
- payroll-preparation responsibilities leak into operational workflows

This ADR defines:

- epic ownership
- workflow boundaries
- lifecycle semantics
- editability posture
- overtime visibility semantics
- aggregation boundaries

for TC-23 and TC-24 relative to TC-23a and TC-27.

---

## Decision

### Epic ownership (normative)

#### TC-23 — Employee Time Tracking MVP

TC-23 owns:

- Daily worked-hour persistence
- Weekly timesheet assembly
- Employee/supervisor operational time entry
- Submission mechanics
- Editability and locking mechanics
- Operational visibility
- Workweek-scoped aggregation
- Projected overtime visibility
- Integration with workweek/pay-period boundaries from ADR-0002

TC-23 does not own:

- approve/reject decisions
- payroll eligibility determination
- payroll-period payroll summaries
- earning-code rollups
- payroll exports

#### TC-24 — Employee Timesheet Approval

TC-24 owns:

- approve / return-for-correction / reopen decisions on weekly timesheets (via a single façade service and append-only approval events)
- supervisor / payroll review workflows (**MVP posture:** agency-scoped operational users may act; **direct-report-only routing is not enforced** until supervisor identity mapping hardens — **TC-29**)
- approval auditability (persisted transition lineage on events)
- payroll-eligibility posture (approved worked time only)
- approved overtime semantics (what counts as payroll-eligible OT **after** approval)
- notifications/escalation workflows (incrementally)

TC-24 does not own:

- workweek semantics
- pay-period semantics
- daily hour persistence
- duplicate hour storage
- payroll export generation

#### TC-27 — Payroll Input Workflow

TC-27 owns:

- pay-period payroll summaries
- payroll earning aggregation
- earning-code rollups
- payroll-preparation aggregation
- export-ready payroll data structures

TC-27 consumes approved worked time from TC-24 and pay-period semantics from ADR-0002.

---

### Canonical data posture

#### Daily worked-hour records

Hours live on daily worked-time records.

Daily worked-hour records are the canonical operational source of worked time.

Suggested conceptual shape:

```text
employee engagement
+
work date
+
worked hours
```

with optional:

- notes/comments
- source attribution
- correction metadata

#### Weekly timesheets

MVP standardizes on weekly timesheets.

Weekly timesheets:

- group daily worked-hour rows within a workweek
- own workflow state
- do not own payroll totals as source-of-truth data
- aggregate operational visibility from daily rows

Derived totals may be cached later for performance but daily rows remain authoritative.

---

### Source attribution posture

Worked-time entries should preserve operational source attribution.

Suggested conceptual examples:

| Source Type | Meaning |
| --- | --- |
| `employee` | Employee-entered |
| `supervisor` | Supervisor-entered or corrected |
| `admin` | Payroll/admin correction |
| `imported` | Future imported source |

Source attribution supports:

- operational audit visibility
- Team360 visibility
- correction tracking
- supervisor accountability

without requiring enterprise audit infrastructure in MVP.

---

### Lifecycle and workflow posture

#### Daily worked-hour rows

Daily worked-hour rows do not own approve/reject workflow.

MVP intentionally avoids:

- approval lifecycle on individual day rows
- partial-day approval workflows
- nested approval states

Daily rows are operationally editable according to parent timesheet locking rules.

#### Timesheet lifecycle

Timesheets own workflow state.

##### Persisted statuses (MVP)

Only three values are persisted on **`WeeklyTimesheet.status`**:

| Status | Meaning |
| --- | --- |
| `draft` | Hours may be edited subject to locking rules; sheet is **not** payroll-eligible. |
| `submitted` | Submitted for review; employee editing locked per matrix below. |
| `approved` | Worked hours are payroll-eligible; **approved** overtime visibility applies. |

**Return for correction** (historically “reject” / **send-back**): **not** a steady persisted status. The sheet moves **`submitted` → `draft`** so the employee can correct and resubmit. Intent is captured only on append-only **`WeeklyTimesheetApprovalEvent`** rows (`sent_back`, `returned_for_correction`, …) including optional `metadata` (e.g. reason).

##### Reopen posture

**Reopen** is **`approved` → `draft`**, audited (`event_type`: **`reopened`**). Snapshot columns **`approved_at`** / **`approved_by_id`** are cleared. Until the sheet is **submitted and approved again**, downstream payroll preparation **must not** treat prior approval timestamps as authoritative — reopened sheets are excluded from approved aggregates.

**Send-back from `submitted`:** **`submitted` → `draft`** (same persisted outcome as return-for-correction); distinct from reopen, which originates from **`approved`**.

---

### Locking and editability (MVP default matrix)

Rules apply to daily hour rows associated with the timesheet workweek.

| Timesheet status | Employee | Direct supervisor | Payroll / admin |
| --- | --- | --- | --- |
| `draft` | Edit hours | Edit hours | Edit hours |
| `submitted` | Locked | Edit hours; may **send back to draft**, or approve per policy | Edit / override per capability |
| `approved` | Locked | No silent edits; changes require **reopen** workflow (→ `draft`) | Override / reopen per capability |

---

### Submitted-state supervisor edits

Supervisor edits during:

```text
submitted
```

do not automatically revert workflow state to:

```text
draft
```

unless:

- explicitly **returned for correction** / **sent back** to `draft`, **or**
- explicitly transitioned via another TC-24-documented action

This preserves operational review continuity during supervisor correction workflows.

---

### Overtime visibility semantics (normative)

ADR-0002 establishes:

- weekly overtime
- worked-hours-only overtime
- leave excluded from overtime thresholds

This ADR distinguishes projected vs approved overtime visibility.

#### Projected overtime

Projected overtime is visible during:

- `draft`
- `submitted`

timesheet states.

Projected overtime is derived from:

- current recorded worked hours within the workweek

Projected overtime is operational preview data only and is not payroll-eligible.

#### Approved overtime

Approved overtime exists only after:

```text
approved
```

timesheet state.

Approved overtime is derived from:

- approved worked hours for the workweek

Approved overtime becomes payroll-eligible operational overtime for downstream payroll preparation workflows.

**Boundary:** TC-23 **computes and surfaces** approved overtime **only when** the timesheet is in TC-24’s `approved` state (using the same weekly aggregation rules as projected overtime). TC-24 **owns** the approval transition that makes those hours **officially** payroll-eligible; TC-23 does not redefine eligibility rules.

---

### Visibility labeling requirement

TeamCORE surfaces, including Team360 and operational dashboards, should consistently distinguish:

| Label | Meaning |
| --- | --- |
| Projected overtime | Operational preview |
| Approved overtime | Payroll-eligible overtime |

This distinction prevents operational preview totals from being mistaken for payroll-ready values.

---

### Aggregation boundaries

#### TC-23 operational aggregation question

> How many regular vs overtime worked hours does this employee currently have for this workweek?

TC-23 owns:

- workweek-scoped operational aggregation
- projected overtime visibility
- approved overtime **visibility** (once TC-24 has approved the timesheet — see Overtime visibility semantics)
- current operational totals

#### TC-27 payroll-preparation aggregation question

> What pay-period payroll earning rows belong in payroll summaries and payroll exports?

TC-27 owns:

- pay-period payroll summaries
- payroll earning aggregation
- earning-code rollups
- export-ready payroll aggregation

TC-27 consumes:

- approved worked time from TC-24
- pay-period semantics from ADR-0002

---

## Consequences

### Positive

- Clear separation between:

  - capture
  - submission
  - approval
  - payroll preparation

- Single approval surface (timesheet-level only)
- No duplicate approval lifecycle on daily rows
- Clear projected vs approved overtime semantics
- Prevents payroll-export logic from leaking into TC-23
- Preserves ADR-0002 as the operational calendar foundation

### Trade-offs

- Reopen/rejection flows require careful integration testing.
- Supervisor corrections during submitted review require explicit audit visibility.
- Aggregation logic spans TC-23, TC-24, and TC-27 contracts.

---

## Explicitly deferred

The following remain intentionally deferred:

- punch/timeclock systems
- biometric attendance systems
- geofencing/GPS workflows
- scheduling engines
- attendance enforcement
- meal-rule compliance engines
- enterprise labor compliance systems
- multi-level approval hierarchies
- payroll tax processing
- payroll reconciliation engines

---

## References

- [ADR-0002 — Payroll period and workweek foundations](./adr-0002-payroll-period-and-workweek-foundations)
- [Phase 5 workflows — employee time and payroll](../roadmap/phase-5-payroll-time-leave/phase-5--workflows.md)
- [TC-23a downstream dependency contracts](../roadmap/phase-5-payroll-time-leave/phase-5-tc-23-a-downstream-dependency-contracts.md)
- Epic TC-23 — Employee Time Tracking MVP
- Epic TC-24 — Employee Timesheet Approval
- Epic TC-27 — Payroll Input Workflow
