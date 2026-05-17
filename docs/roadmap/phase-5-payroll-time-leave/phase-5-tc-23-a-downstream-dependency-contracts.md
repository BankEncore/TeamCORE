# TC-23a — Downstream Dependency Contracts

## Purpose

Define the operational contracts TC-23a provides to downstream Phase 5 epics.

---

# TC-23 — Employee Time Tracking MVP

## TC-23 depends on TC-23a for:

- Workweek definitions
- Agency timezone posture
- Overtime aggregation boundaries
- Current/open pay-period lookup
- Payroll-period association logic

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

## TC-26 should not redefine:

- payable-hour summary structure

---

# TC-27 — Payroll Input Workflow

## TC-27 depends heavily on TC-23a for:

- Payroll-period lifecycle
- Payroll summary aggregation
- Worked-hour vs leave-hour distinction
- Overtime aggregation
- Closure validation posture
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
- Historical export linkage
- Payroll summary structures

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