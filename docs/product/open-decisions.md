# Open decisions register

This register tracks product and modeling decisions for TeamCORE. Not every item needs the same rigor: use the **decision handling model** below so Phase 0 can close without pretending Phase 4–6 design is final.

**Companion docs:** [`domain-map.md`](domain-map.md), [`overview.md`](overview.md), [`roadmap-decision-log.md`](roadmap-decision-log.md), [`../roadmap/phase-1-readiness-checklist.md`](../roadmap/phase-1-readiness-checklist.md), [`employee-contractor-applicability-matrix.md`](employee-contractor-applicability-matrix.md), [`glossary.md`](glossary.md), [`../domain/party-team-member.md`](../domain/party-team-member.md), **[`../domain/engagement.md`](../domain/engagement.md)** (TC-03), **[`../domain/engagement-status.md`](../domain/engagement-status.md)** (TC-04), **[`../domain/documents-compliance.md`](../domain/documents-compliance.md)** (TC-06), **[`../domain/document-alerts.md`](../domain/document-alerts.md)** (TC-07), **[`../domain/document-verification.md`](../domain/document-verification.md)** (TC-08), **[`../domain/contractor-classification-support.md`](../domain/contractor-classification-support.md)** (TC-09), **[`../domain/team360.md`](../domain/team360.md)** (TC-10 / TC-11), **[`../domain/operational-reporting.md`](../domain/operational-reporting.md)** (TC-12).

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
| TC-07-D01 | Document alerts: virtual only (no persisted alert table) | 2 |
| TC-07-D02 | Alert severities `blocking` / `warning` / `info` (`info` unused by default) | 2 |
| TC-07-D03 | Expiring-soon window chain (requirement → type default → agency optional → hard 30) | 2 |
| TC-07-D04 | No alert dismissal/snooze/waiver in TC-07 | 2 |
| TC-07-D05 | No email/SMS/background alert jobs in TC-07 | 2 |
| TC-07-D06 | Alerts only for `required: true` requirements | 2 |
| TC-07-D07 | `Documents::AlertMessageBuilder` owns `AlertResult#message` | 2 |
| TC-07-D08 | Default evaluator `as_of_date` is `Date.current` | 2 |
| TC-07-D09 | Deterministic alert sort order (severity, type, expires_on, type code) | 2 |
| TC-07-D10 | Engagement detail evaluates all statuses; alert index defaults non-terminal engagements | 2 |
| TC-08-D01 | Verification field naming — keep **`verified_*`**; rejects use reviewer actor/date (**TC-08**) | 2 |
| TC-08-D02 | **`rejection_reason`** required when **`status = rejected`** | 2 |
| TC-08-D03 | Void MVP — no **`voided_*`** columns; optional notes; TC-30 for durable void audit | 2 |
| TC-08-D04 | No **`rejected` → `submitted`** in-place; new **`DocumentRecord`** for correction | 2 |
| TC-08-D05 | Verification authorization — MVP coarse verifier gate; TC-29 matrix later | 2 |
| TC-08-D06 | Pending-review queue is **`DocumentRecord.status = submitted`** (optional **`verification_required`** hint) | 2 |
| TC-08-D07 | Review **`status`** / review metadata change only via **`Documents::ReviewDocumentRecord`**, not generic CRUD (**TC-08**) | 2 |
| TC-09-D01 | Contractor classification support is a lens over TC-06–TC-08, not a new compliance engine | 2 |
| TC-09-D02 | Legal-safe wording: “classification support status,” not legal classification language | 2 |
| TC-09-D03 | Use **`DocumentType.category`** + specific **`DocumentType.code`**; no new category enums unless migrated | 2 |
| TC-09-D04 | Related-only subcontractors excluded; promoted subcontractors evaluate via **`subcontractor`** Engagement | 2 |
| TC-09-D05 | Operational reporting deferred to **TC-12**; TC-09 documents report requirements | 2 |
| TC-09-D06 | Reuse existing **`readiness_status`** values; no new classification-readiness vocabulary | 2 |
| TC-09-D07 | Contractor organization engagements may receive contractor classification-support requirements where configured | 2 |
| TC-09-D08 | Contractor-only tax/W-9-style requirements must not use **`relationship_type: any`** unless intentionally universal | 2 |
| TC-3-D01 | Team360: read-only assembly; **no** persisted profile / **`team360s`** table | 2 |
| TC-3-D02 | Team360 and reports: optional **`as_of_date`** param; default **`Date.current`** for placement, supervision, evaluator | 2 |
| TC-3-D03 | **`focused_engagement`** is **display selection only** (non-persisted); drives org/doc panels; not legal/payroll primary | 2 |
| TC-3-D04 | Operational report rows drill to Team360 and source admin records | 2 |
| TC-3-D05 | Phase 3 permissions: agency scope + existing admin auth only; **no** partial TC-29 masking | 2 |
| TC-3-D06 | **No** reporting snapshot tables in Phase 3; query models + evaluator at request time | 2 |
| TC-3-D07 | Deferred-domain Team360 panels: **placeholder** static copy only | 2 |
| TC-3-D08 | Report filters use **existing domain vocabulary** (engagement status/type, evaluator alert fields, org ids, as-of) | 2 |
| TC-3-D09 | Presenters format only; **do not** compute readiness outcomes, alert severity, or classification in views | 2 |


