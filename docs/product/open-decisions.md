# Open decisions register

This register tracks product and modeling decisions for TeamCORE. Not every item needs the same rigor: use the **decision handling model** below so Phase 0 can close without pretending Phase 4–6 design is final.

**Companion docs:** [`domain-map.md`](domain-map.md), [`overview.md`](overview.md), [`roadmap-decision-log.md`](roadmap-decision-log.md), [`../roadmap/phase-1-readiness-checklist.md`](../roadmap/phase-1-readiness-checklist.md), [`employee-contractor-applicability-matrix.md`](employee-contractor-applicability-matrix.md), [`glossary.md`](glossary.md), [`../domain/party-team-member.md`](../domain/party-team-member.md), **[`../domain/engagement.md`](../domain/engagement.md)** (TC-03), **[`../domain/engagement-status.md`](../domain/engagement-status.md)** (TC-04).

---

## Decision handling model

| Tier | Use for | Typical output |
| --- | --- | --- |
| **Tier 1 — Lock before Phase 1** | Decisions that affect core models/schema immediately | Entry here + short modeling note; ADR when immutability matters |
| **Tier 2 — Define now, refine later** | Terms and workflows needed for roadmap clarity, not immediate schema blockers | Glossary + product rule note |
| **Tier 3 — Defer to later phase** | Decisions tied to mid/late MVP phases | Register entry now; ADR or spike when implementation pressure arrives |

---

## Decision index (by tier)

