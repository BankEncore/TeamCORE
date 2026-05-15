# Party and Team Member domain — TeamCORE

Modeling notes for **TC-02 — Team Member / Party Foundation**. Glossary cross-refs in [`../product/glossary.md`](../product/glossary.md); decisions in [`../product/open-decisions.md`](../product/open-decisions.md) (**OD-001**, **OD-002**, **OD-004**, **TC-02-D01…D05**); **TC-03 Engagement** in **[`engagement.md`](engagement.md)**; **TC-05 subcontractor association vs promotion** in **[`subcontractor-relationships.md`](subcontractor-relationships.md)**; internal org substrate in **[`organization.md`](organization.md)** / **ADR-0001**; Party↔Engagement spine in [`../product/modeling-notes/party-team-member-engagement.md`](../product/modeling-notes/party-team-member-engagement.md).

---

## Locked product decisions (TC-02-D01…D05)

Summaries below; formal register entries: **`open-decisions.md`** (TC-02-D01…D05).

| ID | Decision |
| --- | --- |
| **TC-02-D01** | `team_member_number` is **optional**; **unique per agency** when present; multiple NULLs allowed (MySQL). Normalized **strip + uppercase** as internal identifier — **not** [`NormalizesCode`](../../app/models/concerns/normalizes_code.rb) (lowercase org codes). |
| **TC-02-D02** | **Draft-tolerant** Party (may lack profile). **TeamMember** requires **complete identity** (`identity_complete?`). |
| **TC-02-D03** | At most **one currently active** `primary_contact` per **source** party; **active** = type + `status` + effective dates (see § PartyRelationship). |
| **TC-02-D04** | Organization-type Party is **not** automatically a TeamMember; add TeamMember only for **direct workforce participation** (engagement/settlement/Team360/compliance per product). |
| **TC-02-D05** | `Party.display_name` is **authoritative** for UI; **default from profile when blank**; **no ongoing sync** required; must be **present when identity is complete**; `display_name_overridden` flag **deferred**. |

---

## Source of truth recap (TC-02 boundaries)

| Concept | TC-02 source of truth | Implemented now? |
| --- | --- | --- |
| **Party** | `parties` | Yes |
| **PersonProfile** | `person_profiles` | Yes |
| **OrganizationProfile** | `organization_profiles` | Yes |
| **TeamMember** | `team_members` | Yes |
| **PartyContactMethod** | `party_contact_methods` | Yes |
| **PartyRelationship** | `party_relationships` | Yes |
| **Engagement** | `engagements` + placement/supervision children | Yes — **[`engagement.md`](engagement.md)** (TC-03) |
| **Employee vs contractor authority** | Engagement + status | Yes — **TC-03** / **OD-003** (`relationship_type` per domain doc) |
| **Team360 identity UI** | Read model | No — **TC-10** |
| **Permission / audit ledger** | Policy + TC-30 | No — **TC-29/TC-30** |

---

## Agency vs organization (terminology)

- **Agency** — Rails `Agency`; top-level tenant. **Party** and **TeamMember** belong to an agency.
- **Organization (TC-01 domain language)** — Internal structure: `Department`, `Location`, `Team`. **Not** an `organizations` table. See [`organization.md`](organization.md).
- **Organization profile (TC-02)** — **`OrganizationProfile`** on an **organization-type Party** (contractor org, vendor, etc.). **Do not conflate** with TC-01 internal org.

---

## Conceptual spine

```text
Agency
  Party (identity)
    PersonProfile | OrganizationProfile (typed, 1:1)
    PartyContactMethod (many)
    PartyRelationship (directed: source → target)
  TeamMember (workforce participant; ≤1 per Party per Agency MVP)
  Engagement (TC-03)
```

---

## Party (`parties`)

**Concrete model:** `Party`

| Attribute | Notes |
| --- | --- |
| `agency_id` | Required |
| `party_type` | `person` \| `organization` |
| `display_name` | Authoritative label (TC-02-D05); nullable while draft; **required when `identity_complete?`** |
| `status` | `active` / `inactive` / `archived` (`LifecycleStatusable`) |
| `external_reference` | Optional external key; **do not** pass through `NormalizesCode` |
| `notes` | Optional |

**Rules:** Party does **not** encode employee/contractor workflow authority (**OD-001**, **OD-003**). **Profile cardinality:** person parties use **PersonProfile** only; organization parties use **OrganizationProfile** only — mutually exclusive.

### `identity_complete?`

```text
person      → person_profile.present?
organization → organization_profile.present?
```

### Display name default (TC-02-D05)

When `display_name` is blank and the matching profile exists:

- **Person:** `preferred_name` + `last_name`, else `first_name` + `last_name`
- **Organization:** `trade_name`, else `legal_name`

Apply in `before_validation` when profile present. After first save, **no automatic re-sync** when profile changes.

---

## PersonProfile (`person_profiles`)

1:1 with **person-type** Party. Fields: `first_name`, `middle_name`, `last_name`, `preferred_name`, `suffix` (all optional at DB level; product may tighten required names in UX later).