### TC-3-D01–D09 — Phase 3 Team360 and operational reporting

**Status:** Accepted for Phase 3 implementation  
**Tier:** 2  
**Detail:** Authoritative narrative in **[`../domain/team360.md`](../domain/team360.md)** and **[`../domain/operational-reporting.md`](../domain/operational-reporting.md)**.

**Summary**

| ID | Decision |
| --- | --- |
| TC-3-D01 | **No `team360s` table.** Team360 = assembler + snapshot / read path only. |
| TC-3-D02 | **`as_of_date`** on Team360 and reports (default today) for placement, supervision, document evaluation. |
| TC-3-D03 | **`focused_engagement`** chooses which engagement feeds org + document panels; **not persisted**; not primary legal/compliance designation. |
| TC-3-D04 | Report rows link to Team360 and authoritative records (engagement, document record, party, etc.). |
| TC-3-D05 | **No panel-level permission branches** in Phase 3 beyond existing admin + agency scope; **TC-29** for masking later (`TODO(TC-29)` acceptable). |
| TC-3-D06 | **No persisted report snapshots** in Phase 3. |
| TC-3-D07 | Compensation / payroll / settlement / time / leave / durable audit: **placeholders** only (no fake data). |
| TC-3-D08 | Filters use model/evaluator vocabulary; no ad-hoc parallel status labels in query strings. |
| TC-3-D09 | Presentation layer: labels, badges, links; **evaluator** owns requirement outcomes and alert severities; mapping DB `engagement.status` → label is formatting, not re-computation. |

**Handoff:** Full **permission-aware Team360** and durable audit timeline remain **Phase 6 / TC-29 / TC-30** per [`domain-map.md`](domain-map.md).

---

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

**Follow-up:** Glossary + product rule checklist issue. Phase 1 rules, validation, and admin UX: [`../domain/subcontractor-relationships.md`](../domain/subcontractor-relationships.md) **(TC-05)**. Sensitive actions (subcontractor relationship edits, promote-to-workforce) use **existing admin authentication** only; durable audit trails and **TC-29** / **TC-30** RBAC remain future work.

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

**Follow-up:** Phase 2 module/bounded-context boundary; update glossary definitions. **TC-06 hub:** [`../domain/documents-compliance.md`](../domain/documents-compliance.md) (models + `Documents::ReadinessEvaluator`; **OD-005** implementation detail).

---

### OD-006 — Activation readiness (concept)

**Status:** Accepted (concept); detailed rules deferred  
**Tier:** 2 concept, Tier 3 rules engine

**Decision:**

- **Compliance** owns activation readiness **calculation**.
- Readiness is a **deterministic signal** derived from configured requirements, document states, verification, expiration rules, and engagement status.
- **Manual override**, if introduced, must be permission-controlled, reason-coded, and audit-tracked—not the default MVP behavior.

**Follow-up:** Readiness rules backlog for Phase 2; glossary entry. **Document slice (TC-06):** readiness interpretation for configured document requirements lives in **`Documents::ReadinessEvaluator`** per [`../domain/documents-compliance.md`](../domain/documents-compliance.md); full multi-domain activation rules remain Phase 2+. **Virtual document alerts (TC-07)** extend evaluator output (`Documents::ReadinessResult#alerts`); authoritative detail **[`document-alerts.md`](../domain/document-alerts.md)** — **TC-07-D01–D10**. **Document verification actions (TC-08)** mutate **`DocumentRecord`** through **`Documents::ReviewDocumentRecord`** only; authoritative detail **[`document-verification.md`](../domain/document-verification.md)** — **TC-08-D01–D07**.

