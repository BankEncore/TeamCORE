# Organization domain — TeamCORE

Modeling notes for **TC-01 Organization Foundation**. Authoritative glossary terms live in [`../product/glossary.md`](../product/glossary.md); decision register entries in [`../product/open-decisions.md`](../product/open-decisions.md); schema choice in **[ADR-0001](../adr/adr-0001-agency-organization-schema.md)**.

### Source of truth recap (TC-01 boundaries)

Quick map of **who owns authoritative data today** versus **later epics**:

| Concept | TC-01 source of truth | Implemented now? |
| --- | --- | --- |
| **Agency** | `agencies` | Yes |
| **Department** | `departments` | Yes |
| **Location** | `locations` | Yes |
| **Team** | `teams` | Yes |
| **Engagement placement** | Planned `EngagementOrganizationPlacement` (or equivalent) | No — **TC-03** |
| **Supervision / reporting line** | Planned `EngagementSupervisionAssignment` (or equivalent) | No — **TC-03** |
| **Authority structure** | Future permissions / workflow configuration | No |
| **Team360 organization context** | Read model assembled from placements + engagements + supervision | No — **TC-10** (shell) |
| **Operational reporting** | **TC-12** report layers over the same authoritative rows | No — **TC-12** |
| **Audit events** | **TC-30** (and interim logging policy) | No |

---

## Concepts

### Agency vs organization (terminology)

- **Agency** — The Rails model (`Agency`) and product concept for the **top-level operating context**. All departments, locations, and teams belong to exactly one agency in TC-01.
- **Organization** — **Domain language only** for the agency’s internal structure (departments, locations, teams, placement, supervision, authority). TC-01 does **not** add an `organizations` table.

Concrete models in Phase 1: **`Agency`**, **`Department`**, **`Location`**, **`Team`** (see **`### Source of truth recap`**).

### Agency (TC-01 substrate — concrete model)

Persisted as **`Agency`** (`agencies` table): **`name`**, **`code`** (**globally unique**), **`status`**, timestamps (`agencies` has no `description` column in TC‑01). Same **`active` / `inactive` / `archived`** vocabulary as child org entities — § *Organization foundation lifecycle policy* (**including Agency archival caveat**).

**`code` stability:** **`agencies.code`** behaves as a **tenant-stable identifier** (`EXAMPLE`, `corp`, …). TC‑01 enforces uniqueness only; **`code`** should be **immutable after first external reference**; future admin UX SHOULD **permission-gate / audit** edits (same stance as **`Department.code`**, **global** scope).

### Department (TC-01.02)

Internal **functional grouping** within an agency (e.g. Sales, Accounting). Persisted as **`Department`** (`departments` table).

#### Fields (defined)

| Attribute | Requirement | Notes |
| --- | --- | --- |
| `agency_id` | Required | Every department belongs to exactly one **`Agency`**. |
| `name` | Required | Display label (“Sales”, “Accounting”). **Not required to be unique** within an agency unless a future policy adds that constraint (TC-01 allows duplicates by name across branches if coded differently). |
| `code` | Required | Stable **short identifier** unique **per agency** (`UNIQUE (agency_id, code)`). See **Naming & code rules** below. |
| `description` | Optional | Clarifying notes for admins only; not assumed for MVP UI surfaces. |
| `parent_department_id` | Optional | **MVP depth constraint (explicit):** TC-01 supports **only one level** of department nesting — a department may have **one** optional parent department, but **that parent must not itself have a parent**. Deeper trees are **deferred**. Parent must belong to the **same agency** (**ADR-0001** / **`Department`** validations). |
| `status` | Required (default **`active`**) | Shared lifecycle vocabulary: `active`, `inactive`, `archived` — see § *Organization foundation lifecycle policy*. |

#### MVP department hierarchy (explicit constraint)

TC-01 intentionally implements a **single parent hop** only: **`parent_department.parent_department_id` must be blank** whenever a department has a parent. This is a **planned MVP limitation**, not an accidental omission of arbitrary-depth org trees — multi-level hierarchies remain a **later** product/epic decision.

#### Lifecycle / status

Departments share the organization foundation lifecycle: **`active`** (normal use and selectable for defaults), **`inactive`** (historical retention; not offered as normal default without override policy), **`archived`** (retired; **no new** assignments; UI read semantics later). TC-01 provides model validations, **`active`** scope, and DB default **`active`**; assignment blocking awaits **TC-03** placements and downstream UI (**TC-10** / **TC-12** / **TC-29**).

#### Engagement placement use

Department is an optional FK on **`EngagementOrganizationPlacement`** (conceptual specification in § *Engagement placement*). Placement is **anchored on the engagement** so the same person can differ **by engagement** over time (**TC-03**).

#### Reporting filter use

**Department** is a planned **Operational Reporting** and roster dimension: filter/group by **`departments.code`/`name`** and by department **`status`** (include/exclude **`inactive`** / **`archived`** per report contract). Depends on **`TC-12`** once reporting exists; aligns with glossary “operational filtering” for departments ([`glossary.md`](../product/glossary.md)).

#### Naming & code rules (documented product rules)

| Rule | Guidance |
| --- | --- |
| **`code` uniqueness** | **Unique within the agency.** Same code may exist **across agencies** only if separate agencies exist in deployment (later multi-agency tooling). |
| **`code` stability** | **`code`** values are **stable identifiers** beyond display labels — treat as **immutable in normal operations** once referenced externally (integrations, exports, seeded tutorials). TC‑01 validates **uniqueness** only; it does **not** enforce DB-level immutability. Future admin UI SHOULD **discourage** edits and SHOULD **permission-gate / audit** any **`code`** change after first reference (**`§ Admin UX requirements (TC-01.09)`**). |
| **`code` format** | **Not enforced by validation in TC-01.** Convention: **`[a-z0-9_]+`** or lowercase kebab/snake alphanumeric for imports, integrations, URLs, and report keys; avoid spaces—use **`name`** for human labels. Agencies may impose stricter norms in admin docs. |
| **`name` casing** | Prefer title case or agency standard; **not enforced** in TC-01. Trim leading/trailing whitespace when UX exists. |
| **Parent linkage** | Child remains identified by **`code`**, not by parent **`name`**; **`code`** is the stable report key alongside `id`. |

### Location (TC-01.03)

Physical or operational place where workforce activity is anchored for **placement**, **reporting**, and future rules (documents, geo, time—downstream phases). Persisted as **`Location`** (`locations` table).

#### Fields (defined)

