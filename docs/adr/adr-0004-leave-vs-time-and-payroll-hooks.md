# ADR-0004: Employee leave boundaries vs time tracking and payroll preparation

## Status

Accepted

---

## Context

Employee leave (requests, approvals, balances, calendar-day allocation) must coexist with daily worked hours and weekly timesheet approval without collapsing distinct operational concerns. Phase 5 already separates **worked time capture** from **timesheet approval** ([ADR-0003](./adr-0003-employee-time-and-timesheet-approval-boundaries.md)). Leave adds a third strand: **operational absence tracking** that payroll preparation may **correlate** with worked time later, but must not silently merge into timesheet rows or payroll calculation engines in MVP.

Without explicit boundaries:

- Leave hours get written into worked-time tables “for convenience.”
- Approved leave is mistaken for payable payroll output.
- Balance tables acquire liability-accounting semantics prematurely.
- Pay-period closure or overtime logic absorbs leave incorrectly.

TC-26 does not replace the TC-25 leave-request service façade. TC-26 defines the approval-policy contract consumed by TC-25 leave workflows: who may approve, which leave types auto-approve, how approval authority is interpreted, and which rules must be enforced before leave becomes approved operational leave.

---

## Decision

### 1. Leave does not mutate worked time

Leave requests and leave day rows **never** create, update, or delete [`DailyWorkedHour`](../../app/models/daily_worked_hour.rb) or [`WeeklyTimesheet`](../../app/models/weekly_timesheet.rb).

Worked time remains the responsibility of time-tracking flows; leave remains absence tracking. Downstream payroll preparation may interpret both; TeamCORE MVP does not fuse them at persistence.

### 2. Canonical allocation is calendar-day based

Operational leave quantity is stored on **`LeaveRequestDay`**: one row per **`leave_date`** with **`hours`**. The parent **`LeaveRequest`** is the workflow container (status, review snapshot, audit events).

**`start_on` / `end_on`** on the request are derived from the min/max of child days for listing and UX consistency.

Pay-period visibility sums **only days whose `leave_date` falls inside the pay period’s inclusive civil-date range** for **`approved`** requests. No fractional proration of a single lump sum across period boundaries.

### 3. Workflow statuses (Phase 5 vocabulary)

Persisted statuses on **`LeaveRequest`**: **`draft`**, **`submitted`**, **`approved`**, **`rejected`**, **`cancelled`**.

Use **`submitted`** for the supervisor queue state (aligned with weekly timesheet language).

**Reopen:** **`approved` → `draft`** restores prior consumption semantics (see balances), clears review snapshot, clears **`submitted_at`**; the employee or admin must submit again for review.

### 4. Cancellation

**Allowed:** **`draft` → `cancelled`**, **`submitted` → `cancelled`**, **`approved` → `cancelled`** (agency policy may later restrict approved cancellations).

**Not allowed:** **`rejected` → `cancelled`** — **`rejected`** is terminal.

### 5. Balances are informational and auditable only

**`LeaveBalance`** holds a snapshot **`balance_hours`** per engagement + balance-tracked **`LeaveType`**. **`LeaveBalanceAdjustment`** records manual deltas with reason and actor.

Balances are **not** liability-grade ledgers. MVP does **not** automate accrual, carryover, or statutory entitlement.

### 6. Balance consumption on approval (idempotent)

- **Consume** **`sum(LeaveRequestDay.hours)`** exactly once when transitioning **`submitted` → `approved`**, inside the same transaction as the status change and audit event, **only if** the **`LeaveType`** is **`balance_tracked`** and **`paid`** (unpaid / non-tracked types skip balance mutation).

- **Restore** the same amount exactly once when a transition reverses an approval that consumed balance: **`approved` → `draft`** (reopen) or **`approved` → `cancelled`**. **`submitted` → `rejected`** never consumes balance, so **no restore on reject**.

Implementations must enforce **at-most-once** consume/restore by guarding on **current status** before applying deltas (no duplicate transitions).

Default MVP rule: **block approval** if **`balance_tracked`** + **`paid`** and **`balance_hours < requested hours`**. Optional negative-balance policy is deferred unless product enables it per agency/type.

### 7. Payroll preparation is visibility-only

Approved leave contributes **read-model aggregates** for payroll preparation (e.g. paid vs unpaid hours by calendar day overlap with a pay period, optional rollup into global earning-code buckets where **`LeaveType`** maps to [`PayrollEarningCode`](../../app/models/payroll_earning_code.rb)).

**Paid/unpaid** on **`LeaveType`** expresses **designation / eligibility posture**, not a promise that an external payroll run will pay those hours without adjustment.

TC-25 does **not** generate paychecks, tax artifacts, or export earning rows.

### 8. Projected vs payroll-visible leave

Mirror the projected vs approved overtime labeling posture:

| Leave request status | Visibility posture |
| --- | --- |
| **`draft`**, **`submitted`**, **`rejected`**, **`cancelled`** | Operational / **projected** preview — not payroll-visible leave totals |
| **`approved`** | **Payroll-visible** absence hours for aggregation surfaces |

Use a small presenter or helper so Team360 and admin queues share labels without duplicating rules.

### 9. Overtime and pay-period closure

- **Weekly overtime** math stays **worked-hours only**; leave hours do **not** count toward overtime thresholds.

- **Pay-period closure** is **not** blocked on pending leave requests in MVP (avoid operational deadlock).

---

## Consequences

### Positive

- Clear isolation: time capture vs timesheet approval vs leave absence vs payroll prep correlation.
- Day-granular leave aligns reporting, partial days, and period overlap without proration hacks.
- Balance mutations stay tied to explicit workflow transitions and audit events.

### Trade-offs

- More rows than a single “total hours” field (`LeaveRequestDay` per date).
- Payroll consumers must document how **`total_paid_hours`** (worked) relates to **`paid_leave_hours`** until TC-27 formalizes combined summaries.

---

## References

- [ADR-0002 — Payroll period and workweek foundations](./adr-0002-payroll-period-and-workweek-foundations)
- [ADR-0003 — Employee time capture and timesheet approval boundaries](./adr-0003-employee-time-and-timesheet-approval-boundaries.md)
- [ADR-0005 — System actors in workflow audit events](./adr-0005-system-actors-in-workflow-audit-events.md)
- [Phase 5 workflows — leave](../roadmap/phase-5-payroll-time-leave/phase-5--workflows.md)
- [Phase 5 downstream dependency contracts](../roadmap/phase-5-payroll-time-leave/phase-5-tc-23-a-downstream-dependency-contracts.md)