---

### TC-07-D01 … TC-07-D10 — Document alerts presentation (TC-07)

**Status:** Accepted for TC-07 implementation  
**Tier:** 2  

**Decision (summary):** TC-07 is **read-time alert presentation only** atop **`Documents::ReadinessEvaluator`**: no **`document_alerts`** table (**D01**); severities (**D02**); expiring-soon chain (**D03**); no dismissal/waiver (**D04**); no outbound notifications/jobs (**D05**); alerts only for **`required`** requirements (**D06**); **`Documents::AlertMessageBuilder`** centralizes **`message`** (**D07**); default **`Date.current`** as **`as_of_date`** (**D08**); deterministic sort (**D09**); engagement **show** always evaluates; cross-engagement index defaults **non-terminal** (**D10**).

**Companion:** **[`domain/document-alerts.md`](../domain/document-alerts.md)**

---

### TC-08-D01 … TC-08-D07 — Document verification controls (TC-08)

**Status:** Accepted for TC-08 implementation  
**Tier:** 2  

**Decision (summary):** Keep **`verified_by_id`**, **`verified_on`**, **`verification_notes`** (**D01**) — rejects record reviewer + timestamp in the same columns. **`rejection_reason`** mandatory for **`rejected`** (**D02**). **`void`** uses **`status`** + notes only — no **`voided_by`** schema in MVP; durable void audit deferred (**D03**, **TC-30**). **Append-only corrections** — forbid **`rejected` → `submitted`** (**D04**). **Verifier gate** MVP = admin + agency scope; fine roles → **TC-29** (**D05**). **Worklist source** **`submitted`** records; optional **`DocumentType#verification_required`** column in queue (**D06**). **TC-08-D07:** **`DocumentRecord`** review status and review-only columns (**verifier IDs/dates**, **`rejection_reason`**, **`verification_notes`**) cannot change via generic **`document_records`** mass assignment (`create`/`update`); only **`Documents::ReviewDocumentRecord`** and explicit **`POST`** review endpoints.

**Companion:** **[`domain/document-verification.md`](../domain/document-verification.md)**

---

### TC-09-D01 … TC-09-D08 — Contractor classification support (TC-09)

**Status:** Accepted for TC-09 documentation and Phase 2 alignment  
**Tier:** 2  

**Decision (summary):**

| ID | Decision |
| --- | --- |
| **TC-09-D01** | TC-09 is a contractor-focused **compliance-support lens** over **`Documents::ReadinessEvaluator`** / TC-07 alerts / TC-08 verification — **not** a parallel compliance engine or new schema-heavy bounded context. |
| **TC-09-D02** | Surface aggregate UX as **“Classification support status”** (and supporting-documentation language). Do **not** imply legal conclusions (“legally compliant,” “properly classified,” “misclassified”). |
| **TC-09-D03** | Configure specificity with **`DocumentType.category`** (broad bucket) + **`DocumentType.code`** (agency-configured kind). Do **not** invent new **`DocumentType::CATEGORIES`** values unless product migrates the catalog. |
| **TC-09-D04** | **Related-only** subcontractors (**PartyRelationship** without **`subcontractor`** Engagement) have **no** engagement-driven evaluation. **Promoted** subcontractors evaluate through **`Engagement.relationship_type = subcontractor`** when requirements exist. |
| **TC-09-D05** | Full operational reporting stays **TC-12**. TC-09 **documents** report/filter intent and drill-through targets. |
| **TC-09-D06** | Reuse **`Documents::ReadinessEvaluator`** aggregate **`readiness_status`** (`ready`, `not_ready`, `warning`, `not_applicable`) and existing **`requirement_outcome`** vocabulary — **no** new readiness enums for “legal classification.” |
| **TC-09-D07** | **`contractor_organization`** engagements **may** receive contractor classification-support requirements (tax form, agreement, insurance, renewal, certification, classification-support documentation) **where configured** — same document stack as other contractor-class types unless product excludes by rule. |
| **TC-09-D08** | Requirements intended **only** for contractor-class engagements (**tax/W-9-style** and similar) **must not** use **`DocumentRequirement.relationship_type = any`** unless the document is **intentionally universal** (exceptional; not the default for contractor tax artifacts). |

**Companion:** **[`domain/contractor-classification-support.md`](../domain/contractor-classification-support.md)**

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
