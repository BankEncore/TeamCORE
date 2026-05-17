# Phase 5 — Employee Time, Leave, and Payroll Workflows

## Purpose

This document describes the operational workflow posture for TeamCORE Phase 5.

Phase 5 introduces:

- employee time tracking
- timesheet approval
- leave workflows
- overtime aggregation
- payroll preparation workflows
- payroll export/import workflows
- payroll operational reporting

This document is intentionally workflow-oriented rather than implementation-oriented. It exists to provide operational clarity and shared understanding across:

- product planning
- UX
- engineering
- reporting
- payroll export design
- Team360 integration

Companion references:

- `mvp-scope.md`
- `overview.md`
- `employee-contractor-applicability-matrix.md`
- `ADR-0002: Payroll period and workweek foundations` ([adr-0002-payroll-period-and-workweek-foundations](../../adr/adr-0002-payroll-period-and-workweek-foundations))
- `ADR-0003: Employee time capture and timesheet approval boundaries (TC-23 / TC-24)` ([adr-0003-employee-time-and-timesheet-approval-boundaries.md](../../adr/adr-0003-employee-time-and-timesheet-approval-boundaries.md))

**Alignment:** MVP employee time is **daily-hours-based** only (canonical daily worked-hours entries). **Timeclock/punch capture** and related attendance enforcement are **out of MVP** and listed under deferrals; see ADR‑0002 revision note. **Submission vs timesheet approval ownership**, **locking norms**, and **projected vs approved overtime** are normative in **ADR‑0003**.

---

# Core Operational Principles

## TeamCORE is not a payroll processing engine

TeamCORE prepares, organizes, exports, imports, and summarizes payroll-related workforce data.

External payroll providers remain authoritative for:

- payroll execution
- tax calculations
- tax filings
- direct deposit
- payroll compliance processing

---

## Employee payroll and contractor settlement remain separate

Employee payroll workflows and contractor settlement workflows are intentionally distinct operational rails.

Phase 5 payroll workflows apply to employees only.

Contractor settlement cycles are handled separately and are not implemented through employee payroll-period workflows.

---

## Daily worked-hour entries are authoritative

The canonical payroll-oriented operational source is the employee **daily worked-hours entry** (total worked hours per calendar day in the agency payroll timezone).

**Removed from MVP:** timeclock punch streams, punch-derived hour derivation, biometric clocks, geofencing/GPS attendance, and attendance-enforcement engines. Those capabilities are **deferred** so later punch/timeclock features can be added **without redesigning** pay-period or workweek foundations (ADR‑0002).

---

## Workweeks and pay periods are distinct

### Workweeks

Workweeks are used for:
- overtime calculation
- weekly timesheets
- operational aggregation

### Pay periods

Pay periods are used for:
- payroll preparation
- payroll summaries
- payroll exports
- reporting
- Team360 payroll visibility

This distinction is important because payroll periods may span multiple workweeks.

---

# Payroll Calendar and Pay Periods

## Agency payroll configuration

MVP agencies configure:

- payroll frequency (**one frequency per agency**)
- workweek start day
- agency timezone
- overtime threshold

Pay periods **must not overlap** within an agency (boundaries come from generation and agency settings).

Supported payroll frequencies:

- weekly
- biweekly
- semimonthly
- monthly

Semimonthly periods use fixed halves:

| Period | Dates |
| --- | --- |
| First | 1st–15th |
| Second | 16th–end of month |

---

## Pay-period lifecycle

MVP pay periods use a lightweight lifecycle:

| Status | Meaning |
| --- | --- |
| `open` | Editable operational payroll period |
| `closed` | Finalized payroll-processing-complete period |

---

## Open pay periods

Open periods allow:

- time entry (daily worked hours)
- corrections
- leave integration
- approvals
- overtime visibility and ongoing aggregation
- payroll-summary recalculation
- payroll exports
- multiple draft exports

---

