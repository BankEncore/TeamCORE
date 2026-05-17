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
- `ADR-0002: Payroll period and workweek foundations`

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

The canonical payroll-oriented operational source is the employee daily worked-hours entry.

Timeclock punches are supporting operational records only.

Punches may assist:
- operational visibility
- break tracking
- hour derivation

but punches themselves are not the authoritative payroll source.

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

- payroll frequency
- workweek start day
- agency timezone
- overtime threshold

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

- time entry
- corrections
- leave integration
- approvals
- overtime visibility
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

Employees may record:

- daily worked hours
- manual worked hours
- optional timeclock punches
- multiple work segments within a day

Examples:

```text
8.0 worked hours
````

or:

```text
9:00 AM–12:00 PM
1:00 PM–5:00 PM
```

Punches support operational visibility but daily worked-hour entries remain authoritative.

---

## Break posture

MVP supports recording break punches or segmented work periods.

MVP does not implement:

* automatic meal deduction
* labor-rule break enforcement
* automatic unpaid-break calculations
* compliance meal engines

Break handling remains operational and lightweight.

---

## Supervisor-entered time

Supervisors may enter or correct employee time.

Supervisor-entered time is treated as approved by default in MVP.

---

# Timesheet Workflow

## Timesheet cadence

Timesheets may operate on:

* weekly cadence
* pay-period cadence

depending on agency operational posture.

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
Supervisor approves or rejects
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

MVP supports:

* full-day leave
* partial-day leave
* hourly leave tracking

Canonical leave storage is hours-based.

---

## Leave approval flow

Typical workflow:

```text
Employee submits leave request
↓
Supervisor/admin approval
↓
Approved leave contributes payable payroll entries
```

---

## Leave and overtime

Approved leave:

* contributes to payable payroll totals
* does NOT contribute toward overtime thresholds

Examples:

| Type          | Counts toward OT? | Counts toward payroll totals? |
| ------------- | ----------------- | ----------------------------- |
| Worked hours  | Yes               | Yes                           |
| PTO           | No                | Yes                           |
| Holiday leave | No                | Yes                           |
| Sick leave    | No                | Yes                           |

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

* missing timesheets exist
* pending approvals exist

Administrative override is allowed.

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
* attendance enforcement
* scheduling engines
* meal-rule compliance engines
* advanced overtime engines
* payroll groups
* multi-timezone workforce handling
* accrual engines
* contractor time workflows
* complex retro-pay systems
