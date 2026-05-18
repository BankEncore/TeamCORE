# UX0-J04 — Subcontractor onboarding

## Status

conditional

## Primary persona

Agency administrator bringing a **subcontractor** relationship into TeamCORE when the agency tracks subcontractors as first-class workforce records tied to a contractor relationship.

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

When configuration applies, model subcontractor identity + workforce membership, align Party / TeamMember / Engagement flows with parent contractor context, and confirm readiness using Team360—without implying every agency enables subcontractor tracking.

## Entry points

- Post UX-1 hub: planned `/admin/onboarding` → guided subcontractor launcher (routes today: `admin_guided_subcontractor_path`).
- Existing fallback: `admin_guided_setup_path` → `admin_guided_subcontractor_path`.
- Fast path: `admin_search_path` → Team360 once indexed.

## Preconditions

Distinguish **related-only** vs **promoted** subcontractors (do not infer payroll, settlement, documents, or Team360 eligibility from `PartyRelationship` alone):

| Layer | Meaning |
| ----- | ------- |
| **Related-only** | `PartyRelationship` (and Party Hub context) for association / visibility / commercial context—no TeamMember + Engagement spine required. |
| **Promoted / workforce-grade** | `TeamMember` + subcontractor **`Engagement`** when the agency needs operational authority: documents, readiness, settlement/participation hooks, Team360, etc. |

- This journey’s routes apply when promoting to **workforce-grade** (or when already promoted)—not for related-only contacts.
- Parent contractor context exists or will be linked via Party relationships (`admin_party_party_relationships_path`) where promotion requires it.

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Guided subcontractor | `admin_guided_subcontractor_path` | `/admin/guided/subcontractor` |
| Guided hub | `admin_guided_setup_path` | `/admin/guided` |
| Party / relationship CRUD | `admin_party_path`, `admin_party_party_relationships_path`, `new_admin_party_party_relationship_path` | `/admin/parties/:id`, `/admin/parties/:party_id/party_relationships`, `/new` |
| Team member CRUD | `new_admin_team_member_path`, `admin_team_member_path` | `/admin/team_members/new`, `/admin/team_members/:id` |
| Engagement CRUD | `new_admin_engagement_path`, `admin_engagement_path` | `/admin/engagements/new`, `/admin/engagements/:id` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |
| Documents | `admin_document_workbench_path`, `new_admin_document_record_path` | `/admin/document_workbench`, `/admin/document_records/new` |
| Report – subcontractors | `admin_reports_subcontractors_path` | `/admin/reports/subcontractors` |

## Happy path

1. Decide **related-only vs promoted**: if related-only suffices, stop after Party / relationship maintenance—do **not** imply engagement-scoped workflows.

2. Open guided subcontractor onboarding when agency uses TeamCORE’s orchestrated checklist.
   - Route helper: `admin_guided_subcontractor_path`
   - Path pattern: `/admin/guided/subcontractor`

3. Establish Party identity + relationships tying subcontractor to prime contractor context via Party Hub tooling (`admin_party_path`, relationship routes).

4. Create TeamMember + Engagement mirroring contractor onboarding patterns with subcontractor-specific document expectations.

5. Validate **readiness/orientation** via Team360 with `engagement_id` focusing panels when overlapping engagements exist (promoted path only).

## Team360 usage

Same rules as other workforce journeys (**promoted** subcontractors): Team360 supports reviewing readiness/orientation; include `engagement_id` when prime vs subcontractor engagements could otherwise blur panels.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Guided subcontractor | Save supporting record | `admin_guided_subcontractor_path` or Team360 |
| Party relationship editor | Save relationship (related-only layer) | Parent contractor Party hub or subcontractor Party hub |
| Document intake | Save subcontractor evidence | Document workbench / Team360 per `return_to` |

## Exceptions / branches

- **Related-only** subcontractor: skip `TeamMember` / `Engagement` creation; do not use engagement nested routes or imply evaluator/readiness for a workforce engagement that does not exist.

## Reports vs workbenches

- **`admin_reports_subcontractors_path`** supports roster-style insight; operational triage still flows through **`admin_document_workbench_path`** when documents block activation.

## Out of scope / deferrals

- Automated prime/subcontractor synchronization with external CRM tools.

## Verification checklist

- [ ] Journey labeled `conditional` and prerequisites explicitly acknowledged.
- [ ] Guided helper references `admin_guided_subcontractor_path` exactly.
- [ ] Team360 URLs document optional `engagement_id` query usage.
- [ ] **Related-only** vs **promoted** subcontractor paths are explicit (PartyRelationship-only vs TeamMember + Engagement).
