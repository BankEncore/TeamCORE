# TC-23a — Data Model Direction

## Design posture

TC-23a establishes lightweight operational payroll-period foundations.

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
| `payroll_frequency` | weekly/biweekly/semimonthly/monthly |
| `workweek_starts_on` | weekday |
| `payroll_timezone` | agency timezone |
| `weekly_overtime_threshold_hours` | default 40 |

---

## PayPeriod

### Purpose

Operational payroll-period record.

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `agency_id` | Ownership |
| `starts_on` | Period start |
| `ends_on` | Period end |
| `status` | open/closed |
| `payroll_frequency` | Snapshot of config |
| `closed_at` | Closure timestamp |
| `closed_by_id` | Closing actor |
| `override_closed` | Optional future posture |

---

## PayrollExport

### Purpose

Historical payroll export artifact tracking.

### Suggested attributes

| Attribute | Purpose |
| --- | --- |
| `pay_period_id` | Associated period |
| `exported_at` | Export timestamp |
| `exported_by_id` | Export actor |
| `is_final` | Final export indicator |
| `file_format` | CSV/XLSX |
| `notes` | Optional operational notes |

---

# Workweek posture

## Recommendation

Do not persist workweeks initially.

Instead:
- derive workweeks from:
  - agency workweek start day
  - timezone
  - calendar dates

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
- computed from approved operational records
- export-ready
- period-aware

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
  └── Approved time
  └── Approved leave
  ```

# Explicit non-goals

Avoid introducing:

- PayrollRun
- PayrollBatch
- PayrollLedger
- PayrollPosting
- Workweek persistence
- Financial accounting semantics

during MVP unless operational requirements materially change.


---

# Acceptance Criteria

```markdown id="n1o52v"
# TC-23a — Acceptance Criteria

## Payroll configuration

- Agencies can configure:
  - payroll frequency
  - workweek start day
  - payroll timezone
  - weekly overtime threshold

---

## Pay-period generation

- Pay periods are automatically generated.
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
- Open periods remain editable.
- Closed periods become immutable by default.

---

## Closure rules

- Period closure blocks when:
  - missing timesheets exist
  - pending approvals exist
- Administrative override is supported.
- Closure authority is capability-based.

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

---

## Export posture

- Multiple draft exports are allowed while periods remain open.
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
- missing-timesheet reporting
- approval reporting
- payroll export history
- Team360 payroll visibility