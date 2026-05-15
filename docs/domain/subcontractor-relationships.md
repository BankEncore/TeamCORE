# Subcontractor relationships (TC-05)

This document is the **Phase 1 hub** for subcontractor **association** vs **workforce** behavior. Deeper narratives also appear in [`engagement.md`](engagement.md) (TC-03-D06), [`engagement-status.md`](engagement-status.md), and [`party-team-member.md`](party-team-member.md).

## Two layers (do not conflate)

| Layer | Role |
| --- | --- |
| [`PartyRelationship`](../../app/models/party_relationship.rb) (`relationship_type = subcontractor`) | Association / visibility / commercial context between parties |
| [`TeamMember`](../../app/models/team_member.rb) + [`Engagement`](../../app/models/engagement.rb) (`relationship_type = subcontractor`) | Direct workforce spine when the agency needs operational authority on that party |

**Do not** infer workflow eligibility, settlement, documents, or Team360 from **`PartyRelationship.status`** alone. **`Engagement`** holds operational status for promoted subcontractors.

## Schema contract

`party_relationships` use **`effective_start_date`** and **`effective_end_date`** (not `_on`). Optional notes use the `notes` column.

## Related-only vs promoted

### Related-only subcontractor

- [`Party`](../../app/models/party.rb) exists; **`PartyRelationship`** with `relationship_type = subcontractor` exists.
- **No** requirement for `TeamMember` or `Engagement`.
- No direct workflow eligibility from the relationship row alone.

### Promoted subcontractor

- Same **`Party`** may have **`TeamMember`** and **`Engagement`** with **`relationship_type = subcontractor`** when the agency needs the workforce spine.
- The original **`PartyRelationship`** may remain for association context (not removed automatically).

### Display tiers (admin UX)

| Label | Meaning |
| --- | --- |
| **Related only** | A **`subcontractor` `PartyRelationship` exists** and there is **no** **`subcontractor` `Engagement`** for that target party’s agency spine yet. |
| **Promoted — {engagement.status}** | A **`subcontractor` `Engagement` exists** (any of draft, pending, active, suspended, ended, terminated as applicable)—show the engagement status. Draft and pending **count as promoted** (party has entered the workforce spine). |
| **Formerly promoted** | Only **terminal** subcontractor engagements remain (for example ended / terminated / cancelled), with no open non-terminal subcontractor engagement—optional copy for history. |

**Panel copy (direction):** On a contractor organization party: **Subcontractors under this party** (outbound). On the subcontractor target party or team member: **Subcontractor relationships for this party** (incoming, **source → target**).

## Source eligibility (Phase 1)

For `relationship_type = subcontractor`, **`source_party`** may be:

1. An **organization** whose **[`OrganizationProfile`](../../app/models/organization_profile.rb)** has **`organization_kind = contractor_organization`**, or  
2. A **person** who has at least one **same-agency** **`Engagement`** with **`relationship_type = individual_contractor`** and **`status = active`**.

**`target_party`**: **person** or **organization** (matches [`Engagement`](../../app/models/engagement.rb) rules for `relationship_type = subcontractor`).

## Stale person source (read vs write)

If a **person** was eligible as a source because they had an **active individual contractor** engagement and that engagement later **ends or is no longer active**:

- **Do not** delete or hide existing **`PartyRelationship`** rows (history remains).
- **On write** (create, edit, reactivate, new edge from that source): **revalidate** that the source is still contractor-capable per the rules above.
- **On read-only screens**: show a **warning** if the source is no longer contractor-capable.

## Overlap rule (pair-level)

For **`relationship_type = subcontractor`**, constrain **concurrent** association at \((agency_id, source_party_id, target_party_id)\):

- Multiple **historical** rows are allowed when they do not conflict—for example **back-to-back** windows, **`inactive` / `archived`** rows, or **non-overlapping** `effective_start_date` / `effective_end_date` intervals while **`status = active`**.
- **Forbidden:** two rows that are **both** `status = active` for the same `(agency_id, source_party_id, target_party_id, relationship_type = subcontractor)` whose **effective date intervals overlap**. Blanks are treated as **open-ended** for that bound when detecting overlap (inclusive interval overlap in application validation).

The same **target** subcontractor may still link to **different** source contractors—only the **pair** is constrained.

Promotion and other “is this edge live right now?” checks use **currently effective**, which matches **[`PartyRelationship#currently_effective_on?`](../../app/models/party_relationship.rb)**:

```text
status = active
effective_start_date is blank OR <= Date.current
effective_end_date is blank OR >= Date.current
```

## `subcontractor_contact` (not promoted in TC-05)

- **`subcontractor_contact`** remains a distinct `relationship_type` for contact/context edges.
- It **does not** trigger **promotion** UX or the promotion service.
- Phase 1 **does not** apply the same validation stack as **`subcontractor`**; stricter rules can wait for a focused follow-up.

## `subcontractor` admin scope (Phase 1)

Foundation admin UX focuses on **`relationship_type = subcontractor`**. Other relationship types keep existing model rules (for example `primary_contact`).

## Promotion rules

Promotion is allowed **only** from a **`subcontractor` `PartyRelationship`** that is **currently active and effective** (same predicate as **currently effective** above). Ended, inactive, archived, or not-yet-effective relationships must be corrected before promotion.

Promotion runs in a **database transaction**; it **reuses** `TeamMember` when present; it **reuses** an existing open **`subcontractor` engagement** (draft/pending/active/suspended per product policy) when present instead of creating duplicates; it respects **[`Party#identity_complete?`](../../app/models/party.rb)** on the **target**.

## Edge-case defaults

Promotion is allowed only from a currently active/effective `subcontractor` PartyRelationship. Ended, inactive, archived, or not-yet-effective relationships must be corrected or made current before promotion. Once a subcontractor Party has a TeamMember and a `subcontractor` Engagement, the UX should display it as `Promoted — {engagement.status}` even if the engagement is `draft` or `pending`; “related-only” means no subcontractor Engagement exists. If a person source later loses the active `individual_contractor` engagement that made them contractor-capable, existing relationships remain visible for history, but relationship edits, reactivation, or new subcontractor edges must revalidate source eligibility; display screens should show a warning rather than silently rewriting history.

## What TC-05 explicitly does not ship

Document/compliance engines, settlement or charge engines, Team360 full UI, approval workflow, RBAC matrix, durable audit ledger. Phase 1 uses existing **admin login** only; future sensitive-action and audit posture: see **[`open-decisions.md`](../product/open-decisions.md)** (TC-29 / TC-30 references).
