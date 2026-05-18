# TC-23a — Downstream Dependency Contracts

## Purpose

Define the operational contracts TC-23a provides to downstream Phase 5 epics.

**Normative posture:** [ADR-0002 — Payroll period and workweek foundations](../../adr/adr-0002-payroll-period-and-workweek-foundations). MVP employee payroll time is **daily-hours-based** (canonical **daily worked-hour totals**); **weekly timesheets** aggregate those entries within each **workweek**. **Punch/timeclock** capture is **not** MVP and must not become authoritative over daily totals if introduced later.

---

# TC-23 — Employee Time Tracking MVP

## TC-23 depends on TC-23a for:

- Workweek definitions
- Agency timezone posture
- Overtime aggregation boundaries
- Current/open pay-period lookup
- Payroll-period association logic

## TC-23 must (MVP):

- treat **daily worked-hour totals** per calendar day as the **canonical** payroll-oriented worked-time source
- **not** implement punch/timeclock/biometric/geo attendance as payroll-authoritative in MVP

## TC-23 should not redefine:

- payroll frequencies
- overtime thresholds
- workweek semantics

---

# TC-24 — Employee Timesheet Approval

## TC-24 depends on TC-23a for:

- Open/closed pay-period semantics
- Approval completeness checks
- Overtime visibility windows
- Current payroll-period resolution

## TC-24 must (MVP):

- standardize on **weekly** timesheets (one **workweek** per timesheet) that **aggregate daily worked-hour entries**
- persist **three** workflow statuses only on **`WeeklyTimesheet`**: **`draft`**, **`submitted`**, **`approved`**; **return-for-correction** is **`submitted` → `draft`** plus append-only **`WeeklyTimesheetApprovalEvent`** rows (not a long-lived rejected status)
- enforce pay-period closure completeness: each **intersecting workweek** needs an **`approved`** timesheet for active employee engagements (see **`Payroll::ClosureValidators::MissingTimesheets`**), while **`PendingApprovals`** continues to surface **`submitted`** backlog counts
- expose supervisor / payroll review queues with operational aging where implemented

## TC-24 should not redefine:

- pay-period / workweek calendar definitions (**ADR‑0002**)
- daily worked-hour persistence (**TC‑23**)

---

# TC-25 — Employee Leave Request MVP

**Normative posture:** [ADR-0004 — Leave vs time and payroll hooks](../../adr/adr-0004-leave-vs-time-and-payroll-hooks.md).

## TC-25 depends on TC-23a for:

- Civil-date overlap windows against **`PayPeriod#start_on` / `end_on`** for summary inclusion (**no `LeaveRequest` → `PayPeriod` FK**)

## TC-25 must (MVP):

- persist **`LeaveType`**, **`LeaveRequest`**, **`LeaveRequestDay`**, **`LeaveBalance`** (+ **`LeaveBalanceAdjustment`**) for employee engagements only
- keep leave **separate** from **`DailyWorkedHour`** / **`WeeklyTimesheet`**
- use statuses **`draft`**, **`submitted`**, **`approved`**, **`rejected`**, **`cancelled`**, with **`submitted`** as the review-queue label (aligned with timesheets)
- apply balance consume on **`submitted` → `approved`** and restore on **`approved` → `draft`** / **`approved` → `cancelled`** for **balance-tracked paid** types (**ADR‑0004**)
- expose aggregator hooks summing **approved** **`LeaveRequestDay`** rows overlapping the pay period into paid vs unpaid and **`hours_by_earning_code`** where **`LeaveType`** maps to **`PayrollEarningCode`**

## TC-25 should not redefine:

- overtime semantics (**worked hours only**)
- pay-period / workweek calendar definitions (**ADR‑0002**)

---

# TC-26 — Leave Approval by Type

## TC-26 depends on TC-23a for:

- Leave contribution to payroll summaries
- Open-period behavior
- Payroll visibility windows
- Fixed **PayrollEarningCode** mapping for payable leave categories (e.g. `PTO`, `HOL`, `SICK`)

## TC-26 should not redefine:

- payable-hour summary structure

---

# TC-27 — Payroll Input Workflow

## TC-27 depends heavily on TC-23a for:

- Payroll-period lifecycle
- Payroll summary aggregation
- Worked-hour vs leave-hour distinction
- Overtime aggregation
- Closure validation posture (**override applies to validation checks only** — ADR‑0002)
- Finalized-period semantics

## TC-27 should not redefine:

- payroll periods
- workweeks
- overtime thresholds
- payroll lifecycle semantics

---

# TC-20 — Payroll and Settlement Export

## TC-20 depends on TC-23a for:

- Exportable payroll periods
- Finalized export posture
- Historical export linkage (including **export_sequence** / draft vs final posture)
- Payroll summary structures
- Fixed **PayrollEarningCode** vocabulary for code-oriented exports

## TC-20 should not redefine:

- pay-period closure
- payroll completeness rules

---

# TC-21 — Payroll and Settlement Import

## TC-21 depends on TC-23a for:

- Pay-period references
- Finalized export identity
- Payroll-period visibility

## TC-21 should not redefine:

- payroll period generation
- payroll lifecycle semantics

---

# TC-22 — Manual Payroll / Settlement Result Entry

## TC-22 depends on TC-23a for:

- Payroll-period references
- Payroll summary structures
- Finalized payroll-period posture

## TC-22 should not redefine:

- pay-period lifecycle
- overtime calculations
- workweek semantics