| Attribute | Requirement | Notes |
| --- | --- | --- |
| `agency_id` | Required | Every location belongs to exactly one **`Agency`**. |
| `name` | Required | Human label (“Detroit Office”, “Remote”). **Uniqueness of `name` not enforced** in TC-01 (same rationale as **`Department`**). |
| `code` | Required | Stable **short identifier**, **unique per agency** (`UNIQUE (agency_id, code)`). Follow **`### Department`** *Naming & code rules* **including** **`code` stability**. |
| `location_type` | Required | One of **`office`**, **`branch`**, **`remote`**, **`virtual`**, **`client_site`**, **`other`** — validated in Rails (`LOCATION_TYPES` — **ADR-0001** / **`Location` model**). |
| `description` | Optional | Free-form admin/context text. **May** temporarily hold prose “address” hints until **`display_address`** exists—**do not parse** descriptions as postal data in MVP. |
| `timezone` | Optional (`NULL` allowed) | IANA TZ name when helpful (e.g. primary office TZ). **Generally unset** where type is **`remote`** and individuals vary; product rules in **Phase 5+** (`overview`, **`mvp-scope`**) supersede coarse location TZ for statutory payroll/geography (**not modeled in TC-01**). |
| `status` | Required (default **`active`**) | `active`, `inactive`, `archived` — see § *Organization foundation lifecycle policy*. |

#### Address posture (MVP / TC-01 vs later scope)

Scoped issue text allows “**Address, if needed for MVP**.” **Chosen posture for Phase 1 / TC-01:**

