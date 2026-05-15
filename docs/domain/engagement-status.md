# Engagement status semantics — TeamCORE

**Epic:** TC-04 — Employee and Contractor Status Models.

**Purpose:** Define **what** each `engagements.status` value **means** for each `engagements.relationship_type`, how status affects **downstream workflow eligibility** (documentation until those epics ship), and expectations for **Team360**, **operational reporting**, **audit**, and **permissions**. Lightweight eligibility predicates live in **`EngagementWorkflowEligibility`** on **`Engagement`** (**TC-04.11** / implementation) — not payroll/settlement/time/leave engines.

**Companion docs:** lifecycle **mechanism** — [`engagement.md`](engagement.md) (TC-03); decisions — [`../product/open-decisions.md`](../product/open-decisions.md) (**TC-04-D01…D05**); applicability — [`../product/employee-contractor-applicability-matrix.md`](../product/employee-contractor-applicability-matrix.md); Team360/reporting tables — [`organization.md`](organization.md) § Team360 and operational reporting (TC-01.10).

---

## TC-04 implementation lock (TC-04-D01 — TC-04-D05)

Formal register: **`open-decisions.md`**. This section is the domain mirror.

| ID | Topic | Decision |
| --- | --- | --- |
| **TC-04-D01** | Transition graph | **Same** MVP transition graph for **all** `relationship_type` values. **TC-03** / [`Engagement`](../../app/models/engagement.rb) remains **authoritative** for allowed transitions and business-date rules. TC-04 does **not** duplicate transition enforcement. Per-type **edge** restrictions are **deferred** unless product requires them. |
| **TC-04-D02** | Status reason storage | Reason-code **vocabulary** is documented **below** only. **`status_reason`**, **`status_reason_notes`**, and **status event history** tables are **deferred** in TC-04 to avoid pulling **TC-30** forward; persistent storage requires a **separate** UX/audit spike if needed soon. |
| **TC-04-D03** | Suspended | See **normative paragraph** under [Suspended behavior](#suspended-behavior-tc-04-d03). |
| **TC-04-D04** | Workflow predicates | **Lightweight** helpers on `Engagement` via **`EngagementWorkflowEligibility`** (**TC-04.11**) — **hints** for later epics. They are **not** readiness (**OD-006**), payroll, settlement, time, or leave engines, and **not** a substitute for **OD-009** permission checks. |
| **TC-04-D05** | Source of truth | **`engagements.status`** is the **only** persisted workforce **relationship lifecycle** status for this spine. **`Party`** and **`TeamMember`** use their own **record** lifecycle (`LifecycleStatusable`) — **not** employment/contract operational status. |

---

## Source of truth and non-goals

**Source of truth for operational workforce relationship state:**

```text
engagements.status
engagements.relationship_type
```

**TC-03 owns (mechanism — do not re-specify here except by reference):**

- Shared status vocabulary and **MVP transition graph** (`ALLOWED_STATUS_TRANSITIONS` in [`app/models/engagement.rb`](../../app/models/engagement.rb)).
- Terminal statuses and **no forward transition** from terminal.
- Business dates (`start_on`, `end_on`, etc.) per **TC-03-D07** in [`engagement.md`](engagement.md).

**TC-04 owns (this document):**

- Per-`relationship_type` **semantics** of each status.
- **Consumer contract**: which downstream capabilities are allowed, blocked, or historical **by policy** (actual engines ship in later epics).
- Reason-code **vocabulary** (not persistence in TC-04 per **TC-04-D02**).
- Team360 / reporting / audit **expectations** (requirements only until TC-10 / TC-12 / TC-29 / TC-30).

**Non-goals for TC-04:**

- New Party or TeamMember **workforce** status models.
- Separate `EmployeeStatus` / `ContractorStatus` tables or parallel status columns for MVP.
- Documents/compliance **readiness engine** (**OD-006**).
- Payroll, settlement, time, or leave **workflow implementation**.

---

## Shared status vocabulary

Statuses (single column on `engagements`): **`draft`**, **`pending`**, **`active`**, **`suspended`**, **`ended`**, **`terminated`**, **`cancelled`**.

Semantic **interpretation** varies by `relationship_type` in the sections below; the **allowed transitions** are the same for all types in MVP (**TC-04-D01**).

---

## Employee (`relationship_type = employee`)

### Status meanings

| Status | Meaning |
| --- | --- |
| `draft` | Employment engagement is being prepared. |
| `pending` | Onboarding or setup incomplete; not yet active in workforce operations. |
| `active` | Employee is active and **eligible for employee-class operational workflows** when those epics exist (time, leave, payroll input — see matrix). |
| `suspended` | Temporarily **not eligible for new forward operational work** by default; see [Suspended behavior](#suspended-behavior-tc-04-d03). |
| `ended` | Employment ended in a **normal or planned** separation sense (product nuance for reporting may extend later). |
| `terminated` | Employment ended by **termination** action (distinct label for HR/reporting); same transition graph as `ended` in MVP. |
| `cancelled` | Engagement never became effective; optionally documented with reason vocabulary when reasons are persisted later. |

### Workflow effects (policy — not implemented engines)

| Status | Time | Leave | Payroll input | Documents | Team360 |
| --- | :---: | :---: | :---: | :---: | :---: |
| `draft` | No | No | No | Setup-oriented | Limited / admin |
| `pending` | No | No | No | Yes (onboarding path) | Visible as pending |
| `active` | Yes¹ | Yes¹ | Yes¹ | Yes | Full permitted view (when TC-10 allows) |
| `suspended` | No / block new² | Restricted² | Restricted² | Yes | Warning / muted state |
| `ended` | No | No | Historical / finalize | History | Historical |
| `terminated` | No | No | Historical / finalize | History | Historical / restricted display |
| `cancelled` | No | No | No | Minimal / none | Admin / historical |

¹ **Eligibility only** — period locks, approvals, readiness (**OD-006**), and **OD-009** gates apply in later epics.  
² **Default:** block **new** forward work; corrections and permissioned exceptions are **later** epics (**TC-30**).

 **`active`** is the sole status where **employee-only** rails (time, leave, payroll **input** in MVP framing) are **intended** to attach; predicates in **`EngagementWorkflowEligibility`** encode this hint.

---

## Individual contractor (`relationship_type = individual_contractor`)

### Status meanings

| Status | Meaning |
| --- | --- |
| `draft` | Contractor engagement being prepared. |
| `pending` | Setup, contract, or readiness incomplete. |
| `active` | Active for **contractor-class** workflows (settlement/charges/documents — when implemented). |
| `suspended` | Temporarily blocked from **new** settlement-type forward work by default (**TC-04-D03**). |
| `ended` | Relationship concluded normally or contract expired. |
| `terminated` | Ended by agency/contract action; same MVP graph as `ended`. |
| `cancelled` | Never became effective. |

### Workflow effects (policy)

| Status | Time / Leave | Payroll | Settlement | Charges | Documents | Team360 |
| --- | :---: | :---: | :---: | :---: | :---: | :---: |
| `draft` | No | No | No | No / setup | Setup | Limited / admin |
| `pending` | No | No | No | Setup possible | Yes | Pending |
| `active` | No | No | Yes¹ | Yes¹ | Yes | Full permitted view |
| `suspended` | No | No | Block new² | Review / wind-down | Yes | Warning |
| `ended` | No | No | Historical | Recover / history | History | Historical |
| `terminated` | No | No | Historical | Recover / history | History | Historical / restricted |
| `cancelled` | No | No | No | No | Minimal | Admin / historical |

¹ Eligibility hints — not settlement **runs** or accounting.  
² Default block on **new** forward settlement-cycle work.

**Individual contractors never** use employee time, leave, or payroll-input rails in MVP ([**applicability matrix**](../product/employee-contractor-applicability-matrix.md)).

---

## Contractor organization (`relationship_type = contractor_organization`)

Represents agency relationship with an **organization** Party (not a person). **Contractor-org** engagements use the **same** status vocabulary and MVP transition graph as other types (**TC-04-D01**).

### Interpretation highlights

- Eligible **in principle** for contractor-class outcomes: documents/compliance framing, settlement, contractor charges, org-oriented Team360, primary-contact and subcontractor **PartyRelationship** visibility — when those domains exist.
- **Not** a person: **no** employee time, leave, or payroll input.
- **Supervision:** per **TC-03-D05**, a **`contractor_organization`** engagement **must not** be the supervisor in MVP; it **may** be supervised.

### Status meanings

Align row labels with individual contractor (**draft** … **cancelled**) with org-context wording (“organization engagement”, “contract/setup”, etc.). Workflow-effect **posture** matches **contractor-class** rows above (no time/leave/payroll; settlement/charges when **active** as eligibility hints).

---

## Subcontractor (`relationship_type = subcontractor`)

### Related party vs promoted subcontractor

- **Related party only:** **`PartyRelationship`** (often under **OD-004**) — visibility/context; **no** `Engagement` required.
- **Promoted:** **`TeamMember` + Engagement** with **`subcontractor`** when the agency needs direct documents, Team360, settlement, or operational rails on that party.

Operational semantics follow **promotion/configuration**: subcontractor engagements **do not** duplicate **`PartyRelationship.status`** — relationship graph vs workforce engagement remain distinct (see **TC-03-D06**).

### Status meanings

Same seven statuses; interpret as **direct subcontractor** setup (`draft`/`pending`), active subcontractor posture (`active`), suspend/end/terminate/cancel analogous to contractor-class.

### Workflow effects (MVP framing)

| Capability | Effect |
| --- | --- |
| Documents / compliance | If promoted and configured (**Phase 2+**). |
| Team360 | If promoted (**TC-10**). |
| Settlement | Only if modeled as directly engaged/settled (**OD-008** trajectory). |
| Time / Leave | **No** in MVP. |
| Payroll | **No** in MVP. |
| Contractor charges | **Maybe** later if product ties charges to subcontractor engagements. |

---

## Shared MVP transition graph (TC-04-D01)

Authoritative transitions are implemented in **`Engagement`** (`ALLOWED_STATUS_TRANSITIONS`). TC-04 **confirms** the same graph applies to **all** `relationship_type` values; **effects** differ by type above; **edges** do not vary by type in MVP.

| From | To |
| --- | --- |
| `draft` | `pending`, `cancelled` |
| `pending` | `active`, `cancelled` |
| `active` | `suspended`, `ended`, `terminated` |
| `suspended` | `active`, `ended`, `terminated` |

Terminal: **`ended`**, **`terminated`**, **`cancelled`** — no normal forward transitions (see TC-03).

---

## Status reason codes (documentation only — TC-04-D02)

Vocabulary for **human** status changes; **no** persisted `status_reason` in TC-04 unless product opens a spike (see **TC-04-D02**). When stored later, pair with **TC-30** (who/when/prior status).

### Suspension-oriented (illustrative)

`missing_documents`, `compliance_review`, `contract_issue`, `performance_review`, `administrative_hold`, `other`

### End-oriented

`completed_term`, `contract_expired`, `voluntary_separation`, `role_change`, `converted_to_employee`, `converted_to_contractor`, `other`

### Termination-oriented

`termination_for_cause`, `termination_without_cause`, `contract_breach`, `agency_decision`, `contractor_decision`, `other`

### Cancellation-oriented

`created_in_error`, `duplicate_record`, `candidate_withdrew`, `contract_not_executed`, `other`

---

## Suspended behavior (TC-04-D03)

**Normative:**

> Suspended engagements are not eligible for new forward operational work by default, but may remain visible for history, correction, review, finalization, or permissioned exception workflows defined by later epics.

Applies to **employee** and **contractor-class** engagements. **Suspended** retains placement/supervision rows per **TC-03** unless a future epic changes data rules.

---

## Workflow effects summary (consumer contract)

- **Employee path:** **`active`** is the hinge for intended time/leave/payroll-**input** eligibility (**matrix** above + [**applicability matrix**](../product/employee-contractor-applicability-matrix.md)).
- **Contractor-class path** (`individual_contractor`, `contractor_organization`, promoted **`subcontractor`):** **`active`** is the hinge for settlement/charges **eligibility hints**; **never** employee time/leave/payroll input in MVP.
- **Mutual exclusivity** of payroll vs settlement **rails per engagement** remains a product invariant ([**applicability matrix** § Payroll vs settlement](../product/employee-contractor-applicability-matrix.md)).
- **Readiness (**OD-006**):** May **gate** activation later; TC-04 documents posture only (**TC-03-D08**).

---

## Team360 and reporting (requirements)

### Team360 (**TC-10**, **TC-11** if numbered in tracker)

Suggested **read** surfaces (exact UX TC-10 / TC-29):

- `relationship_type`, `status`, business dates (`start_on`, `end_on`, `expected_end_on`, `renewal_on` per policy).
- Status **labels** map 1:1 to enum for default UI: Draft, Pending, Active, Suspended, Ended, Terminated, Cancelled.
- **Warning** presentation for **`suspended`**; **historical / terminal** treatment for **`ended` / `terminated` / `cancelled`**.
- Placement + supervisor resolution remains per [`engagement.md`](engagement.md) § Team360 cross-links → [`organization.md`](organization.md) § Team360 organization context fields.

### Operational reporting (**TC-12**)

Standard facets and lists (conceptual inventory — UX TC-12):

- Counts/filter by **`relationship_type`** and **`status`** (active/pending/suspended/ended/terminated/cancelled employees and contractor classes).
- Cuts by placement dimensions (department, location, team) and supervisor when TC-03 data exists ([`organization.md`](organization.md) § Operational reporting filters, drill-through).
- Optional slices: cancelling before activation, ending soon (**`expected_end_on` / `end_on`** — reporting logic later), suspended without persisted reason (**deferred** until reason storage).

---

## Sensitive status actions — audit & permission (**TC-29** / **TC-30**)

**Illustrative sensitive actions:**

- Changing `status`; activating; suspending; ending; terminating; cancelling.
- (Future) Changing or requiring **status reason**.
- Reactivating **`suspended` → `active`**.
- **Correcting** a wrong status or **bypassing** normal transitions — **correction / audit territory** (**TC-30**); never silent overwrite of history (**TC-03-D09**).

**Expectation:** coarse gates (**OD-009** provisional) → hardened **Phase 6** permissions; immutable audit artifacts **TC-30**. Align posture with **[`organization.md`](organization.md)** § Audit and permission impact note (TC-01.12) and **`open-decisions.md`** **OD-010**.

**Bypass:** Override of normal transitions = **elevated** control + eventual **audit trail** — not MVP implementation in TC-04.

---

## Downstream consumers (non-exhaustive)

Later epics **consume** `Engagement` + this policy doc as inputs: Documents/Compliance (**Phase 2**), Team360 (**TC-10**), Operational reporting (**TC-12**), Compensation, Contractor settlement (**OD-008**), Time/Leave (**Phase 5**), Payroll input (**OD-007**), Permission-aware UX (**TC-29**), Audit history (**TC-30**).

---

## Acceptance checklist (TC-04 docs track)

Used for epic / PR **A** sign-off mapping:

- [ ] `engagement-status.md` identifies **`engagements.status`** + **`relationship_type`** as source of truth (**TC-04-D05**).
- [ ] TC-03 **mechanism** vs TC-04 **semantics** boundary is explicit.
- [ ] Party / TeamMember **not** workforce relationship status carriers.
- [ ] Meanings documented for employee, individual contractor, contractor organization, subcontractor.
- [ ] Shared transition graph **confirmed** aligned with TC-03 (**TC-04-D01**); no duplicate enforcement spec.
- [ ] Reason vocabulary documented; storage **deferred** (**TC-04-D02**).
- [ ] Suspended paragraph locked (**TC-04-D03**).
- [ ] Workflow effects documented; applicability matrix referenced.
- [ ] Team360 + reporting + TC-12 / TC-10 / TC-11 references present.
- [ ] Audit/permission sensitive actions and TC-29/TC-30 called out.

---

## Related

- [`engagement.md`](engagement.md) — TC-03 lifecycle, placement, supervision.
- [`party-team-member.md`](party-team-member.md) — Identity vs participant.
- [`organization.md`](organization.md) — Team360 org strip, reporting filters, drill-through.
- [`../product/open-decisions.md`](../product/open-decisions.md) — **TC-04-D01…D05** register rows.
