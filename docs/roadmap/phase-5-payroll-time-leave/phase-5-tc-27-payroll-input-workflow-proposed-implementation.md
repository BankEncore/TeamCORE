# Proposed Implementation — Payroll Input Workflow (TC-27)

## Status

Proposed implementation planning document

---

# Purpose

Define the proposed operational architecture for payroll input assembly workflows introduced in TC-27.

This document expands the TC-27 epic definition into a developer-oriented implementation proposal covering:

* payroll batch lifecycle
* payroll assembly semantics
* payroll input row structure
* snapshot/recalculation behavior
* earning and adjustment code posture
* export interaction boundaries
* operational review posture
* upstream workflow contracts

This document is implementation guidance and does not replace ADRs.

---

# Architectural Role

TC-27 establishes the operational payroll-preparation layer between:

| Upstream Operational Workflows | Downstream Payroll Processing |
| ------------------------------ | ----------------------------- |
| approved worked time           | payroll export/import         |
| approved overtime              | external payroll processor    |
| approved leave                 | payroll execution             |
| commission/draw visibility     | paycheck generation           |
| manual payroll adjustments     | payroll tax processing        |

TC-27 is:

* an operational payroll assembly workflow
* a payroll-preparation visibility layer
* a payroll review surface
* a payroll export staging layer

TC-27 is not:

* a payroll engine
* a payroll accounting engine
* a tax calculation engine
* a payment processing engine

---

# Core Concepts

## PayrollInputBatch

Represents a payroll-preparation assembly snapshot for a payroll period.

The batch becomes the operational review and export source for payroll-preparation workflows.

---

## PayrollInputRow

Represents an assembled payroll-preparation row derived from approved operational workforce records.

Examples:

| Employee | Code       | Quantity | Amount  |
| -------- | ---------- | -------- | ------- |
| Jane     | REG        | 80       |         |
| Jane     | OT         | 6        |         |
| Jane     | PTO        | 8        |         |
| Jane     | COMMISSION |          | 2400.00 |
| Jane     | DRAW       |          | -500.00 |

Rows are payroll-preparation records only.

Rows do not represent:

* accounting entries
* paycheck lines
* tax calculations
* payment execution

---

# Batch Lifecycle

## Batch statuses

| Status      | Meaning                                                                |
| ----------- | ---------------------------------------------------------------------- |
| `draft`     | Recalculable payroll preview                                           |
| `finalized` | Frozen payroll-preparation snapshot                                    |
| `exported`  | Immutable payroll artifact associated with external payroll processing |
| `reversed`  | Former finalized batch undone before export; immutable; superseded by a new batch |

### Batch identity and lineage

A pay period may have **one active draft** payroll input batch at a time. Draft batches may be **recalculated in place**. Once **finalized**, a batch must **not** be mutated. If changes are needed before export, the finalized batch is **reversed** and a **new** batch is generated with lineage to the prior batch (`supersedes_batch_id` / `superseded_by_batch_id`, `reference_sequence`, reversal stamps).

---

## Draft batches

Draft batches are ephemeral operational preview artifacts.

Draft batches:

* may be regenerated repeatedly
* may reflect changing upstream approvals
* are not immutable
* are not payroll-final

Draft batches support:

* operational payroll review
* draft exports
* payroll validation/review cycles

Draft batches may be deleted or regenerated freely.

---

## Finalized batches

Finalized batches represent frozen payroll-preparation snapshots.

Finalized batches:

* preserve payroll review state
* are not silently editable
* may not be recalculated directly
* may be reversed before export

Finalized batches remain operationally separate from pay-period close.

---

## Exported batches

Exported batches are immutable payroll-preparation artifacts.

Exported batches:

* may not be edited
* may not be regenerated in place
* represent operational handoff to external payroll workflows

Exported batches trigger pay-period close in MVP operational posture.

Corrections after export require future adjustment/reversal workflows rather than mutation of exported batches.