| Concern | TC-01 |
| --- | --- |
| **Structured address** (country/street/geocoding/tax locality) | **Not modeled** — deferred until payroll/compliance/geo reporting mandates it (document with **`display_address`** and/or richer schema later; see § *Organization foundation lifecycle policy* **`display_address` note`). |
| **Human-readable postal label** | **`display_address` column deliberately omitted** until **TC-10/TC-12** shells or downstream compliance spikes require it (**ADR-0001** alignment). Until then **`description`** carries **informal narrative only**. |

#### Location types (rules documented)

Rails **reject** unknown types; authoritative allow-list:

```
office branch remote virtual client_site other
```

| `location_type` | Intended semantics (product vocabulary) |
| --- | --- |
| **`office`** | Primary agency office or identifiable floor/unit (physical HQ). Often has a **`timezone`** for corporate reference. |
| **`branch`** | Secondary physical site — branch storefront, satellite office. |
| **`remote`** | **Distributed / no bricks address** workload bucket (employees or contractors assigned to **“Remote”** as operational place—not a postal address substitution). TZ often **unset** unless agency standard applies. |
| **`virtual`** | **Non-geographic operational label** — e.g. virtual team pool, online-only service center, or program bucket **distinct from** **Remote** WFH when the agency uses both concepts. If an agency does not distinguish them, treat **`virtual`** as alias for distributed operations and document in admin runbooks. |
| **`client_site`** | Work performed primarily **at a client** or third-party site (physical client engagement). |
| **`other`** | Escape hatch; document meaning in **`description`** or admin policy. |

#### Remote and virtual handling (acceptance)

- **Both** are **first-class `location_type` values** and **valid placement targets** on **`EngagementOrganizationPlacement`** when TC-03 ships.
- **Neither** implies **payroll tax jurisdiction** or **legal work-site determination** in TC-01—those are **Phase 5** payroll-input / configuration concerns unless a future compliance epic adds structured geo.
- **Teams** may reference **`remote`** / **`virtual`** locations for routing and reporting the same as **`office`** (**`Team#location_id`** — already allowed in schema).
- **Seeds** may include generic **“Remote”** and **“Virtual”** rows (see **`db/seeds.rb`**) as non-company-specific examples.

#### Lifecycle / status

Same organization foundation lifecycle as **`Department`** — see § *Organization foundation lifecycle policy*.

#### Engagement placement use

Optional **`location_id`** on **`EngagementOrganizationPlacement`** (§ *Engagement placement*). Same-agency rule applies.

#### Reporting filter use

**Location** is a planned **Operational Reporting** dimension: filter/group by **`code`**, **`name`**, **`location_type`**, and **`status`**. **TC-12** dependency; **inactive/archived** inclusion is per report contract (see **`Department`** *Reporting filter use* pattern).

### Team (TC-01.04)

Working group or operational unit under an agency (may align to a department / location footprint or stay “floating”). Persisted as **`Team`** (`teams` table).

#### Fields (defined)

| Attribute | Requirement | Notes |
| --- | --- | --- |
| `agency_id` | Required | Every team belongs to exactly one **`Agency`**. |
| `name` | Required | Display label (**“Corporate Travel Team”**, **“Commission Review Team”**, …). **`name`** uniqueness **not enforced** in TC-01 (same posture as **`Department`** / **`Location`**). |
| `code` | Required | Stable **short identifier**, **unique per agency** (`UNIQUE (agency_id, code)`). Follow **`### Department`** *Naming & code rules* **including** **`code` stability**. |
| `description` | Optional | Internal admin notes only until richer UX exists. |
| `department_id` | Optional (`NULL` allowed) | **See below** — *Team ↔ Department*. |
| `location_id` | Optional (`NULL` allowed) | **See below** — *Team ↔ Location* (**implemented in TC-01**, **not deferred**). |
| `team_lead` / **supervisor reference** | **Not present in TC-01 schema** | **Explicitly deferred** — see *Team lead (deferred)*. |
| `status` | Required (default **`active`**) | Lifecycle uses **`active`**, **`inactive`**, and **`archived`** (**ADR-0001** / shared org policy). Issue wording “active/inactive” is satisfied; **`archived`** adds an explicit retirement state for teams that must not receive new defaults. |

#### Team ↔ Department relationship (defined)

- **`Team` `belongs_to :department, optional: true`**: a team **may** anchor to one **home department** for admin, reporting roll-ups, and permission scoping ideas later.
- **Same-agency rule:** if **`department_id`** is set, the department’s **`agency_id`** **must match** the team’s **`agency_id`** (Rails validation in **`Team`**).
- A team **without** a department remains valid (“floating” / cross-functional team) — product choice, not a schema error.

#### Team ↔ Location relationship (defined — not deferred)

- **`Team` `belongs_to :location, optional: true`**: optional **operational site** or **location bucket** (e.g. **Main Office**, **Remote**) for the team.
- **Same-agency rule:** if **`location_id`** is set, the location must belong to the same agency (**`Team`** model validation).
- **Not deferred:** relationship exists in **`db/schema.rb`** today; **`TC-03`** consumes it for roster/placement/read models.

#### Team lead / supervisor reference (scope item — consciously deferred)

Original scope allowed an **optional team lead**. **Chosen posture (aligned with **ADR-0001** and § *Reporting line (TC-01.05)*):**

- **No **`team_lead_id`**, `team_lead_engagement_id`, or similar on `teams` in TC-01.** Supervision belongs on the **Engagement** via **`EngagementSupervisionAssignment`** so supervisors are **not conflated** with org **`Team`** records and remain correct when placement differs across engagements (**TC-03**).
- **Future enhancement (post TC-03, if needed):** optional **`team`** “default liaison” linkage could be reconsidered—but it is **out of TC-01** acceptance.

Issue AC **“defined or deferred”**: **defer team-level lead FK**; define **replacement pattern** (**engagement-scoped supervisor**).

#### Engagement placement use

Optional **`team_id`** on **`EngagementOrganizationPlacement`** (§ *Engagement placement*) with same **`Agency`** integrity as department/location. **TC-03** owns persistence & validation.

#### Team360 organization context (acceptance — requirements for TC-10)

The **`Team`** is a **first-class row** in the **organization context panel** for a team member / engagement once **TC-10** Team360 shell exists. **TC-01** delivers **data + definitions**; **UI** ships later.

**Expected panel inputs (read model, not source of truth):**

| Display | Source (once wired) |
| --- | --- |
| **Team name** | **`teams.name`** (from engagement **placement** `team_id` or equivalent read path) |
| **Team code** | **`teams.code`** (for support / internal labels) |
| **Department (context)** | **`departments.name`** via **`EngagementOrganizationPlacement.department_id`** when set; otherwise **fallback** to **`teams.department_id`** resolved through placement’s **`team_id`**. See **Recommended precedence** below. |
| **Location (context)** | **`locations.name`** via **`EngagementOrganizationPlacement.location_id`** when set; otherwise **fallback** to **`teams.location_id`** via the same team linkage. Same **recommended precedence**. |
| **Supervisor** | **Not** from **`Team`** — from **`EngagementSupervisionAssignment`** (**TC-03**). |
| **Org lifecycle** | **`teams.status`** (and placement row / engagement state as applicable) |

**Recommended precedence (Team360 department / location):** **explicit engagement placement** values **override** **`Team`** department/location roll-up. Use **`teams.department_id` / `teams.location_id`** **only as fallback** when the placement omits department or location. This avoids contradictory **`Department`** vs **`Team`** messaging in panels; **TC-03** authoring policy SHOULD keep data aligned when both paths are populated.

**Dependencies:** **TC-10** (Team360 MVP shell), **TC-03** (placement + supervision data), **TC-29** (permission-aware panels later).

#### Lifecycle / status

Same **organization foundation lifecycle** as **`Department`** / **`Location`** — § *Organization foundation lifecycle policy*.

### Engagement placement (TC-01.07 — documented — implemented in TC-03)

Placement answers **where does this engagement sit** in internal structure (**who / where dimension**), complementary to supervision (**who supervises** — see § *Reporting line (TC-01.05)*).

#### Engagement placement fields (identified)

Roadmap-aligned references an engagement **may** use (conceptual—not persisted in TC-01):

| Field | Persistence pattern (planned) |
| --- | --- |
| **Agency** | Carried on **`Engagement`** itself (`agency_id` or equivalent) as the implied operating context; org rows (department, location, team) already belong to that agency. |
| **Department** | Optional FK on **`EngagementOrganizationPlacement`** (or equivalent), subject to same-agency validation. |
| **Location** | Optional FK on placement record. |
| **Team** | Optional FK on placement record. |
| **Supervisor** | **Not** a free-text column on placement; expressed via **`EngagementSupervisionAssignment`** (supervisor points at another **Engagement** or approved future pattern) so the supervisor is a first-class workforce context, not a label. |

#### Conceptual record (future): `EngagementOrganizationPlacement`

- `engagement_id` (FK when **Engagements** exist)
- `department_id`, `location_id`, `team_id` (optional at schema level; **requiredness** is product rule — see below)
- `effective_start_date` (required); `effective_end_date` optional
- Agency consistency: department, location, and team must belong to the engagement’s agency when present

#### Required vs optional placement rules (TC-01 definition)

TC-01 **defines the rule space**; **TC-03** **locks** concrete required/optional validation per agency policy and engagement type.

- **Schema-level default (recommended):** allow **department**, **location**, and **team** to be **nullable** so agencies can onboard engagements before org structure is complete, or differentiate requiredness by workflow.
- **Product rules (examples of what TC-03 may enforce):**
  - An agency policy may **require department + location** for **active employment** placements but permit looser drafts while **pending/onboarding**.
  - **Team** may remain optional globally or required only for certain programs—**configured or decided in TC-03**, not in TC-01.
- **`active`, `inactive`, `archived` org rows:** new assignments should prefer **`.active`** org fixtures (see § *Organization foundation lifecycle policy*); exceptions (rehire to historical team, override) are **explicit policy + audit** work, not TC-01.

#### Employee vs contractor placement differences (documented)

The **same placement field set** applies to **both** engagement relationship types (**employee** and **contractor**): applicability matrix confirms **Organization placement → Yes / Yes** for both ([`employee-contractor-applicability-matrix.md`](../product/employee-contractor-applicability-matrix.md)).

**Differences are in downstream consumption**, not necessarily different columns:

| Dimension | Typical employee emphasis | Typical contractor emphasis |
| --- | --- | --- |
| **Payroll / locality** | Department/location/tax-geography hooks may tie to payroll input and reporting (**Phase 5**) | Usually irrelevant to payroll rails; contractor uses **settlement** rail instead |
| **Time / leave** | Location/department may gate self-service or approval routing (**employee-only MVP time/leave**) | Not on employee time rails in MVP (`overview`, `mvp-scope`) |
| **Charges / settlement** | N/A | Department/team may drive **routing** for commission/support or operational ownership—not charge math itself (**Phase 4+**) |

TC-03 should document any **explicit** “required for contractor but not employee” (or inverse) rules when engagement lifecycle and forms are designed.

#### Historical placement concerns (identified)

- **Effective dating:** preserve **history** with `effective_start_date` / `effective_end_date` (or successor pattern); do not **silently overwrite** placement as if it always applied.
- **Reporting “as-of”:** operational reports and Team360 may need **point-in-time** placement (use row effective for the date in question).
- **Corrections:** wrong placement is corrected by **new effective-dated row** or controlled correction workflow—with **audit** expectation (**TC-30**), not ad hoc mutation of past facts.
- **Inactive/archived targets:** engagements may **remain** tied to historically valid org IDs for audit truth; UX should clarify **inactive** placements vs forbidding silent **new** assignments to stale org rows.

#### TC-03 Engagement Lifecycle dependency (explicit)

- **Persisted** **`engagements`** table and engagement lifecycle **must exist before** FK-backed **`EngagementOrganizationPlacement`** and **`EngagementSupervisionAssignment`** can ship.
- **TC-03** owns: validation matrices (required fields by status/type), onboarding vs active rules, UX for placement/supervisor, and integration with **TC-02** Party/Team Member.
- TC-01 deliverable for **TC-01.07** stops at **this specification** plus **ADR-0001** org substrate (`Agency`, `Department`, `Location`, `Team`).

### Reporting line (TC-01.05 — documentation only; persistence in TC-03)

#### Purpose and MVP posture (recommended approach)

TeamCORE models **reporting lines / supervisory relationships** on the **Engagement**, not as a single static row on **Team Member** alone.

**Why:** the same person may have **different supervisors** across **different engagements** (employee vs contractor, concurrent allowed exceptional cases, or sequential roles) and **over time** as assignments change.

**TC-01** defines **product rules and planned shape**; **TC-03** implements tables, validations, and UX.

#### Reporting line ownership (acceptance)

| Layer | Owner |
| --- | --- |
| **Product / domain** | **Organization** domain describes reporting-line **semantics**; **Engagement** domain will **own persisted** supervision rows (**TC-03**). |
| **Authoritative link** | Each **supervision relationship** references the **supervised engagement** (`engagement_id` or equivalent on the conceptual assignment row). |
| **Not authoritative** | Org **`Team`** “team lead” FK (**omitted in TC-01**), implied manager on **Party**, or implicit **Team Member**-only graph—those do **not** replace engagement-scoped supervision. |

#### Conceptual record (future): `EngagementSupervisionAssignment`

Planned attributes (names indicative; **TC-03** may adjust column names):

| Field | Role |
| --- | --- |
| `engagement_id` | **Required.** The engagement being supervised (the “subordinate” workforce context for this relationship). |
| `supervisor_engagement_id` (or approved successor) | **Required** for a concrete assignment—points at the supervisor’s **Engagement** (or future pattern tying to an active manager engagement) so the supervisor is a **first-class** workforce participant, not a display string. |
| `relationship_type` | **Reporting / supervision flavor** — e.g. `primary_reports_to`, `dotted_line`, `interim`, `matrix_secondary` — **enum to be finalized in TC-03**; supports multiple concurrent edges if product allows. |
| `effective_start_date` | **Required** when historical accuracy matters; defines when this edge becomes true. |
| `effective_end_date` | Optional; **nullable** means “open-ended / current”. **Revocation** prefers setting end date over hard delete (see **Historical behavior**). |
| **Agency consistency** | Supervisee and supervisor engagements must belong to the **same Agency** tenant context (**TC-03** validation). |

**No** physical table ships in **TC-01**.

#### Supervisor assignment rules (acceptance — product rules for TC-03 to enforce)

- **Anchor:** every assignment ties to **one supervised `engagement_id`**; optional **multiple active edges** only if **TC-03** explicitly allows (e.g. matrix) and UI/reporting can disambiguate **`relationship_type`**.
- **Supervisor identity:** resolve via **`supervisor_engagement_id`** (or successor) — **not** free-text name fields on the supervised engagement.
- **Eligibility (to be detailed in TC-03):** e.g. supervisor engagement **status** must be suitable (typically **active** employments for manager paths); **contractor** supervises **contractor** vs **employee** supervises **employee** policy—**employee vs contractor matrix** may restrict certain edges; **OD-002** / engagement-type rules apply.
- **Org dimensions:** **Department / Location / Team** on **placement** may **inform** default supervisor suggestions in UX but **do not** automatically create a reporting line without an explicit assignment row.
- **Lifecycle:** changing managers **adds** a new effective-dated row (or equivalent) rather than rewriting history in place.

#### Relationship to engagement (acceptance)

- **Primary join:** `EngagementSupervisionAssignment.engagement_id` → **supervised** engagement.
- **Supervisor side:** supervisor is **another Engagement** (`supervisor_engagement_id`), keeping Party/Team Member resolution on the **existing** engagement spine (**TC-02** + **TC-03**).
- **Distinction from placement:** **`EngagementOrganizationPlacement`** answers **where**; supervision answers **who manages this engagement** — both may be shown in **Team360** but are **different** concepts (see **`### Team`** *Team360* and § *Engagement placement*).

#### Historical behavior (acceptance)

- **Truth over time:** retain **past** supervisors using **effective dating**; reports and **Team360** “as-of” views pick the edge valid for a date.
- **No silent overwrite:** do not **mutate** a historical row to pretend an earlier supervisor never existed; corrections use **new rows** or controlled admin correction with **audit** (**TC-30**).
- **Revocation / end:** set **`effective_end_date`** (or close equivalent) instead of deleting rows needed for audit or prior-period reporting.
- **Inactive engagements:** ended engagements may still **appear** in historical supervision chains for compliance or narrative views—**TC-03** defines read rules.

#### Future approval routing implications (acceptance)

Reporting line is a **common default** for **routing** and **escalation** in HR-ish workflows but must **not** be equated with **approval authority** (see **§ Authority structure (TC-01.06)**):

| Implication | Notes |
| --- | --- |
| **Default approver suggestions** | Time, leave, expenses, onboarding steps **may default** to **primary** reporting-line supervisor **when** workflow config says so (**Phase 5+** time/leave; **TC-03+** lifecycle). |
| **Override / alternate approver** | **Authority**, **role**, **delegate**, or **queue** may **replace** reporting-line routing—especially for **payroll/settlement**, **waivers**, or **SOX-style** separation of duties. |
| **Matrix / dotted-line** | Secondary edges may **inform CC/visibility** more than **hard approval** unless configured. |
| **Implementation home** | Executable routing lives in **workflow / permissions** epics—not **TC-01**; **TC-01** only flags the dependency so **TC-03** exposure of reporting lines can feed those engines later. |

#### TC-01 boundary (recap)

- **No** `engagements` table and **no** supervision **persistence** in TC-01.
- **No** assignment-blocking or workflow behavior until **TC-03** and downstream workflow owners ship.
- Reporting line is **Engagement-scoped**, not inferred from **`Team`** “team lead” or **Team Member** alone (see **`### Team (TC-01.04)`** *Team lead deferred*).

**Authority vs reporting line (see also § Authority structure below)**

These stay **distinct product concepts**:

| Concept | Question it answers |
| --- | --- |
| **Reporting line / supervision** | Who does this engagement **report to** for management, visibility, escalation, or day-to-day direction? Usually modeled alongside **placement** using engagement-scoped supervision (TC-03). |
| **Authority structure** | Who is **authorized** (by role, delegation, rule, or policy) to execute **controlled actions**: approve workflows, verify records, waive requirements, approve payroll/settlement batches, approve time or leave, override compliance/readiness gates? |

They **often correlate** but are **not the same**:

- The **manager in the reporting line** may approve timesheets **or** that approval may belong to payroll/HR depending on configured rules.
- A **designated operations or finance authority** may **waive a contractor charge** without being the supervisee’s line manager.

TC-01 records this boundary **only as documentation**. Neither reporting-line persistence nor executable authority rules ship in TC-01.

---

## Organization foundation lifecycle policy

This section satisfies **TC-01.08** (organization foundation lifecycle — **`Agency`**, **`Department`**, **`Location`**, **`Team`** — and availability for assignments) acceptance criteria **in documentation**; **enforceable assignment UX/API** gates are **TC-03** and later shells (**TC-10**, **TC-12**, **TC-29**, **TC-30**).

Organization foundation records use a shared lifecycle **status**:

- `active`
- `inactive`
- `archived`

### Active

Active records are available for normal use and may be selected for future assignments.

### Inactive

Inactive records are retained for history and reporting but should not be offered as default choices for new assignments.

Future assignment workflows should prevent inactive records from being selected unless an explicit override policy is defined.

### Archived

Archived records are retired historical records.

Archived records should not be available for new assignments. Future UI/API workflows should treat archived records as read-only except for narrowly authorized administrative correction workflows.

### Agency archival (single-agency MVP caveat)

Moving the **only **`Agency`** row** in a **single‑agency MVP** tenant to **`archived`** risks making workforce operations **effectively unavailable** for **new assignments** and may strand admin flows. **`Agency` → archived** SHOULD be treated as a **non-standard** action backed by **escalated permission + audit** (**TC‑30** expectation), **or blocked** unless a **replacement Agency** migration path exists. **`Agency` archival** semantics are exercised mainly when **multi‑agency**, **agency cloning**, or **sandbox** patterns exist—not day‑one MVP defaults.

### Deactivation rules (TC-01.08)

**“Deactivation”** in product language usually means moving a record off **`active`**. TeamCORE uses two non-active states:

| Transition | Meaning | Typical use |
| --- | --- | --- |
| → **`inactive`** | **Soft withdrawal** from normal selection. Record remains in the database for **history**, **reporting**, and **existing references** (e.g. engagement placement FKs). May return to **`active`** when product allows. |
| → **`archived`** | **Stronger retirement.** Treated as **read-only** for most users; **not** offered for **new** organizational assignments. Use when a department/location/team/agency unit is **closed** and should not re-enter operational rotation without an explicit admin process. |

**Directional guidance (not a state machine in TC-01):** prefer **`inactive`** first when sunsetting a unit; move to **`archived`** when the agency wants to **freeze** edits and **bar** new uses more strictly than **`inactive`**. Exact transition rules are **TC-03** (assignments) + **admin UX** + **audit** epics.

### Historical records (TC-01.08)

- **Immutability of facts:** past truth (what department a placement used last quarter) is **not erased** because the **`Department`** row later became **`inactive`** or **`archived`**.
- **Foreign keys:** engagement placement (**TC-03**) **may keep** **`department_id` / `location_id` / `team_id`** pointing at **`inactive`** or **`archived`** rows so historical views stay consistent.
- **Labels:** reporting and Team360 display **resolved names/codes** from those rows **even when** status is non-active (with UX cues optional in **TC-10**/**TC-12**).
- **Destruction:** avoid **hard delete** of org rows referenced by placements or audit-relevant facts; **`restrict_with_exception`** associations on **`Agency` → children** discourage orphaning; prefer **status** transitions.

### New assignment selection (TC-01.08)

**Product rule — default pickers (“new assignments”):**

| Status | selectable for **new** org placement defaults? |
| --- | --- |
| **`active`** | **Yes** (subject to TC-03 validation). |
| **`inactive`** | **No**, **unless** an **explicit override** path exists — policy-defined, permission-gated, and **audit-visible** (**TC-30** expectation). Overrides are **not** ad hoc edits. |
| **`archived`** | **No** for new assignments; **narrow admin correction** only (rare, documented, permissioned). |

**TC-01 code** supplies **valid statuses**, **defaults**, and **`.active`** scopes on org models; **enforcement in assignment UI/API** is **TC-03+** (stated in *TC-01 enforcement scope* below).

### Existing historical engagements (TC-01.08)

- Engagements and **effective-dated placement** rows (**TC-01.07**) that **already reference** a department, location, or team **remain valid** when that org record becomes **`inactive`** or **`archived`** — the relationship was **true in context** unless the business runs a controlled **migration** to a replacement org row (**TC-03** owns workflow).
- **`inactive` / `archived`** affects **whether new rows** **default-select** that org unit — **not** retroactive revocation of truthful history.

### TC-01 enforcement scope

TC-01 enforces lifecycle status values, default status, **`active`** scopes, and basic association consistency (same agency).

TC-01 does **not** implement engagement assignment enforcement, admin override workflows, audit events, or UI-level read-only behavior. Those behaviors are deferred until the relevant engagement, admin UI, permission, and audit workflows exist.

**Expectation:** TC-03 uses **`active`** scopes and these rules when building placement UX/API; TC-10/TC-12/TC-29/TC-30 further harden visibility, filtering, audit, and permissions.

**Display address**

- **`display_address`** for locations is **intentionally omitted** until **TC-10/TC-12** (Team360/reporting shells) unless compliance/payroll needs force earlier structured address modeling.

---

## Authority structure (TC-01.06 — concepts only, no authority engine)

This section satisfies **TC-01.06** acceptance criteria in documentation form: TC-01 **does not** build an authority engine, permission matrix, delegation model, or approval workflow runner.

### Definition

An **authority structure** (product term) is the set of rules and assignments that decide **whether a given actor may perform a protected action**—independent of **who they report to** for management purposes (**reporting line**). Over time this may tie to roles, delegated approvers, org dimensions (department, location, team), engagement type (employee vs contractor), and configurable workflow steps; **implementation is deferred.**

### Authority kinds scoped for later design (hooks)

These categories are intentionally **product vocabulary** TeamCORE workflows can attach to (`OD-009` provisional permissions; future ADR as needed—not locked in TC-01):

| Kind | Typical controlled actions |
| --- | --- |
| **Approval authority** | Approving lifecycle transitions, onboarding/rehire steps, discretionary exceptions where “approve” gates progress. |
| **Verification authority** | Marking documents or readiness items verified, releasing holds that depend on human verification. |
| **Waiver authority** | Waiving charges, penalties, recoverables, fee rules, or similar—generally narrower and higher risk than blanket edit rights. |
| **Payroll / settlement authority** | Submitting payroll inputs or settlement batches for processing, approving batch totals, approving corrections after export/import. |
| **Document / compliance authority** | Overriding readiness, granting exemptions where policy allows, or accepting alternate evidence—without substituting automated “legal determination.” |
| **Timesheet / leave approval authority** | Approving employee timesheets, rejecting or sending back for correction, approving leave requests per agency rules. |

### Reporting line vs authority structure boundary (TC-01.06 acceptance)

Same as § *Reporting line (TC-01.05)*: **reporting line = management/supervisory context** on an engagement or role; **authority = permission to act** on a protected operation. Epic **TC-03** is expected to own **supervision** persistence; epic **Phase 6** roadmap items (**TC-29**, **TC-30**, with **OD-009**/future permission ADRs) own **enforceable** authorization and audit on those actions—not TC-01.

### Future permission and approval hooks (identified, not implemented)

Downstream artifacts should reuse this vocabulary when attaching gates:

- **Role/action checks** (MVP default per `OD-009`) mapped to domain actions (approve, verify, waive, export, import, override).
- **Workflow step approvers** (when an approval engine exists) may reference **authority** without assuming it equals the **reporting line** assignee.
- **Org scoping** (department, location, team, agency) as **inputs** to “who may act” rules—using **TC-01** models as dimensions, not as the authority engine itself.
- **Delegation / substitute approver** (post-MVP or later phase)—not modeled in TC-01.
- **Segregation of duties** constraints between preparer/submitter vs approver—for example payroll input vs payroll approval—not enforced in TC-01.

### Phase 6 permission hardening implications

**Phase 6** in the roadmap (`domain-map.md`: “MVP hardening, permissions, audit, release readiness”) is where **permission-aware Team360**, **audit history**, **validation stabilization**, and **import/export safety** converge. Relative to authority:

- Sensitive actions flagged in **§ Audit and permission impact** (below) plus **authority-bearing** approvals/waivers/verifications should eventually require **explicit permission checks**, not only “logged in admin.”
- **Audit trails** (**TC-30**) should capture who exercised **authority** (approve/waive/verify/override)—not merely who supervised the engagement reporting line.
- **Team360** (**TC-29**) may **hide panels or rows** unless the viewer holds appropriate authority—not just manager visibility inherited from reporting line.
- Narrow **exceptions** (“override inactive org for assignment”) belong to **explicit policy tools** plus audit, not undocumented toggles—their design waits for workflows that consume org and engagement placement.

Earlier phases **may introduce light gates** before Phase 6, but Phase 6 is the roadmap bucket for **hardened** RBAC/policy behavior and MVP audit completeness.

---

## Admin UX requirements (TC-01.09 — requirements only)

**TC-01.09 acceptance** is satisfied by documenting **requirements** here. No admin UI ships in TC-01 unless scope is deliberately expanded beyond this baseline.

### Required admin screens (acceptance — listed)

Screens below are **minimum** to administer **ADR-0001** org substrate. Implementation epics (**TC-10**, dedicated admin epic, etc.) decide framework (Hotwire SPA, Rails admin, …).

| # | Screen / area | Manages | Notes |
| --- | --- | --- | --- |
| 1 | **Agencies** | `Agency` — `name`, `code`, `status` | **Separate model** in schema; singleton or few rows per deployment in MVP is OK. Avoid destructive delete while children exist (**`restrict_with_exception`** aligns with **§ Historical records**). |
| 2 | **Departments** | `Department` — incl. optional parent (single-level) | Scoped to chosen agency **context** (selector or tenancy UX). |
| 3 | **Locations** | `Location` — incl. **`location_type`**, optional `timezone`, `description` | No structured/`display_address` in TC-01 — see **`### Location (TC-01.03)`**. |
| 4 | **Teams** | `Team` — optional `department`, `location` | Same-agency validations match **`Team`** model. No **team-lead** field—see **`### Team (TC-01.04)`**. |
| 5 | **Placement & supervision** (`Engagement`-centric) | `EngagementOrganizationPlacement`, **`EngagementSupervisionAssignment`** | **Not standalone “org-only” substitutes** — lives with **TC-03 engagement** lifecycle admin (wizard, engagement detail tabs, or comparable). Mirrors issue wording *“Reporting lines or supervisor assignment.”* |
| 6 | **Organization settings** (agency-level) | Cross-cutting knobs **beyond** CRUD screens | MVP expectation: absorbed into **`Agency` edit** (**name/code/status**) plus agency-scoped conventions documented in admin runbooks. **Separate “settings” portal** deferred until **agency-level preference** backlog exists (timezone default, numbering policy, required placement toggles)—**those rules are authored in TC-03**/config epics rather than reinvented abstract “settings tables” here. |

### Create / edit / deactivate behavior (acceptance)

| Operation | UX expectation |
| --- | --- |
| **Create** | Validate required columns per model (**`agency_id`**, **`name`**, **`code`**, **`status`**, **`location_type`**); show inline errors; default **`status` → `active`**. Parent department picker filters to **same agency** and shows only **roots** (children cannot be parents — **single-level rule**). |
| **Edit** | Allow correction of **`name`**, **`description`** freely; **`code`** changes **discouraged** once referenced by integrations or historical exports—prefer **immutable code** convention with admin override gated (**permission + audit**, **§ Audit and permission impact**). |
| **Deactivate** | Prefer **`inactive`** vs **`archived`** per **`### Deactivation rules (TC-01.08)`**; confirmations when **Teams** attach to Departments/Locations; block or warn breaking refs per association strategy. |
| **Delete** | **Avoid** physical delete when rows are referenced (**schema already restricts parent deletes where configured**); use **inactive/archived**. |

### Search / filter needs (acceptance)

| Dimension | Applies to |
| --- | --- |
| **Agency context** | Departments, Locations, Teams (required before listing or enforced by deployment default). |
| **`status`** | All four org entities — **`active`** / **`inactive`** / **`archived`** checklist or tabs. |
| **`code`**, **`name`** | Substring match on Departments, Locations, Teams; Agencies when multi-agency. |
| **`location_type`** | Locations filter (six allowed values — **`### Location (TC-01.03)`**). |

Full-text polish, facets, CSV export/import — deferred to later admin hardening (**Phase 6** polish / explicit admin epic).

### Permission assumptions (acceptance — provisional **OD-009** stance)

Official permission matrix belongs to **permissions** epics (**OD-009** provisional; Phase 6 hardening). **Minimal assumptions** until then:

| Assumption | Guidance |
| --- | --- |
| **Privileged users only** | Only users with **`organization_admin`**-class role (exact name TBD in permissions model) mutate **Org** foundation rows in production. End users (**team members**) do **not** edit departments from self-service (**`overview`/`mvp-scope` self-service is limited**). |
| **Separate agency vs god-mode** | In future multi-agency deployments, admins may scope to **their `Agency`**; global super-admin escapes hatch—explicitly flagged for audit. |
| **Supervision/placement edits** | Tied to **who may edit engagements** (**TC-03**)—likely **HR/Operations** strata, tighter than CRM-style users. |

### Audit-sensitive actions (acceptance — cross-reference)

Administrative gestures that merit **explicit permission gates** and **immutable audit artifacts** (**TC-30**) overlap **§ Audit and permission impact (TC-01.12)**. High-signal overlaps for admins:

| Action | Relation |
| --- | --- |
| Create/update org foundation rows (`Agency`, `Department`, `Location`, `Team`) | **TC-01.12 table** rows + misconfiguration blast radius |
| **`inactive`** / **`archived`** transitions | Incorrect roster UX; correlate with **`### New assignment selection (TC-01.08)`** |
| **Override** selecting **`inactive`** org for placement | Narrow path — **explicit policy**, **authority**, capture in audit |
| Placement / supervision edits | **TC-01.12**, **TC-03** UX |

Readers implementing admin UI should defer final gate design to **`OD-009`** roadmap but **preserve hooks** (`before_action` scaffolding, immutable event logging placeholder) wherever these tables are touched early.

---

## Team360 and operational reporting (TC-01.10)

**TC-01.10** is satisfied **as requirements documentation** below. Rendering lives in **`TC-10`** (Team360 MVP shell), **`TC-12`** (operational reporting), with **org data plumbing** unlocked by **`TC-03`** placements/supervision. **Organization context** aggregation also references **`### Team (TC-01.04)`** § *Team360 organization context* ([`#team-tc-0104`](#team-tc-0104)).

### Team360 organization context fields (acceptance — listed)

These are the fields the **Organization / placement** strip on **Team360** should surface once wired (read-model only). **Authority** masking is **Phase 6** (**TC-29**) unless MVP explicitly opens visibility.

| Field | Typical source read path |
| --- | --- |
| **Department** | **Primary:** engagement **placement** `department_id` → **`departments`**. **Fallback only:** when placement omits department, **`teams.department_id`** via placement `team_id` — see **Recommended precedence** under **`### Team (TC-01.04)`**. |
| **Location** | **Primary:** placement `location_id` → **`locations`**. **Fallback:** **`teams.location_id`** via placement `team_id` when placement omits location — same **`### Team (TC-01.04)`** precedence rule. |
| **Team** | Placement `team_id` → **`teams.name` / `code`**. |
| **Supervisor** | **`EngagementSupervisionAssignment`** — resolve **display identity** (**Party** / **Team Member** name via supervisor’s **`Engagement`**, **TC-02** identifiers). Plain-text example permissible in mocks (“**Jane Manager**”) until integrations exist. |
| **Status (`Active` shown in issue)** | **Interpretation:** **recommended split** — (a) **`Engagement`** operational status (**TC-03**/`OD-003` spine)—what users intuit as “actively employed/contracted here”; PLUS (b) optional **footnote/badges** when linked **department/location/team** rows themselves are **`inactive`**/**`archived`** so viewers understand stale org fixtures (§ *Organization foundation lifecycle policy*). |

Issue-style example (conceptual composite):

```
Department: Sales
Location: Detroit Office
Team: Corporate Travel
Supervisor: Jane Manager          # Resolved label from supervisor engagement / Party (TC-03 + TC-02)
Engagement operational status: Active   # Canonical “active workforce relationship” wording (exact label TBD in TC-04/TC-03 UX)
Department / Location / Team org row status: active   # Or badges if any linked org row differs
```

### Operational reporting filters (acceptance — listed)

Standard roster / workload / ops reports SHOULD expose facets (exact UX **TC-12**):

| Filter dimension | Targets |
| --- | --- |
| **Department** | Placement `department_id` or equivalents. |
| **Location** | Placement `location_id` + optional **`location_type`**. |
| **Team** | Placement `team_id`. |
| **Supervisor** | Primary supervision edge (**`EngagementSupervisionAssignment`**) when **TC-03** persists it. Matrix supervisors may expose **facet per `relationship_type`** later. |
| **Organization lifecycle (`active` / `inactive`, `archived`)** | Department, Location, Team **record status** (“include deactivated org rows”) — dovetails with **`### New assignment selection (TC-01.08)`** within § *Organization foundation lifecycle policy*. |

Combined filters (Dept **AND** Team, etc.) deferred to **`TC-12`** interaction design unless MVP explicitly trims scope.

### Drill-through expectations (acceptance)

| From | Navigate to |
| --- | --- |
| **Operational report row** (“Team roster”, “inactive placement audit”, etc.) | **Engagement detail** or **subject Team360** (**TC-10**) when row keys include **Team Member**/engagement identity; respect **permissions** (**TC-29**). |
| **Supervisor cell** | **Supervisor Team360** profile or **their active engagement anchor** (**TC-03** chooses canonical link). |
| **Org unit row aggregated metrics** (**headcount per Department**) | **Filtered report** deepening to members or optionally **inactive-only exception** dashboards—**exact behavior TC-12**. |

Drill-through must **reuse authoritative engagement/org IDs** surfaced in aggregates—no brittle string matching alone.

### Dependencies (acceptance — **TC-10**, **TC-12** explicitly)

| Epic | Depends on it for TC-01.10 |
| --- | --- |
| **TC-10** | Implements **Team360 shell** embedding **organization context strip** sourced from placements + supervisors. Without **Team360**, Org fields stay API-only/console-only. |
| **TC-12** | Implements **operational reporting** lists, summaries, facets, drill-through honoring filters above. |
| **TC-03** (**supporting prerequisite**) | **Must** expose **persisted placements** + **`EngagementSupervisionAssignment`** (or equivalents) Team360/reporting aggregates read from—else panels render **UNKNOWN** stubs. Listed because AC references Team360/reporting—not because TC-01.09 “depends on TC-03” numerically substitutes for TC-10/12. |
| **TC-29** (**supporting prerequisite**) | **Permission-aware masking** hides sensitive org labels or restricts drill-down when MVP security demands it (**OD-009** provisional). |

---

## Audit and permission impact note (TC-01.12)

**TC‑01.12** captures **requirements only**: TC‑01 ships **no** executable permission engine or persistent audit ledger.

### Sensitive organization actions (acceptance — listed)

Actions below SHOULD be **permission-gated** (**`OD-009`** provisional → hardened **Phase 6**) and SHOULD emit **immutable audit artifacts** (**`TC-30`**) once those capabilities exist.

| Area | Sensitive action | Typical risk |
| --- | --- | --- |
| **Department** | **Create** department | Wrong hierarchy / codes pollute placements and reporting. |
| **Department** | **Deactivate / archive** (status **→ `inactive` / `archived`**) | Incorrect availability for assignments; UX confusion (§ *Organization foundation lifecycle policy*). |
| **Location** | **Create** location | Wrong **`location_type`** distorts roster/time/payroll storylines downstream. |
| **Location** | **Deactivate / archive** | Misroutes placement defaults; timezone/report expectations drift. |
| **Team** | **Create** team | Mis-linked **department**/**location** breaks consistency validations or operational ownership. |
| **Team** | **Deactivate / archive** | Rosters orphan teams; stale labels in historical placements. |
| **Agency** *(foundation)* | **Create/update** **`Agency`** (+ **`inactive`/`archived`**) | Multi-tenant / misconfiguration blast radius (**epic also implies agencies as top-level entity**). |
| **Supervision / reporting line** | **Changing supervisor assignments** (**`EngagementSupervisionAssignment`**) | Wrong manager visibility + approval routing assumptions (**§ Reporting line TC‑01.05**, **§ Authority TC‑01.06**). |
| **Reporting line** | **Changing reporting line semantics** (edge type / primary promotion / matrix reorder) | Same class of risk as supervisor swap—may reroute escalation paths. |
| **Placement** | **Moving engagement** between **department / team / location** (**effective-dated placement row**) | Historical reporting anomalies; reconciliation pain without audit (**`§ Engagement placement`**). |
| **Authority** *(concept→implementation)* | **Changing authority structure** mappings (roles→actions, waive paths, segregation rules) | Unauthorized waivers/approvals; SOC-style failures (**authority engine deferred**, **Phase 6** tightening). |

> **Normalize:** Epic wording “creating/deactivating departments…” maps to **create + lifecycle transitions** in the table. **Deactivate** includes transitions to **`inactive`** or **`archived`** unless product explicitly distinguishes them in downstream audit taxonomy.

### Audit expectations (acceptance — documented)

| Expectation | Notes |
| --- | --- |
| **Coverage** | **Who** acted, **when**, **what** entity, **prior vs new values** for attribute edits and placement moves (**including effective dates**). |
| **Immutability** | Audit entries are **append-only**; corrections are **superseding events**, not silent database overwrites (same posture as **§ *Historical placement concerns*** and supervision **§ *Historical behavior***). |
| **Retention** | Retention/class-of-service policy **outside TC‑01** — Phase 6 / compliance backlog. |
| **Privileged reads** | Viewing audit streams itself may require **elevated permission** (**TC‑29**/**TC‑30** UX). |

**Minimum viable posture before Phase 6 spike:** structured **application logs** keyed by **`agency_id`** + **`current_user`** on admin mutations (**best-effort**) — upgrading to **`TC‑30`** schema.

### Permission expectations (acceptance — documented)

| Expectation | Notes |
| --- | --- |
| **Granularity** | **Separate** capabilities for **`organization_admin`** (foundation CRUD/status) vs **`engagement_editor`** (**placement/sup supervision**) vs future **`authority_admin`** (**Phase 6**)—exact matrix **`OD‑009`** + permissions ADR backlog. |
| **Least privilege** | Ordinary managers **must not silently edit** departments/locations globally; localized delegation **explicit decision**. |
| **Overrides** | Selecting **`inactive`** department/location/team during **placement** (**allowed exception**) requires **narrow permission flag** + **paired audit record** (**§ Admin UX** + § *Organization foundation lifecycle policy*). |

### Phase 6 hardening dependencies (acceptance — noted)

Phase 6 (**`domain-map`** “MVP Hardening, Permissions, Audit, Release Readiness”) is where these controls **crystallize**:

| Artifact | Dependency |
| --- | --- |
| **`TC‑29`** | **Permission-aware Team360/admin** masking using finalized RBAC/policy model. |
| **`TC‑30`** | **MVP audit history** emitting durable events on rows above (**success criterion for TC‑01.12 rollout** beyond logs). |
| **`OD‑009` follow‑through** | Moves from provisional MVP stance → formal permission ADR (**register already flags Phase 3–6** alignment). |
| **`OD‑010` audit depth** | Optional formal audit ADR if **`TC‑30`** policy gaps emerge (**Phase 6** posture in **`open-decisions`**). |

**Intermediate phases:** **TC‑03** introduces **placement / supervision mutations** requiring **immediate** coarse gates even before Phase 6 completeness — **reuse this issue list as checklist** those PRs reference.

---

## Seeds and baseline fixtures (TC-01.11)

**Implementation:** **[`db/seeds.rb`](../../db/seeds.rb)** — **`find_or_initialize_by`** on stable **`code`** keys so **`db:seed`** is repeatable.

### What exists (aligned with epic “suggested seed data”)

| Kind | Rows |
| --- | --- |
| **Agency** | Example Agency (**`code`:** **`example`**) |
| **Departments** | Administration · Operations · Sales · Accounting · Contractor Relations |
| **Locations** | Main Office (**office**) · Remote (**remote**) · Virtual (**virtual**) |
| **Teams** | Employee Operations · Contractor Support · Payroll Review · Settlement Review |

Teams link to plausible **department** + **location** pairs so **TC-03** placements can mimic **employee-ops** (**main office / operations**) vs **contractor** (**virtual / contractor relations**) demos without inventing engagements in TC-01.

### Acceptance mapping

| Criterion | Evidence |
| --- | --- |
| Baseline agency / departments / locations / teams | **`db/seeds.rb`** authoritative list above |
| Seeds support future engagement examples | Stable **`code`** identifiers + dept/loc FK coverage for placement/supervisor scenarios once **`engagements`** exist |
| Avoid overfitting to one company | Neutral **“Example Agency”** taxonomy; documented intent in **`db/seeds.rb`** header |

**Tests (`test/`):** model tests **construct org rows programmatically** (no checked-in YAML fixtures yet) — acceptable “fixture expectation” posture until engagement fixtures land (**TC-03**).

---

## Related epics

- **TC-03** — Engagements plus persistence for placement/supervision
- **TC-10 / TC-12** — Presentation and reporting consuming org context
- **TC-29 / TC-30** — Permission-aware views and audit history
