# Leave Approval by Type — Implementation Plan

## Framing

“TC-26” is only the planning label. Application code and user-facing copy should use domain language such as:

* Leave Approval Policy
* Leave Approval Rules
* Leave Type Approval
* Auto-Approval
* Leave Review

## Purpose

Implement leave-type-specific approval policy for employee leave requests.

This work defines **how leave requests become approved operational leave** while leaving TC-25 as the owner of leave request persistence, balance mutation mechanics, and core workflow transitions.

---

# Scope

## In scope

### Leave type approval policy

Add policy controls to leave types, likely:

```ruby
approval_policy: "manual" | "auto"
```

Recommended over multiple booleans to avoid contradictory states.

Behavior:

| Policy   | Meaning                                             |
| -------- | --------------------------------------------------- |
| `manual` | Submitted leave requires review                     |
| `auto`   | Submitted leave is automatically approved by policy |

---

## Approval-policy service

Introduce a small policy layer, for example:

```ruby
Leave::ApprovalPolicy
```

Responsibilities:

* determine whether a request requires manual approval
* determine whether it should auto-approve
* validate approval can proceed
* enforce overlap policy
* expose clear result/error objects

TC-25’s `Leave::LeaveRequestService` should consume this policy layer rather than duplicating rules.

MVP Leave Approval by Type does not require employee self-service leave submission. Admin/supervisor-managed leave request creation, submission, approval, rejection, cancellation, and reopening remain sufficient for MVP. Employee self-service may be added later against the same policy contract.

---

## Auto-approval behavior

Auto-approval should run synchronously on submit:

```text
draft → submitted → approved
```

Requirements:

* same transaction where practical
* approval event recorded
* actor recorded as system/policy metadata
* balance rules still enforced
* failure if balance is insufficient
* idempotent if submit is retried

Auto-approval events use a nullable `actor_id` with metadata identifying the actor as system/policy-driven, per [ADR-0005 — System actors in workflow audit events](../../adr/adr-0005-system-actors-in-workflow-audit-events.md). TeamCORE does not create a fake system user for MVP auto-approval.

---

## Manual approval behavior

For manually approved leave types:

```text
draft → submitted
submitted → approved
submitted → rejected
```

Approval creates operationally approved leave.

Approved leave becomes payroll-visible, but does not generate payroll exports.

---

## Authorization posture

MVP implementation should use the current agency-scoped access model unless supervisor identity mapping is already reliable.

Recommended posture:

| Actor                             | MVP behavior                                                |
| --------------------------------- | ----------------------------------------------------------- |
| Agency admin/payroll-capable user | May approve/reject/reopen                                   |
| Direct supervisor                 | Product-intended approver; enforce only when mapping exists |
| Employee                          | May submit/cancel own eligible requests, not approve        |

Document direct-supervisor enforcement as intended product posture, with stricter RBAC/supervision enforcement deferred to TC-29 if not already supported.

---

## Overlap policy

Implement or explicitly ticket:

```text
Block overlapping submitted or approved LeaveRequestDay rows
for the same engagement and leave_date.
```

Rejected and cancelled requests should not block new leave.

This protects payroll visibility and leave balance consistency.

A leave request may not be submitted or approved if any `LeaveRequestDay` overlaps an existing submitted or approved leave request for the same engagement and leave date. The rule applies regardless of leave type or number of hours. `LeaveRequestDay.hours` must be greater than zero.

---

## Rejection posture

Recommended MVP posture:

```text
rejected = terminal
```

Employees create a new corrected request after rejection.

This aligns with ADR-0004 and avoids reopening ambiguity. Add `rejected → draft` only if you intentionally amend ADR-0004.

---

## Cancellation and reopen behavior

Use ADR-0004 as the source of truth.

| Transition              | Behavior                          |
| ----------------------- | --------------------------------- |
| `draft → cancelled`     | allowed                           |
| `submitted → cancelled` | allowed                           |
| `approved → cancelled`  | allowed; restore consumed balance |
| `approved → draft`      | reopen; restore consumed balance  |
| `rejected → cancelled`  | not allowed                       |