### Final export and pay-period closure

Final payroll export closes the pay period through **`Payroll::PayPeriodClosureService.call(...)`** (not by mutating `pay_period.status` directly). Closure validators remain authoritative. Payroll closure may use an explicit authorized **`override_validation`** with a **required `override_reason`**; override bypasses validation only and does not bypass authorization or audit expectations.

Closure events are recorded as **pay-period lifecycle** rows (`pay_period_closure_events`). When closure is triggered from TC-27, the closure event may reference the payroll input batch / export that initiated it (`payroll_input_batch_id`), but the **authoritative closure audit trail belongs to the pay period**.

---

# Batch Transitions

## Allowed transitions

| From      | To               | Notes                                              |
| --------- | ---------------- | -------------------------------------------------- |
| draft     | finalized        | Freeze snapshot                                    |
| finalized | reversed         | Explicit reversal (then create new draft superseding) |
| finalized | exported         | Final export workflow + closure via closure service |
| reversed  | —                | Immutable; successor draft/finalized batch is a new row |
| exported  | —                | Immutable                                          |

---

## Reversal posture

Reversal applies only to finalized, unexported batches.

Reversal:

* invalidates finalized review posture
* allows regeneration
* preserves audit visibility
* does not mutate historical exported artifacts

Recommended operational pattern:

* append-only batch events
* current-state batch row

---

# Snapshot Semantics

## Point-in-time assembly

PayrollInputBatch captures a point-in-time payroll-preparation snapshot.

Finalized/exported batches must not dynamically recalculate based on later operational changes.

Examples of upstream changes:

* reopened timesheets
* reopened leave requests
* payroll adjustments
* corrected overtime
* commission corrections

Draft batches may reflect these changes.

Finalized/exported batches do not change automatically.

---

# Payroll Assembly Pipeline

## Upstream eligibility contract

Only approved operational workforce records may assemble into payroll input rows.

Examples:

| Source               | Eligibility |
| -------------------- | ----------- |
| approved worked time | included    |
| projected overtime   | excluded    |
| approved overtime    | included    |
| approved leave       | included    |
| pending leave        | excluded    |
| rejected leave       | excluded    |

---

## Assembly sources

### Approved worked time

Produces:

* REG
* OT

rows.

---

### Approved leave

Produces payroll-visible leave rows.

Examples:

* PTO
* SICK
* HOL
* UNPAID

---

### Commission/draw visibility

TC-27 may assemble:

* commission activity
* draw activity
* draw recovery activity

where operationally approved/eligible.

---

### Manual adjustments

Manual payroll adjustments may contribute rows.

Examples:

* bonus
* reimbursement
* misc pay
* manual deduction
* payroll correction

---

# PayrollInputBatch Model (Proposed)

## Suggested fields

| Field              | Purpose                     |
| ------------------ | --------------------------- |
| agency_id          | owning agency               |
| payroll_period_id  | payroll period              |
| status             | draft/finalized/exported    |
| reference_number   | operational identity        |
| generated_at       | initial generation          |
| finalized_at       | optional                    |
| exported_at        | optional                    |
| source_snapshot_at | assembly timestamp          |
| exported_reference | optional external reference |

---

# PayrollInputRow Model (Proposed)

## Suggested fields

| Field                  | Purpose                          |
| ---------------------- | -------------------------------- |
| payroll_input_batch_id | parent batch                     |
| engagement_id          | employee engagement              |
| payroll_code           | earning/adjustment code          |
| quantity               | hours/units                      |
| amount                 | money value                      |
| source_type            | work/leave/commission/adjustment |
| source_reference_type  | polymorphic source type          |
| source_reference_id    | upstream linkage                 |
| notes                  | optional operational notes       |

---

# Payroll Code Posture

## System-defined payroll codes

System-defined payroll codes remain authoritative for core payroll-preparation behavior.

Examples:

