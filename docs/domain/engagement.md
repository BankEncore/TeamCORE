# Engagement domain — TeamCORE

Modeling notes for **TC-03 — Engagement Lifecycle** ([GitHub epic #4](https://github.com/BankEncore/TeamCORE/issues/4)) and cross-reference **TC-04 — Engagement status semantics** ([`engagement-status.md`](engagement-status.md)). **TC-05** subcontractor relationship hub: [`subcontractor-relationships.md`](subcontractor-relationships.md). Glossary ([`../product/glossary.md`](../product/glossary.md)); decisions ([`../product/open-decisions.md`](../product/open-decisions.md) — **TC-03-D01…D10**, **TC-04-D01…D05**); identity substrate [`party-team-member.md`](party-team-member.md); TC-01 placement/supervision concepts [`organization.md`](organization.md); applicability matrix [`employee-contractor-applicability-matrix.md`](../product/employee-contractor-applicability-matrix.md).

**Spine:** `Party → TeamMember → Engagement(s)`. Engagement is **workflow authority** for employee vs contractor semantics and lifecycle (not Party or TeamMember). See **OD-001**, **OD-002**, **OD-003**.

---

## TC-04 — Status semantics (policy)

**Mechanism (TC-03)** — transitions, validators, placement, supervision — lives in **this** document. **Meanings** of `engagements.status` by `relationship_type`, workflow-effect matrices (documentation until later epics), reason-code vocabulary, Team360/reporting expectations, and audit posture are in **[`engagement-status.md`](engagement-status.md)**.

---

## Source-of-truth recap (TC-03 boundaries)

| Concept | TC-03 source | Implemented |
| --- | --- | --- |
| **Engagement** | `engagements` | Yes |
| **EngagementOrganizationPlacement** | `engagement_organization_placements` | Yes |
| **EngagementSupervisionAssignment** | `engagement_supervision_assignments` | Yes |
| **Documents / compliance** | Engagement consumers | No — future |
| **Compensation / settlement** | Engagement consumers | No — future |
| **Team360 UI** | Read paths only (requirements in this doc § Team360) | No — TC-10 |
| **Operational reports** | Engagement + placement dimensions | No — TC-12 |
| **Full RBAC / durable audit ledger** | Policy TC-29/TC-30 | No |

---

## Implementation-lock decisions

Formal register summaries: **`open-decisions.md`** (**TC-03-D01…D10**, **TC-04-D01…D05**). This section mirrors the authoritative rules for migrations and validators; **TC-04** semantics and consumer contract are summarized in **`engagement-status.md`**.

### Index

| ID | Topic |
| --- | --- |
| **TC-03-D01** | Operational `relationship_type` (+ Party constraints) |
| **TC-03-D02** | Engagement status, transitions (**not** `LifecycleStatusable`) |
| **TC-03-D03** | One `active` engagement per type; concurrency note |
| **TC-03-D04** | Effective-dated placement |
| **TC-03-D05** | MVP supervision (`primary_reports_to`) |
| **TC-03-D06** | Subcontractor PartyRelationship vs Engagement |
| **TC-03-D07** | Business dates `*_on` |
| **TC-03-D08** | `pending` / activation (no OD-006 engine) |
| **TC-03-D09** | Correction / history |
| **TC-03-D10** | ADR vs domain doc |

### TC-03-D01 — `relationship_type`

Persisted enum: **`employee`**, **`individual_contractor`**, **`contractor_organization`**, **`subcontractor`**. Refines **OD-003’s** roadmap “employee \| contractor” into operational types without changing “status belongs on Engagement.”

| `relationship_type` | Required Party `party_type` |
| --- | --- |
| `employee` | `person` |
| `individual_contractor` | `person` |
| `contractor_organization` | `organization` |
| `subcontractor` | `person` or `organization` |

---

### TC-03-D02 — Status and MVP transitions

**Statuses:** `draft`, `pending`, `active`, `suspended`, `ended`, `terminated`, `cancelled`. Do **not** reuse **`LifecycleStatusable`** vocab for Engagement business lifecycle.

Default on create: `draft`.

**MVP transitions (when `status` changes on an existing row):**

- `draft` → `pending` | `cancelled`
- `pending` → `active` | `cancelled`
- `active` → `suspended` | `ended` | `terminated`
- `suspended` → `active` | `ended` | `terminated`

Terminal statuses (`ended`, `terminated`, `cancelled`) have no forward transitions in MVP. Other paths require explicit future product/sign-off.

**Transition enforcement:** Model validates inclusion and **D07** dates; validates allowed transitions when `status_changed?` after persist. Seeds may create rows in any allowed status **on first insert** without a prior status.

**Suspended:** Operational eligibility changes; engagement **may retain** current placement and supervision edges — do not auto-delete them (**D04**, **D05**).

---

### TC-03-D03 — Active cardinality

At most **one** engagement per `(agency_id, team_member_id, relationship_type)` with **`status = active`**. Defined by **status string only** in MVP — not mixed with date math.

Enforced in **application validation + tests**. **Not** concurrency-proof vs parallel requests; revisit DB constraints or locking under contention.

**Simultaneous types:** Allowed to have active **employee** and active **individual_contractor** (different `relationship_type`) — **administrative exception** posture; **OD-002**.

---

### TC-03-D04 — Placement

`engagement_organization_placements`: `agency_id`, `engagement_id`, optional `department_id` / `location_id` / `team_id`, required `effective_start_on`, optional `effective_end_on`, optional `notes`.

- `draft`: placement optional.
- `active`: **expect** one current placement; transition guard deferred until policy locks.
- `suspended`: may keep current placements.

**Inclusive overlap:** Two placements on the **same** `engagement_id` overlap if they share ≥1 calendar day. Use:

```text
NOT ( (e₁ present AND s₂ > e₁) OR (e₂ present AND s₁ > e₂) )
```

with `effective_end_*` nullable meaning “open.” **Back-to-back** handoff ends one interval the day **before** the next starts under inclusive rules (example: Old `… 2026-05-31`, New `2026-06-01 …`).

**Org targets:** Historical FK to inactive/archived org rows OK. **New** rows default to **`active`** org fixtures only (**TC-01** statuses).

See [`organization.md`](organization.md) for display precedence (placement vs Team fallbacks).

---

### TC-03-D05 — Supervision

`engagement_supervision_assignments`: `agency_id`, `engagement_id` (supervisee), `supervisor_engagement_id`, **`relationship_type` = `primary_reports_to`** in MVP.

- Supervisor engagement: **`status = active`**; **`relationship_type`** must **`not`** be **`contractor_organization`** in MVP (org must not supervise). Normal case: **`employee`** supervisor.
- No self-edge. At most **one current** `primary_reports_to` per supervisee engagement (overlap rule same inclusive pattern as placements).
- `suspended` supervisee may keep supervision edges.

Directed cycle detection beyond self-edge:** deferred.

---

### TC-03-D06 — Subcontractor

Only **`PartyRelationship`:** association visibility, no Engagement.

**Promoted (`TeamMember` + Engagement `relationship_type = subcontractor`):** direct workforce workflows — **OD-004**. Engagement is workflow authority; relationship row may remain for context.

---

### TC-03-D07 — Business dates (`engagements`)

| Status | `start_on` | `end_on` |
| --- | --- | --- |
| `draft` | optional | **null** |
| `pending` | optional | **null** |
| `active` | **required** | **null** |
| `suspended` | **required** | **null** |
| `ended` | **required** | **required** |
| `terminated` | **required** | **required** |
| `cancelled` | optional | optional (normally **null**) |

`expected_end_on` optional when present must be ≥ `start_on`; `renewal_on` optional.

**Renewal / expiry semantics (TC-03.04):** `expected_end_on` and `renewal_on` are **shared, optional** planning fields on **every** `relationship_type`—most often used to express **contract or agreement horizon** and **renewal review** for contractor-style engagements, but not restricted to them. They are **informational in TC-03**: no automatic status changes, renewals, alerts, or charge/settlement behavior; those stay in later product (e.g. contractor charges, compliance, reporting). Actual **legal or economic end** of the relationship in MVP is still expressed through **`status`** plus **`start_on` / `end_on`** per the table above (and placement/supervision effective dating on child rows).

---

### TC-03-D08 — Activation

**`pending`:** Intended to proceed, not yet `active`; may reflect future readiness without implementing **OD-006** engines.

Gate **`pending → active`** minimally: TM identity (**TC-02**); valid `relationship_type`; `start_on` present; no duplicate **`active`** for same tuple (**D03**). Documents/compliance not required in TC-03.

---

### TC-03-D09 — Correction

Engagement lifecycle on parent row; placement/supervision history via **new effective-dated** child rows. No `engagement_versions` table; durable audit — **TC-30**.

---

### TC-03-D10 — ADR

Standalone ADR not required unless architecture diverges materially from OD-001/003; domain doc + `open-decisions` index suffice for Phase 1.

---

## Same-agency integrity (tests)

- **`Engagements`:** `engagement.agency_id == team_member.agency_id`.
- **Placement:** `placement.agency_id == engagement.agency_id`; each non-null dept/location/team shares that **`agency_id`**.
- **Supervision:** Assignment `agency_id` matches both supervised and supervisor engagements.

---

## Team360 engagement panel (#81) — requirements only

Read surfaces for the **Engagement / workforce** narrative (delivery **TC-10**): `relationship_type`, `status`, `title`, business dates, current placement (dept/loc/team labels), supervisor identity via **`supervisor_engagement_id`** resolved to supervisor **Party** / **Team Member** `display_name` (**TC-02** identifiers); subcontractor linkage from **`PartyRelationship`** when no promoted engagement exists.

### TC-03.10 — Field list, placement, supervisor, applicability

| Need | Where it is specified |
| --- | --- |
| **Organization / placement strip** (Department, Location, Team, Supervisor, operational vs org-row status badges) | **[`organization.md` § Team360 organization context fields (acceptance — listed)](organization.md#team360-organization-context-fields-acceptance--listed)** under **[Team360 and operational reporting (TC-01.10)](organization.md#team360-and-operational-reporting-tc-0110)** |
| **Explicit placement vs team roll-up** (department/location precedence) | **[`organization.md` § Team (TC-01.04) — Recommended precedence](organization.md#team-tc-0104)** (Team360 department/location strip) |
| **Supervisor labeling** | Same **Team360 organization context** table — **`EngagementSupervisionAssignment`** → supervisor **`Engagement`** → identity |
| **Employee vs contractor display** | **Spine:** `relationship_type` + engagement status (**this doc**, **TC-03-D01/D02**). **Capability differences** (panels, payroll vs settlement, time/leave, etc.): **[`employee-contractor-applicability-matrix.md`](../product/employee-contractor-applicability-matrix.md)** and **[`domain-map.md` § Team360](../product/domain-map.md#team360)** — execution is **Phase 3+**, not TC-03. |

### TC-03.10 — Epic dependencies (**TC-10**, **TC-11**)

| Epic | Role |
| --- | --- |
| **TC-10** | **Team360 MVP shell** embedding org placement + supervisor read paths powered by **`engagements`** / **`EngagementOrganizationPlacement`** / **`EngagementSupervisionAssignment`**. Dependency table: **[`organization.md` § Dependencies](organization.md#dependencies-acceptance--tc-10-tc-12-explicitly)**. |
| **TC-11** | **Not** assigned a numbered section elsewhere in repo markdown yet. **TC-03 UX** assumes **adjacent Phase 3** work alongside Team360/reporting (**[`domain-map.md` — Phase 3 — Team360 MVP and Operational Reporting](../product/domain-map.md#phase-3--team360-mvp-and-operational-reporting)**). When program management pins **TC-11** on GitHub, add a row here linking that epic explicitly. |

---

## Reporting (#82) — requirements only

**Spine dimensions (authoritative aggregates):** agency, TM, `relationship_type`, `status`, placement keys, **`as-of`** placement/supervision via effective intervals (**TC-03-D04**, **D05**).

### TC-03.11 — Filters, exceptions, drill-through, **TC-12**

| Need | Cross-link |
| --- | --- |
| **Operational reporting filters** (department, location, team, supervisor, org lifecycle / “include deactivated”, etc.) | **[`organization.md` § Operational reporting filters (acceptance — listed)](organization.md#operational-reporting-filters-acceptance--listed)** |
| **Operational exception lists** (e.g. inactive placement audits, deactivated-org exception paths) | Described alongside **filters** (org lifecycle facet) and **drill-through** table rows — same **[Team360 and operational reporting (TC-01.10)](organization.md#team360-and-operational-reporting-tc-0110)** section |
| **Drill-through targets** (report row → engagement / Team360; supervisor cell; aggregate → filtered / exception dashboards) | **[`organization.md` § Drill-through expectations (acceptance)](organization.md#drill-through-expectations-acceptance)** |
| **`TC-12` dependency** | States **TC-12** owns list UX / combined filters / exact exception-dashboard behavior — see **[§ Dependencies (`TC-12` row)](organization.md#dependencies-acceptance--tc-10-tc-12-explicitly)** |

---

## Audit / permission note (#83)

**TC-03.12:** sensitive **Engagement** and child-table actions SHOULD align with **`OD-009`** (provisional → Phase 6) and emit **immutable audit artifacts** (**`TC-30`**) when that platform exists.

### Engagement-scoped sensitive actions (list)

These extend org-foundation risks defined in **`organization.md`** and map to **`TC-03` persistence**:

- Create / update / delete **Engagement** (agency, **`relationship_type`**, **`status`**, titles, business dates).
- **`status` / `relationship_type` mutations** once persisted (workflow and applicability implications).
- **Placement mutations** (`EngagementOrganizationPlacement`) — prefer **effective-dated new rows** for corrections (**TC-03-D09**).
- **Supervision mutations** (`EngagementSupervisionAssignment`).
- **Archiving / terminal transitions** (`ended`, `terminated`, `cancelled`) and any future override of **`inactive`/archived org** picks for assignments.

### TC-03.12 — Cross-references (**TC-29**, **TC-30**)

| Topic | Cross-link |
| --- | --- |
| **Org + supervision + placement** risk tables and expectation matrices | **`organization.md` — [Audit and permission impact note (TC-01.12)](organization.md#audit-and-permission-impact-note-tc-0112)** — [Sensitive organization actions](organization.md#sensitive-organization-actions-acceptance--listed); [Audit expectations](organization.md#audit-expectations-acceptance--documented); [Permission expectations](organization.md#permission-expectations-acceptance--documented); [Phase 6 dependencies (`TC-29`, `TC-30`)](organization.md#phase-6-hardening-dependencies-acceptance--noted). |
| **Engagement-centric audit backlog** | **`open-decisions.md` — [`OD-010` — Audit depth (policy direction)](../product/open-decisions.md#od-010--audit-depth-policy-direction)** (covers engagement lifecycle among MVP audit expectations). |
| **Correction posture (append-only history)** | **TC-03-D09** (this doc) — durable audit **`TC-30`**. |

---

## TC-04+ handoff

Later epics read **`engagements`** and child tables as spine. **Forbidden on Engagement in MVP:** compensation IDs, document requirement IDs, settlement fields, readiness rule engines.

---

## Related

- **`organization.md`** — Placement/supervision concepts (TC-03 persistence).
- **`party-team-member.md`** — Identity; TC-03 handoff from TC-02.
- GitHub epic **#4**, issues **#72–#84**.