| ID | Summary | Tier |
| --- | --- | --- |
| OD-001 | Party vs Team Member | 1 |
| OD-002 | Multiple engagements | 1 |
| OD-003 | Employee vs contractor status | 1 |
| OD-004 | Subcontractor relationship (MVP) | 1 |
| OD-011 | Agency vs Organization (concept + Phase 1 implementation / **ADR-0001**) | 1 |
| TC-02-D01 | Team member number optional + unique when present | 1 |
| TC-02-D02 | Party/profile draft-tolerant; TeamMember requires complete identity | 1 |
| TC-02-D03 | One active primary contact per org (effective dating + status) | 1 |
| TC-02-D04 | Organization Party not auto–TeamMember | 1 |
| TC-02-D05 | Party.display_name authoritative; default from profile | 1 |
| TC-03-D01 | Engagement `relationship_type` enum + Party constraints | 1 |
| TC-03-D02 | Engagement business statuses + MVP transitions | 1 |
| TC-03-D03 | One `active` engagement per type + concurrency posture | 1 |
| TC-03-D04 | Placement + overlap rules | 1 |
| TC-03-D05 | Supervision MVP (`primary_reports_to`) | 1 |
| TC-03-D06 | Subcontractor PartyRelationship vs Engagement | 1 |
| TC-03-D07 | Engagement business dates (`*_on`) | 1 |
| TC-03-D08 | `pending` / activation (no OD-006 engine in TC-03) | 1 |
| TC-03-D09 | Correction / history posture | 1 |
| TC-03-D10 | ADR vs domain doc (#72) | 1 |
| TC-04-D01 | Same engagement transition graph for all `relationship_type` (MVP) | 1 |
| TC-04-D02 | Defer `status_reason` / event history persistence (doc-only vocabulary in TC-04) | 1 |
| TC-04-D03 | Suspended: no new forward operational work by default | 1 |
| TC-04-D04 | Lightweight workflow eligibility predicates (hints; not engines) | 1 |
| TC-04-D05 | `engagements.status` sole workforce relationship lifecycle SOT | 1 |
| OD-005 | Documents vs Compliance boundary | 2 |
| OD-006 | Activation readiness | 2 |
| OD-007 | Payroll input vs payroll run | 2 |
| OD-008 | Contractor settlement vocabulary | 2 |
| OD-012 | Compensation vs settlement ownership (concept) | 2 |
| OD-009 | Permissions depth (MVP default) | 2 (provisional) |
| OD-010 | Audit depth (policy direction) | 2 / 3 |
| OD-012 (detail) | Draw recovery / settlement application details | 3 |
| OD-005 (impl) | Documents/Compliance module split | 3 |
| OD-006 (rules) | Deterministic readiness rule set | 3 |

---

## Accepted decisions

### OD-001 — Party vs Team Member

**Status:** Accepted  
**Tier:** 1  
**Blocks:** Party, Team Member, Engagement schema

**Decision:** Use separate concepts:

```text
Party = identity/legal/contact entity
Team Member = agency-linked workforce participant profile
Engagement = specific employee/contractor relationship
```

**Rationale:** Separates identity from workforce participation; supports contractor organizations, related contacts, history, future vendors, and Team360 without overloading identity rows.

**Follow-up:** Modeling note [`modeling-notes/party-team-member-engagement.md`](modeling-notes/party-team-member-engagement.md). Promote to ADR if the team requires formal architecture sign-off.

---

### OD-002 — Multiple engagements

**Status:** Accepted with constraint  
**Tier:** 1  
**Blocks:** Engagement cardinality, uniqueness, status logic, history

**Decision:**

- A team member may have **multiple engagements over time**.
- **Normally** only **one active engagement per relationship type** at a time.
- **Simultaneous employee + contractor** engagements are **not** default; require explicit administrative allowance or later-phase support.
- Overlapping contractor relationships may be scoped later (contract/program/client).

**Rationale:** Matches real history (rehire, contractor→employee) without making the MVP unconstrained.

**Follow-up:** Product rule in glossary; schema uniqueness/index strategy in Phase 1 modeling.

---

### OD-003 — Employee status vs contractor status

**Status:** Accepted  
**Tier:** 1  
**Blocks:** Engagement lifecycle, workflow eligibility

**Decision:** Model status primarily on **Engagement**, with **relationship type** (`employee` | `contractor`) and **type-specific allowed statuses** / state rules. Do **not** create separate top-level domains named “Employee Status” and “Contractor Status.”

**Rationale:** A party is not “active” in the abstract; activity is always in the context of a relationship.

**Follow-up:** **TC-03-D01** refines the **persisted operational** `relationship_type` set (`employee`, `individual_contractor`, `contractor_organization`, `subcontractor`) and business statuses — see [`../domain/engagement.md`](../domain/engagement.md) and **TC-03-D01…D10** below. **Per-type status semantics** and downstream consumer contract: [`../domain/engagement-status.md`](../domain/engagement-status.md) (**TC-04-D01…D05**). Enumerations and transition rules are implemented in Rails per the engagement doc.

---

### OD-004 — Subcontractor relationship

**Status:** Accepted for MVP; revisit later  
**Tier:** 1 (MVP rule), 3 (advanced cases)

**Decision (MVP):**

- Subcontractors may appear as **related parties** linked to a contractor or contractor organization.
- **Promote** to **Team Member** (and engagements as needed) when the agency requires direct operational tracking, documents/compliance **on the subcontractor**, Team360 visibility, or settlement-related records.

| Need | MVP model |
| --- | --- |
| Name/contact only | Related party / contact |
| Compliance docs required | Related party + requirements, **or** Team Member if tracked directly |
| Direct work tracking | Team Member |
| Direct settlement/payment | Team Member + contractor engagement |
| Team360 profile | Team Member |

**Follow-up:** Glossary + product rule checklist issue.

---

### TC-02-D01 — Team member number

**Status:** Accepted  
**Tier:** 1 — TC-02 implementation

**Decision:** `team_member_number` is optional in MVP. When present, it is unique within the agency (multiple NULLs allowed in MySQL). It is normalized strip + uppercase as an agency internal identifier, not the **`NormalizesCode`** concern used for lowercase org codes.

### TC-02-D02 — Party / profile completeness

**Status:** Accepted  
**Tier:** 1

**Decision:** Party persistence is draft-tolerant (Party may exist before matching PersonProfile or OrganizationProfile). Creating a TeamMember requires `identity_complete?` for that party type.

### TC-02-D03 — Active primary contact

**Status:** Accepted  
**Tier:** 1

**Decision:** At most one **currently effective** `primary_contact` relationship per source party (`status` active + effective date window per [`party-team-member.md`](../domain/party-team-member.md)).

### TC-02-D04 — Organization Party vs Team Member

**Status:** Accepted  
**Tier:** 1

**Decision:** Organization-type parties are not automatically TeamMembers; add TeamMember only when the org participates directly as workforce participant (paths consumed by TC-03+).

### TC-02-D05 — Party display name

**Status:** Accepted  
**Tier:** 1

**Decision:** `Party.display_name` is the authoritative UI label; may default from profile when blank and is required when identity is complete; ongoing sync from profile updates is **not** required.

---

### TC-03 implementation lock (TC-03-D01…D10)

**Status:** Accepted for Phase 1 TC-03 schema and validation  
**Tier:** 1  
**Authoritative detail:** [`../domain/engagement.md`](../domain/engagement.md)

| ID | Decision (summary) |
| --- | --- |
| **TC-03-D01** | Persist **`employee` \| `individual_contractor` \| `contractor_organization` \| `subcontractor`**; constrain to Party `party_type` per engagement doc. |
| **TC-03-D02** | Seven business statuses; MVP transition graph; **not** `LifecycleStatusable`; suspended retains placement/supervision context. |
| **TC-03-D03** | At most one **`status = active`** per `(agency_id, team_member_id, relationship_type)` via app validation + tests; concurrency limitation documented. |
| **TC-03-D04** | Effective-dated **`engagement_organization_placements`** with inclusive overlap rules; back-to-back segment handoff. |
| **TC-03-D05** | **`engagement_supervision_assignments`** with **`primary_reports_to`**; active supervisor; no **`contractor_organization`** as supervisor in MVP. |
| **TC-03-D06** | Subcontractor **`PartyRelationship`** vs promoted **`Engagement`** workflow authority. |
| **TC-03-D07** | **`start_on` / `end_on` / `expected_end_on` / `renewal_on`** invariants by status. |
| **TC-03-D08** | **`pending`** semantics; TC-03 activation without full **OD-006** engine. |
| **TC-03-D09** | History on child rows; no engagement version table in TC-03. |
| **TC-03-D10** | Domain doc + this register suffice; ADR only if architecture materially changes. |

**Same-agency:** Enforced for engagement, placement targets, and supervision (see domain doc).

---

### TC-04 implementation lock (TC-04-D01…D05)

**Status:** Accepted for TC-04 documentation and later predicate work  
**Tier:** 1  
**Authoritative detail:** [`../domain/engagement-status.md`](../domain/engagement-status.md)

| ID | Decision (summary) |
| --- | --- |
| **TC-04-D01** | **Same** MVP transition graph for **all** `relationship_type` values; **TC-03** / `Engagement` authoritative for enforcement; no per-type edge restrictions in MVP unless product requires them. |
| **TC-04-D02** | Reason-code **vocabulary** documented in domain only; **no** `status_reason` / notes / status-event tables in TC-04 — defer to avoid pulling **TC-30** forward; separate spike if persistent reasons are needed soon. |
| **TC-04-D03** | **Suspended:** not eligible for **new** forward operational work **by default**; history, correction, review, finalization, permissioned exceptions = later epics (see engagement-status doc normative paragraph). |
| **TC-04-D04** | **Lightweight** eligibility helpers on `Engagement` (`EngagementWorkflowEligibility`; **TC-04.11**): **hints** only — not **OD-006** readiness, payroll run, settlement run, time, or leave engines; **not** a substitute for **OD-009** permission checks. |
| **TC-04-D05** | **`engagements.status`** is the **only** persisted workforce **relationship lifecycle** status on this spine; **Party** / **TeamMember** use **record** lifecycle (`LifecycleStatusable`) — not employment/contract operational status. |

**No migration** for TC-04 status reasons (**TC-04-D02**). **TC-04.11** implements `EngagementWorkflowEligibility` predicates; **TC-04.12** extends `db/seeds.rb` with pending / suspended / ended examples.

---

### OD-005 — Documents vs Compliance (conceptual)

**Status:** Accepted conceptually; implementation deferred  
**Tier:** 2 concept, Tier 3 implementation boundary

**Decision:**

```text
Documents — uploaded artifacts, metadata, verification state attached to artifacts
Compliance — requirement rules, completeness, expirations, readiness signals, alerts
```

**Rationale:** An artifact is not the same thing as interpretation of requirements.

**Follow-up:** Phase 2 module/bounded-context boundary; update glossary definitions.

---

### OD-006 — Activation readiness (concept)

**Status:** Accepted (concept); detailed rules deferred  
**Tier:** 2 concept, Tier 3 rules engine

**Decision:**

- **Compliance** owns activation readiness **calculation**.
- Readiness is a **deterministic signal** derived from configured requirements, document states, verification, expiration rules, and engagement status.
- **Manual override**, if introduced, must be permission-controlled, reason-coded, and audit-tracked—not the default MVP behavior.

**Follow-up:** Readiness rules backlog for Phase 2; glossary entry.

---

### OD-007 — Payroll input vs payroll run

**Status:** Accepted (naming)  
**Tier:** 2

**Decision:**

```text
Payroll Input — data TeamCORE prepares for payroll processing
Payroll Run — payroll processing cycle or batch reference (often external/manual in MVP)
Payroll Export — files sent out
Payroll Result — outcomes recorded back
```

TeamCORE prepares inputs and records results; it is **not** the payroll processor in MVP.

**Follow-up:** Glossary + UX string review for issues/UI.

---

### OD-008 — Contractor settlement vocabulary

**Status:** Accepted (naming)  
**Tier:** 2

**Decision:** Disambiguate:

| Term | Use for |
| --- | --- |
| **Contractor settlement** | Overall workflow |
| **Settlement run** | Batch/cycle |
| **Settlement calculation** | Computed payable/recoverable values |
| **Settlement result** | Final recorded outcome |
| **Settlement export** | File sent out |
| **Settlement import** | Results loaded back |

**Follow-up:** Glossary + UX string review.

---

### OD-010 — Audit depth (policy direction)

**Status:** Accepted as policy direction  
**Tier:** 2 direction, Tier 3 formal ADR before highest-risk workflows

**Decision:** MVP audit should cover (non-exhaustive): engagement lifecycle; status changes; document verification; activation readiness override (if any); contractor charge create/update/waiver; timesheet approval; leave approval; payroll export/import/manual result; settlement export/import/manual result; permission-sensitive changes; admin config affecting requirements, compensation, payroll, or settlement.

**Levels:** lifecycle event; change history; approval/decision audit; import/export audit.

**Follow-up:** Dedicated audit policy issue; ADR or spike before Phase 6 hardening if gaps appear.

---

### OD-011 — Agency vs Organization (concept)

**Status:** Accepted (concept + Phase 1 implementation)  
**Tier:** 1 schema pattern — **ADR-0001** documents the implementation choice  
**Companion:** [`domain/organization.md`](../domain/organization.md), **[`adr/adr-0001-agency-organization-schema.md`](../adr/adr-0001-agency-organization-schema.md)**

**Decision (product language):**

```text
Agency = the business using TeamCORE (top-level operating context)
Organization = the agency's internal structure (domain term — not an AR model in TC-01)
```

**Implementation (Phase 1 / TC-01):** Standalone **`Agency`** model; **`Department`**, **`Location`**, and **`Team`** belong to **`Agency`**. No polymorphic **`Organization`** table.

**Resolved:** ~~Modeling note or ADR selecting implementation option.~~ Completed with **ADR-0001**.

---

### OD-012 — Compensation vs settlement ownership (concept)

**Status:** Accepted (concept); detail deferred  
**Tier:** 2 glossary boundary, Tier 3 detailed modeling

**Decision:**

```text
Compensation — plans and earning components owed to the team member
Contractor charges — recoverables and balances owed to the agency
Settlement — run/result that applies compensation, charges, recoveries, adjustments
```

**Draw recovery:** Compensation may define the draw arrangement; charges/recoverables may track outstanding balances; **settlement calculation/application** executes recovery and records results.

**Follow-up:** Phase 4 ADR/modeling note for calculation ownership edge cases.

---

## Provisional decisions

### OD-009 — Permissions depth

**Status:** Provisional (MVP)  
**Tier:** 2 MVP default, Tier 3 full hardening

**Decision (MVP):**

- Role-based access
- Domain/action checks
- Team360 panel visibility rules
- Sensitive workflow action gates
- Basic organization/location/team scoping where needed

**Defer:** Full field-level security, heavy row-level policy engines, segregation-of-duties matrix, per-field masking—unless a specific field forces an exception.

**Follow-up:** **Needs ADR** before Phase 3/6 alignment; revisit when Team360 hardens.

---

## Deferred decisions / follow-ups

Items accepted at concept level elsewhere; detailed design waits for phased delivery.

| ID | Deferred work | Target phase |
| --- | --- | --- |
| OD-005 | Documents vs Compliance bounded-context/module layout | Phase 2 |
| OD-006 | Deterministic readiness rule catalog | Phase 2 |
| OD-007 / OD-008 | Implementation naming in APIs and DB column terminology | Phase 4–5 |
| OD-009 | Full permission model ADR | Phase 3–6 |
| OD-010 | Formal audit ADR if policy gaps | Phase 6 |
| OD-012 | Settlement calculation vs compensation engine boundaries | Phase 4 |
| OD-004 | Advanced subcontractor / multi-party graph | Post-MVP |

---

## Lock before closing TC-0 / Phase 0 modeling kickoff

These should be **accepted** (as above) before treating Phase 1 schema as unblocked:

- OD-001, OD-002, OD-003, OD-004 (MVP rule), OD-011 (concept + **ADR-0001** implementation)

The remainder supply **language and direction** so issues stay consistent without front-loading every implementation detail.