---

## OrganizationProfile (`organization_profiles`)

1:1 with **organization-type** Party.

| `organization_kind` | Use |
| --- | --- |
| `contractor_organization` | Firm under contract |
| `vendor` | Vendor |
| `agency_partner` | Partner org |
| `client` | Client org |
| `other` | Escape hatch |

**Legal/trade names** live here — **not** on `Party` (Option B).

---

## TeamMember (`team_members`)

Links **Party** to **Agency** as workforce participant row.

| Attribute | Notes |
| --- | --- |
| `agency_id`, `party_id` | **Unique pair** (MVP) — **OD-002** history is on Engagement, not duplicate TeamMembers |
| `team_member_number` | Optional; **unique per agency** when set (TC-02-D01); normalized strip + **uppercase** |
| `status` | Lifecycle; **not** employment/contractor status (**TC-03**) |

**TC-02-D02:** `TeamMember` creation requires `party.identity_complete?` and **non-blank** `party.display_name` (enforced via Party validation when complete).

**TC-02-D04:** Do not create TeamMember for org parties unless direct participation is intended.

---

## PartyContactMethod (`party_contact_methods`)

| `contact_type` | `email`, `phone`, `address`, `website`, `other` |
| `value` | Raw entry |
| `normalized_value` | Optional canonical form for matching/search (rules per type, documented in code) |
| `is_primary` | At most **one primary per `(party_id, contact_type)`** among `active` rows |

**Status:** `active` / `inactive` / `archived` (shared vocabulary).

---

## PartyRelationship (`party_relationships`)

**Directed:** `source_party` → `target_party`. **Same agency:** `agency_id` plus source/target parties’ `agency_id` must match.

| `relationship_type` (MVP set) | Examples |
| --- | --- |
| `primary_contact` | Org → person (contractor org’s primary contact) |
| `secondary_contact` | Secondary |
| `subcontractor` | Org or person link |
| `subcontractor_contact` | Contact on subcontractor path |
| `representative`, `owner`, `related_contact`, `other` | Per product |

**Status:** `active` / `inactive` / `archived` (**TC-02-D03** uses `active` for “counts as current”).

### Currently effective (TC-02-D03)

```text
status == active
AND (effective_start_date IS NULL OR effective_start_date <= as_of)
AND (effective_end_date IS NULL OR effective_end_date >= as_of)
```

**Primary contact:** at most **one** currently-effective `primary_contact` per **source_party**. Historical rows use effective dates and/or `inactive`/`archived`.

**Shape:** For `primary_contact`, **source** should be **organization** Party (contractor org); **target** **person** Party (enforced in model).

### Self-edge

**Forbidden:** `source_party_id == target_party_id`.

**`relationship_context`:** deferred (not in TC-02 schema).

---

## Duplicate posture (TC-02.09)

- **Names** are not unique identifiers.
- **`display_name`** not globally unique.
- **`external_reference`** optional; not assumed unique unless product adds constraint later.
- **`team_member_number`** unique per agency when present.
- **Contact `value`** not globally unique.

---

## Subcontractor promotion (OD-004)

Related party + `PartyRelationship` by default; **promote** to **TeamMember** when agency needs direct tracking (documents, Team360, engagement, settlement). See **OD-004** table in `open-decisions.md`.

---

## Team360 identity panel (requirements only — #68)

When **TC-10** exists, identity strip should be able to show (read paths): `display_name`, `party_type`, profile fields, `team_member_number`, primary email/phone/address from **PartyContactMethod**, contractor org relationships, primary contact, subcontractor edges. **No TC-02 UI.**

---

## Audit and permission impact (#69)

Sensitive actions (future **TC-29/TC-30**): create/update Party; change `party_type`; profile CRUD; TeamMember CRUD; archive Party/TeamMember; primary contact changes; relationship CRUD; subcontractor promotion; future merge/dedupe. **TC-02** documents only — no durable audit ledger.

---

## TC-03 handoff contract

**Engagement (TC-03)** is expected to reference:

- **`team_members.id`** (and/or **`parties.id`** through TeamMember’s party) as the workforce anchor.
- **Not** duplicate identity; **not** put `employee`/`contractor` enums on **Party** or **TeamMember** as authoritative workflow state.

**Forbidden on TC-02 tables (MVP):** `employment_status`, `contractor_status`, `engagement_status`, compensation IDs, document requirement IDs, Team360 denormalized payloads, approval authority fields — those belong to **TC-03+**.

**Invariants to preserve:** ≤1 TeamMember per `(agency_id, party_id)`; Party `agency_id` consistent on TeamMember and relationships; complete identity before TeamMember.

---

## Related epics

- **TC-01** — Agency / internal org substrate
- **TC-03** — [**`engagement.md`**](engagement.md) — engagements, placement, supervision
- **TC-10** — Team360 shell
- **TC-29 / TC-30** — Permissions and audit

GitHub: epic [#3](https://github.com/BankEncore/TeamCORE/issues/3), sub-issues **#58–#70**.