| Code          | Meaning              |
| ------------- | -------------------- |
| REG           | Regular worked hours |
| OT            | Overtime             |
| PTO           | Paid time off        |
| SICK          | Sick leave           |
| HOL           | Holiday              |
| COMMISSION    | Commission           |
| DRAW          | Draw                 |
| DRAW_RECOVERY | Draw recovery        |

Agencies may not redefine system-defined codes in MVP.

---

## Agency-defined adjustment codes

Agencies may define adjustment codes for operational payroll-preparation purposes.

Examples:

* BONUS
* REIMBURSEMENT
* MISC_PAY
* MANUAL_DEDUCTION
* CORRECTION

Agency-defined codes supplement, but do not replace, system-defined payroll codes.

---

# Payroll Visibility Semantics

Payroll-visible operational records indicate payroll-preparation eligibility only.

Payroll-visible does not imply:

* payroll execution
* payroll transmission
* payroll taxation
* paycheck generation
* payment issuance
* payroll reconciliation
* accounting completion

---

# Operational Review Workflow

## Payroll review posture

Payroll input batches support operational payroll review prior to export generation.

Examples:

* missing approvals
* overtime review
* leave review
* commission visibility
* draw visibility
* adjustment review
* payroll-ready eligibility visibility

---

## Review expectations

Operational users should be able to:

* regenerate draft batches
* review finalized batches
* identify missing approvals
* identify upstream corrections
* review payroll summaries before export

---

# Export Interaction Contract

TC-27 does not generate export files.

Exports belong to:

* TC-20 (CSV/XLSX export)

However, TC-27 defines the operational source material for exports.

---

## Draft export posture

Draft exports:

* may be generated repeatedly
* do not close the payroll period
* remain operational preview artifacts

---

## Final export posture

Final export:

* exports a finalized batch
* freezes payroll-preparation posture
* closes the payroll period in MVP operational posture

---

# Team360 and Reporting Hooks

TC-27 provides read models and operational visibility hooks for:

* payroll summaries
* payroll visibility
* overtime visibility
* leave visibility
* payroll adjustment visibility
* commission/draw visibility

Team360 should consume these read models rather than duplicate payroll assembly logic.

---

# Upstream Contracts

## TC-23 / TC-24

Provide:

* approved worked time
* approved overtime

---

## TC-25 / TC-26

Provide:

* approved leave
* leave approval posture

---

## TC-23a

Provides:

* payroll periods
* workweeks
* operational calendar semantics

---

# Explicit Deferrals

The following remain intentionally deferred:

* payroll tax calculation
* paycheck generation
* direct deposit/ACH
* payroll accounting/GL posting
* payroll balancing/reconciliation
* contractor settlement payroll integration
* retro payroll correction engine
* wage garnishments
* accrual accounting
* statutory payroll compliance
* multi-payroll-group architecture
* multi-state payroll complexity

---

# Open Questions

## Future considerations

The following remain intentionally unresolved pending later payroll phases:

* retroactive payroll correction handling
* reversal workflows after export (post-export corrections)
* multi-payroll schedules
* payroll accounting integration
* payroll reconciliation workflows
* contractor settlement convergence
* external payroll processor acknowledgment tracking

---

# References

* ADR-0002 — Payroll period and workweek foundations
* ADR-0003 — Employee time capture and timesheet approval boundaries
* ADR-0004 — Employee leave boundaries vs time tracking and payroll preparation
* ADR-0005 — System actors in workflow audit events (audit/event recording posture)
* TC-23a — Work Calendar / Pay Period Foundation
* TC-23 — Employee Time Tracking MVP
* TC-24 — Employee Timesheet Approval
* TC-25 — Employee Leave Requests and Tracking
* TC-26 — Leave Approval by Type (approval policy and operational approval posture)
* TC-20 — Payroll and Settlement CSV/XLSX Export
* TC-21 — Payroll and Settlement CSV/XLSX Import
* TC-22 — Manual Payroll / Settlement Result Entry
