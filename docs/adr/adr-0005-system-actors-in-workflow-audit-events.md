# ADR-0005: System actors in workflow audit events

## Status

Accepted

---

## Context

TeamCORE records workflow transitions using **append-only audit rows** tied to domain aggregates (for example [`WeeklyTimesheetApprovalEvent`](../../app/models/weekly_timesheet_approval_event.rb), [`LeaveRequestApprovalEvent`](../../app/models/leave_request_approval_event.rb)). Those rows historically assume a **human** actor (`User`) where accountability matters.

Product flows increasingly need **policy- or system-driven** transitions that are still **operationally auditable** without implying a specific person clicked “Approve”—for example:

- leave types configured for **auto-approval** after submit ([Phase 5 — Leave Approval by Type](../roadmap/phase-5-payroll-time-leave/phase-5-tc-26-leave-approval-by-type-draft-plan.md))
- future batch reconciliation, imports, or scheduled jobs that advance workflows under explicit rules

Without an explicit convention:

- teams invent **fake “system” `User` rows** (lifecycle and permission ambiguity),
- or they **reuse arbitrary admins** as proxies (misleading audit),
- or they **skip audit rows** for non-human transitions (invisible lineage).

This ADR defines how **non-human** approval-like transitions appear in **workflow audit events** across TeamCORE.

---

## Decision

### 1. Prefer nullable actor FK plus structured metadata

For workflow audit events that reference an **`actor`** (`User`):

- **`actor_id` MAY be `NULL`** when the transition was initiated by **system/policy automation**, not an interactive human decision on behalf of that user record.
- The event **`metadata`** (JSON) **SHOULD** record machine-readable lineage, minimally identifying that the actor was **system-driven**.

Recommended convention for policy-driven automation in MVP:

| Metadata key | Purpose |
| --- | --- |
| **`actor_kind`** | `"human"` (default when inferred from present `actor_id`) or **`"system_policy"`** when `actor_id` is absent |

Consumers MAY add optional keys later (`policy_rule`, `job_id`, `correlation_id`) without changing this ADR’s core rule.

### 2. No synthetic `User` for “System” in MVP

TeamCORE **does not** introduce a persisted **`User`** row representing “System”, “Robot”, or “Auto-approve” for MVP workflow audit.

Rationale:

- avoids password resets, agency membership, and authorization edge cases on non-people
- keeps **`users`** reserved for authenticatable identities

If product later requires a dedicated service principal model, that should be a **separate ADR** (not assumed here).

### 3. Human-initiated transitions remain unchanged

When a human approves, rejects, reopens, cancels, or otherwise triggers a recorded workflow transition through the admin or future self-service UI:

- **`actor_id` MUST** reference the accountable **`User`** (subject to existing access rules).
- **`actor_kind`** MAY be omitted or **`human`** for clarity.

### 4. Presentation and queries must tolerate absent actors

Admin surfaces, Team360, exports, and diagnostics **MUST** handle **`actor_id` NULL** without raising:

- display copy such as **“System (policy)”** or **“Automatic approval”** when `actor_kind == system_policy` (or equivalent detection),
- never imply a human reviewer when none exists.

### 5. Scope: workflow audit events, not all logging

This ADR applies to **persisted domain audit rows** attached to workflow aggregates (leave approval events, weekly timesheet approval events, and analogous future append-only transition tables).

It does **not** mandate schema for application logs, metrics, or external observability platforms.

---

## Consequences

### Positive

- Clear audit lineage for **automatic** vs **human** transitions without polluting **`users`**.
- Consistent pattern for **future** policy-driven workflows beyond leave.
- Forces UI and reporting to treat **missing actor** as a first-class case.

### Trade-offs

- **`belongs_to :actor`** models must allow **`optional: true`** where system events are stored (schema + validation updates per table).
- Analytics that assume every approval event joins to **`users`** require **`LEFT JOIN`** or equivalent.

---

## Explicitly deferred

- Dedicated **service principal** or **machine identity** tables
- Cryptographic **non-repudiation** or regulator-grade **immutable ledgers**
- Cross-product **single audit bus** unifying all domains

---

## References

- [ADR-0003 — Employee time capture and timesheet approval boundaries](./adr-0003-employee-time-and-timesheet-approval-boundaries.md)
- [ADR-0004 — Employee leave boundaries vs time tracking and payroll preparation](./adr-0004-leave-vs-time-and-payroll-hooks.md)
- [Leave Approval by Type — implementation plan](../roadmap/phase-5-payroll-time-leave/phase-5-tc-26-leave-approval-by-type-draft-plan.md)
