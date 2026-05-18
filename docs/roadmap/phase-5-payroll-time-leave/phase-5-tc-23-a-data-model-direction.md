# TC-23a — Data Model Direction

## Design posture

TC-23a establishes lightweight operational payroll-period foundations.

**Normative companion:** [ADR-0002 — Payroll period and workweek foundations](../../adr/adr-0002-payroll-period-and-workweek-foundations).

Downstream time modeling assumes **daily worked-hour totals** as the canonical payroll-oriented source and **weekly timesheets** that aggregate those entries within each **workweek**. **Punch/timeclock persistence** is **not** MVP scope for TC-23a; see Explicit non-goals.

The model should remain:

- operational
- employee-focused
- workflow-oriented
- lightweight for MVP

The model should not evolve into:
- payroll accounting
- payroll ledgering
- payroll tax processing
- financial close infrastructure

---

# Core models

## Agency payroll configuration

Potential ownership:
- `Agency`
- `AgencyPayrollConfiguration`
- similar lightweight config model

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `payroll_frequency` | weekly/biweekly/semimonthly/monthly (**one frequency per agency** in MVP) |
| `workweek_starts_on` | weekday |
| `payroll_timezone` | agency timezone (single timezone per agency in MVP) |
| `weekly_overtime_threshold_hours` | default 40 |
| `pay_schedule_anchor_on` | Anchor date for weekly/biweekly/monthly boundaries (required except semimonthly fixed halves) |

---

## PayPeriod

### Purpose

Operational payroll-period record.

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `agency_id` | Ownership |
| `start_on` | Period start |
| `end_on` | Period end |
| `status` | open/closed |
| `payroll_frequency` | Snapshot of config |
| `closed_at` | Closure timestamp |
| `closed_by_id` | Closing actor |

**Constraints (MVP):** pay periods **must not overlap** (by date range) within the same agency.

---

## PayrollExport

### Purpose

Historical payroll export artifact tracking.

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `pay_period_id` | Associated period |
| `export_sequence` | Monotonic sequence # per pay period (draft vs final ordering) |
| `exported_at` | Export timestamp |
| `exported_by_id` | Export actor |
| `is_final` | Final export indicator |
| `file_format` | CSV/XLSX |
| `storage_reference` | Optional file/storage pointer when TC-20 wires artifacts |
| `notes` | Optional operational notes |

---

## PayrollEarningCode (foundation catalog)

### Purpose

Fixed **system** earning codes and categories (e.g. worked regular, worked overtime, payable leave) shared by summaries and exports. **No** agency-configurable earning-code engines in MVP.

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `code` | Stable code (`REG`, `OT`, `PTO`, …) |
| `category` | Semantics for OT vs payable leave rollup |
| `name` | Display label |
| `position` | Ordering |

---

# Workweek posture

## Recommendation

Do not persist workweeks initially.

Instead:
- derive workweeks from:
  - agency workweek start day
  - payroll timezone
  - calendar dates

**Employee time:** MVP payroll-oriented worked time flows from **daily hour totals** into **weekly timesheets** (downstream tables). TC-23a does **not** add punch/timeclock tables.

This keeps MVP lightweight while supporting overtime.

---

# Overtime posture

## Recommendation

Overtime should initially be:
- operationally derived
- approval-aware
- dynamically aggregated

Later phases may materialize summaries if necessary.

---

# Payroll summary posture

## Recommendation

Payroll summaries should initially be:
- computed from approved operational records (**approved daily worked-hour totals** and approved leave, aggregated through **weekly timesheets** where applicable)
- export-ready
- period-aware
- mappable to fixed **PayrollEarningCode** rows for code-oriented exports

Future materialization/snapshotting may occur later if performance or audit needs increase.

---

# Relationships

## Conceptual relationships

```text
Agency
  └── Payroll Configuration
  └── Pay Periods
        └── Payroll Exports

Pay Period
  └── Employee payroll summaries (derived initially)
  └── Approved daily worked-hour totals (via downstream time + weekly timesheets)
  └── Approved leave

PayrollEarningCode (global catalog, not agency-scoped)
```

---

# Explicit non-goals

Avoid introducing:

- PayrollRun
- PayrollBatch
- PayrollLedger
- PayrollPosting
- Workweek persistence
- **Punch/timeclock/biometric/geo attendance persistence as the canonical payroll time source in MVP** (may be added later only if subordinate to daily worked-hour totals — ADR‑0002)
- Financial accounting semantics

during MVP unless operational requirements materially change.


---

# Acceptance Criteria

```markdown id="n1o52v"
# TC-23a — Acceptance Criteria

## Payroll configuration

- Agencies can configure:
  - payroll frequency (**one frequency per agency** in MVP)
  - workweek start day
  - payroll timezone
  - weekly overtime threshold
  - pay-schedule anchor date for weekly/biweekly/monthly (not required for semimonthly fixed halves)

---

## Pay-period generation

- Pay periods are automatically generated.
- Pay periods **do not overlap** within an agency.
- Supported frequencies:
  - weekly
  - biweekly
  - semimonthly
  - monthly
- Semimonthly periods use:
  - 1st–15th
  - 16th–end of month

---

## Pay-period lifecycle

- Pay periods support:
  - `open`
  - `closed`
- Open periods remain operationally editable for downstream corrections/approvals/recalculation posture.
- Closed periods become immutable by default.

---

## Closure rules

- Period closure blocks when:
  - missing **employee** timesheets exist
  - pending approvals exist
- Administrative override is supported (**validation checks only** — does not bypass authorization or audit expectations; ADR‑0002).
- Closure authority is capability-based.

---

## Earning codes

- Fixed system **PayrollEarningCode** rows exist (e.g. `REG`, `OT`, `PTO`, `HOL`, `SICK`) with categories for summaries/exports.
- Agency-configurable earning-code engines are deferred.

---

## Overtime support

- Weekly overtime is supported.
- Overtime uses worked hours only.
- Leave/PTO does not count toward overtime thresholds.
- Overtime visibility is available continuously during open periods.

---

## Payroll summaries

Payroll summaries support:
- regular hours
- overtime hours
- leave hours
- total paid hours
- alignment with fixed payroll earning codes for export-oriented preparation

---

## Export posture

- Multiple draft exports are allowed while periods remain open (with **export_sequence** per period).
- Finalized exports are retained historically.
- Closed periods associate with a finalized export posture.

---

## Contractor separation

- Employee payroll periods remain separate from contractor settlement workflows.
- Contractor settlement periods are not implemented through TC-23a payroll-period logic.

---

## Reporting readiness

TC-23a provides sufficient foundations for:
- overtime reporting
- missing **employee** timesheet reporting
- approval reporting
- payroll export history
- Team360 payroll visibility
```