## Closed pay periods

Closed periods:

- represent finalized payroll-processing posture
- become immutable by default
- block standard editing

Administrative reopening or override may occur through authorized workflows.

---

# Employee Time Workflow

## Time entry posture

Employees (or supervisors on their behalf) record **daily worked-hour totals** — the canonical unit for payroll-oriented time in MVP.

Examples:

```text
Mon 2025-01-06: 8.0 hours worked
Tue 2025-01-07: 7.5 hours worked
```

Intra-day clock ranges, automatic punch pairing, and segment-level engineering **are not MVP requirements**; any future UI that breaks down a day still **rolls up** to authoritative daily totals for payroll (ADR‑0002).

---

## Break posture

Without punch infrastructure, MVP does **not** model break punches or automated break deductions.

MVP does not implement:

* automatic meal deduction
* labor-rule break enforcement
* automatic unpaid-break calculations
* compliance meal engines

Break handling remains intentionally lightweight (policy and communication outside the system, or simple notes if added later).

---

## Supervisor-entered time

Supervisors may enter or correct employee time.

Supervisor-entered time is treated as approved by default in MVP.

---

# Timesheet Workflow

## Timesheet cadence

MVP **standardizes on weekly timesheets**: each timesheet covers **one workweek** and **aggregates daily worked-hour entries** for that week. Approved weekly timesheets roll into pay-period summaries; a single pay period may span **multiple** workweeks.

**Deferred:** alternate MVP cadences such as pay-period-only timesheets without weekly aggregation, unless product re-opens that decision.

---

## Employee submission flow

Typical workflow:

```text
Employee enters daily worked hours
↓
Timesheet assembled
↓
Employee submits timesheet
↓
Supervisor reviews
↓
Supervisor approves or sends back for correction (returns sheet to draft)
```

---

## Approval posture

MVP approval authority:

* direct supervisor
* payroll/admin override

Future supervisor hierarchy workflows are deferred.

---

## Approved time posture

Approved worked time becomes payroll-eligible operational time.

Approved timesheets become locked to employee editing.

Supervisors/payroll administrators may reopen or adjust approved time if necessary.

---

# Leave Workflow

## Leave posture

Leave applies to employees only in MVP.

**Normative boundaries:** [ADR-0004 — Leave vs time and payroll hooks](../../adr/adr-0004-leave-vs-time-and-payroll-hooks.md).

MVP supports:

* full-day leave
* partial-day leave
* hourly leave tracking

Canonical leave storage is **hours-based**, allocated per calendar date on **`LeaveRequestDay`** rows (workflow container: **`LeaveRequest`**).

---

## Leave approval flow

Typical workflow:

```text
Request drafted with daily hour rows → submitted for review
↓
Supervisor/admin approval or rejection
↓
Approved leave feeds payroll-preparation visibility (summaries / earning-code buckets — not paycheck generation)
```

---

## Leave and overtime

Approved leave:

* surfaces in **payroll-preparation visibility** aggregates for paid vs unpaid designation (**ADR‑0004**)
* does NOT contribute toward **weekly overtime thresholds** (worked hours only)

Examples:

| Type          | Counts toward OT? | Payroll-prep visibility (approved)? |
| ------------- | ----------------- | ----------------------------------- |
| Worked hours  | Yes               | Yes (approved worked time)          |
| PTO           | No                | Yes (paid leave designation)        |
| Holiday leave | No              | Yes (paid leave designation)      |
| Sick leave    | No                | Yes (paid leave designation)      |

---

## Holidays

MVP treats holidays as leave-type payroll contributions.

MVP does not implement:

* holiday-pay engines
* automatic holiday calculations
* jurisdiction-specific holiday rules

---

# Overtime Workflow

## Overtime posture

MVP supports basic weekly overtime.

Overtime is operationally derived from approved worked hours.

---

## Overtime calculation

MVP overtime rules:

