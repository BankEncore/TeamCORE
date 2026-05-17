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

## TC-24 should not redefine:

- payroll closure semantics
- workweek boundaries

---

# TC-25 — Employee Leave Request MVP

## TC-25 depends on TC-23a for:

- Payroll-period association
- Leave-hour aggregation windows
- Agency timezone posture

## TC-25 should not redefine:

- overtime semantics
- payroll-period structure

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