---

`Leave::ApprovalPolicy` decides whether a transition is allowed. `Leave::LeaveRequestService` executes transitions, writes events, mutates balances, and persists state changes. Controllers and views must not reimplement approval policy checks.

# Work Items

## 1. Document approval policy contract

Deliverables:

* short implementation note
* [ADR-0005 — System actors in workflow audit events](../../adr/adr-0005-system-actors-in-workflow-audit-events.md) for nullable actor + metadata convention on auto-approved events
* optional separate ADR for leave approval policy gates if product wants normative text beyond this plan
* explicit reference to ADR-0004

Key statement:

```text
Leave Approval by Type defines approval policy gates and actors.
Leave request persistence, transitions, and balance side effects remain owned by the leave request service.
```

---

## 2. Add leave type approval policy field

Add to `LeaveType`:

```ruby
approval_policy
```

Allowed values:

```text
manual
auto
```

Default:

```text
manual
```

Validation:

* required
* constrained to allowed values

---

## 3. Add policy service

Create:

```ruby
Leave::ApprovalPolicy
```

Suggested API:

```ruby
policy = Leave::ApprovalPolicy.new(leave_request)

policy.auto_approve?
policy.manual_approval_required?
policy.approvable?
policy.overlap_violation?
policy.balance_violation?
```

Keep it small and deterministic.

---

## 4. Extend submit flow for auto-approval

Update `Leave::LeaveRequestService#submit!` or equivalent:

```text
draft
→ submitted
→ approved if leave_type.approval_policy == auto
```

Ensure:

* approval event exists
* balance consumption runs once
* failure rolls back cleanly
* status does not get stuck halfway

---

## 5. Enforce overlap rules

Add validation/service check against `LeaveRequestDay`.

Block overlap when existing request status is:

* `submitted`
* `approved`

Do not block when existing request status is:

* `draft`
* `rejected`
* `cancelled`

---

## 6. Tighten approval authorization

Extend existing access service, for example:

```ruby
Payroll::Access.can_manage_leave_request?
```

or introduce:

```ruby
Leave::Access
```

MVP can remain agency-scoped, but the service should make future supervisor enforcement easy.

---

## 7. Update admin UI

Admin leave request screens should show:

* leave type
* approval policy
* status
* submitted date
* requested days/hours
* balance impact
* overlap warnings/errors
* approve/reject actions for manual requests
* auto-approved indicator for auto-approved requests

Queues:

* pending manual approval
* recently auto-approved
* rejected/cancelled history as optional secondary view

---

## 8. Update Team360 leave panel

Show:

* pending leave
* approved leave
* recent rejected/cancelled leave
* approval policy label where helpful
* auto-approved indicator where applicable

Do not duplicate approval logic in Team360.

---

## 9. Tests

Minimum coverage:

* manual leave type submits to `submitted`
* auto leave type submits and approves
* auto approval consumes balance once
* insufficient balance blocks auto approval
* overlap with submitted request blocks
* overlap with approved request blocks
* overlap with rejected/cancelled request allowed
* unauthorized actor cannot approve
* approval event created for manual approval
* approval event created for auto approval
* approved cancellation restores balance
* rejected request remains terminal

---

# Explicit Deferrals

Do not implement in this work:

* delegated approval routing
* multi-stage approvals
* escalation chains
* HR case management
* regulatory leave compliance
* scheduling/coverage checks
* payroll export generation
* accrual engines
* contractor leave
* field-level security/RBAC beyond current MVP posture

---

# Recommended Delivery Order

1. Documentation/ADR alignment
2. `LeaveType.approval_policy`
3. `Leave::ApprovalPolicy` service
4. Auto-approval submit integration
5. Overlap enforcement
6. Authorization/access cleanup
7. Admin UI updates
8. Team360 updates
9. Tests and regression coverage