* calculated weekly
* based on worked hours only
* excludes leave/PTO
* continuously visible during the pay period

Agency overtime threshold is configurable.

Default:

* 40 hours/week

---

## Future overtime compatibility

The architecture should leave room for future:

* daily overtime
* double-time
* holiday overtime
* jurisdiction-specific labor rules
* employee-class-specific overtime rules

without redesigning foundational models.

---

# Payroll Earning Aggregation

## Payroll-code-oriented posture

Payroll preparation is payroll-code-oriented rather than summary-only.

Examples:

| Code   | Meaning              |
| ------ | -------------------- |
| `REG`  | Regular worked hours |
| `OT`   | Overtime hours       |
| `PTO`  | Paid time off        |
| `HOL`  | Holiday leave        |
| `SICK` | Sick leave           |

MVP earning codes remain system-defined and fixed.

Agency-configurable earning-code engines are deferred.

---

## Payroll summary structure

Payroll summaries may include:

| Field              | Meaning                      |
| ------------------ | ---------------------------- |
| `regular_hours`    | Non-overtime worked hours    |
| `overtime_hours`   | Approved overtime hours      |
| `leave_hours`      | Approved payable leave hours |
| `total_paid_hours` | Total payable payroll hours  |

---

# Payroll Export Workflow

## Payroll export posture

TeamCORE prepares payroll export artifacts for external payroll processors.

Supported export formats:

* CSV
* XLSX

---

## Draft exports

Open payroll periods may generate multiple draft exports.

Examples:

* preliminary payroll review
* payroll verification
* correction review

---

## Final export

When a pay period closes:

* the finalized export becomes authoritative
* the pay period becomes finalized operationally

Exports remain historically visible.

---

# Payroll Correction Workflow

## Open periods

Open periods allow:

* corrections
* edits
* approvals
* recalculation

---

## Closed periods

Closed periods block standard editing.

If corrections are required after closure:

```text
Admin reopens period
↓
Corrections made
↓
Updated export generated
↓
Period closed again
```

MVP intentionally avoids:

* retro-pay engines
* amendment payroll architecture
* payroll adjustment ledgering

---

# Closure Validation Workflow

## Closure requirements

Periods should not close when:

* an **approved** weekly timesheet is missing for any **workweek intersecting** the pay period (per active employee engagement)
* **pending approvals** exist (**submitted** timesheets overlapping the period — operational backlog signal)

Administrative override is allowed.

**Override semantics:** override bypasses **closure validation checks only** (e.g. unapproved / missing approved timesheets / pending approvals). It does **not** bypass authorization to close, audit expectations, or immutability rules for closed periods (ADR‑0002).

**Note:** Early Phase 5 drafts gated closure on **row existence** only; the normative rule is **approved** weekly timesheets for each intersecting workweek so payroll preparation reflects payroll-eligible worked time only.

---

## Closure authority

Pay-period closure is capability/permission-based rather than hardcoded to specific roles.

---

# Reporting and Operational Visibility

Phase 5 workflows support operational visibility for:

* current pay-period status
* employee timesheets
* missing timesheets
* pending approvals
* overtime visibility
* payroll export history
* employee payroll summaries

---

# Team360 Integration

Team360 may surface:

* current pay-period summaries
* overtime visibility
* leave summaries
* payroll export status
* payroll history summaries
* approval status indicators

Team360 remains a read/aggregation surface rather than the source of truth.

---

# Explicit MVP Deferrals

The following are intentionally deferred:

* payroll tax engines
* direct deposit processing
* payroll APIs
* payroll reconciliation engines
* **timeclock punch systems and punch-derived workflows**
* **biometric attendance and attendance-enforcement engines**
* **geofencing, GPS, and location-based time capture**
* scheduling engines
* meal-rule compliance engines
* advanced overtime engines
* payroll groups
* multi-timezone workforce handling
* accrual engines
* contractor time workflows
* complex retro-pay systems
