# UX0-J03 — Contractor organization onboarding

## Status

current

## Primary persona

Agency administrator onboarding a **contractor organization** (business entity workforce type).

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Create an **organization Party**, establish the contractor **TeamMember** representing the entity, attach primary contacts / relationships as needed, stand up the contractor **Engagement**, then complete placement, supervision (if agency tracks oversight), documents, compensation assignment, and readiness via **Team360**.

## Entry points

- Post UX-1 hub: planned `/admin/onboarding` → `admin_guided_contractor_organization_path`.
- Existing fallback: `admin_guided_setup_path` → `admin_guided_contractor_organization_path`.
- Fast path: `admin_search_path` → entity Team360 once indexed.

## Preconditions

- Workforce type should be organization—not a sole proprietor modeled only as person (use [contractor-onboarding-individual.md](./contractor-onboarding-individual.md)).
- Agency knows primary contact parties if relationships must be recorded (`admin_party_party_relationships_path`).

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Guided contractor organization | `admin_guided_contractor_organization_path` | `/admin/guided/contractor_organization` |
| New organization party | `admin_new_organization_party_path` | `/admin/parties/new/organization` |
| Create organization party | `admin_organization_parties_path` | `POST /admin/parties/organization` |
| Party hub | `admin_party_path(party)` | `/admin/parties/:id` |
| Party relationships index | `admin_party_party_relationships_path(party)` | `/admin/parties/:party_id/party_relationships` |
| New party relationship | `new_admin_party_party_relationship_path(party)` | `/admin/parties/:party_id/party_relationships/new` |
| Promote relationship | `promote_admin_party_party_relationship_path(party, relationship)` | `POST /admin/parties/:party_id/party_relationships/:id/promote` |
| Team member CRUD | `new_admin_team_member_path`, `admin_team_member_path(team_member)` | `/admin/team_members/new`, `/admin/team_members/:id` |
| Engagement CRUD | `new_admin_engagement_path`, `admin_engagement_path(engagement)` | `/admin/engagements/new`, `/admin/engagements/:id` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |
| Placements | `admin_engagement_placements_path(engagement)`, `new_admin_engagement_placement_path(engagement)` | `/admin/engagements/:engagement_id/placements`, `/new` |
| Supervision | `admin_engagement_supervision_assignments_path(engagement)`, `new_admin_engagement_supervision_assignment_path(engagement)` | `/admin/engagements/:engagement_id/supervision_assignments`, `/new` |
| Compensation assignments | `new_admin_engagement_compensation_plan_assignment_path(engagement)` | `/admin/engagements/:engagement_id/compensation_assignments/new` |
| Documents | `new_admin_document_record_path`, `admin_document_workbench_path` | `/admin/document_records/new`, `/admin/document_workbench` |
| Subcontractor reporting | `admin_reports_subcontractors_path` | `/admin/reports/subcontractors` |

## Happy path

1. Enter guided contractor organization onboarding.
   - Route helper: `admin_guided_contractor_organization_path`
   - Path pattern: `/admin/guided/contractor_organization`

2. Create **organization Party**.
   - Route helper: `admin_new_organization_party_path` → `admin_organization_parties_path`
   - Path pattern: `/admin/parties/new/organization` → `POST /admin/parties/organization`
   - Primary return: `admin_party_path(party)`.

3. Record **relationships** (e.g., primary contact, authorized signers) when operational needs demand it.
   - Route helper: `new_admin_party_party_relationship_path(party)`
   - Path pattern: `/admin/parties/:party_id/party_relationships/new`
   - Promotion / upgrades (if used): `promote_admin_party_party_relationship_path`

4. Create **TeamMember** representing the contractor organization.
   - Route helper: `new_admin_team_member_path`
   - Path pattern: `/admin/team_members/new`

5. Create contractor **Engagement** anchored to the entity membership.
   - Route helper: `new_admin_engagement_path` → `admin_engagement_path(engagement)`
   - Path pattern: `/admin/engagements/new` → `/admin/engagements/:id`
   - Team360: `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` for org-centric readiness review.

6. Add **Placement** / **Supervision** consistent with how the agency oversees contractor organizations.

7. Attach entity-level **documents** (agreements, insurance, renewal artifacts, **classification-supporting** records per configured requirements—not a legal classification determination).

8. Assign **compensation** plan appropriate to contractor settlement rails.

9. Validate readiness via Team360; pivot to subcontractor flows only when configuration warrants ([subcontractor-onboarding.md](./subcontractor-onboarding.md)).

## Team360 usage

Team360 remains the **record hub** for the contractor organization’s workforce shell: engagement panels summarize obligations; drill-through links should preserve `engagement_id` when interacting with nested engagement resources.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Party hub | Jump to workforce / team member creation | `admin_team_member_path` / `new_admin_team_member_path` per UI linkage |
| Guided org contractor flow | Save nested resource | Guided route or `admin_engagement_path` |
| Relationship editor | Save party relationship | `admin_party_party_relationships_path` or Party hub |
| Document upload | Save document record | Team360 with matching `engagement_id` when returns configured |

## Exceptions / branches

- **Subcontractors**: remain conditional; see [subcontractor-onboarding.md](./subcontractor-onboarding.md) and report `admin_reports_subcontractors_path` for visibility—not a substitute for Team360 drill-down.

## Reports vs workbenches

- Avoid dumping entity onboarding queues onto future hubs; prefer **`admin_document_workbench_path`** for missing items and **`admin_reports_contractor_documentation_index_path`** for cross-agency contractor documentation analytics.

## Out of scope / deferrals

- Automated subcontractor provisioning—depends on agency configuration and future UX.

## Verification checklist

- [ ] Organization creation uses `admin_new_organization_party_path` / `admin_organization_parties_path` (distinct from person contractor path).
- [ ] Relationship routes retain `:party_id` prefix exactly as generated.
- [ ] Engagement-scoped URLs mirror nested resources under `/admin/engagements/:engagement_id/...`.
- [ ] Team360 links carry `engagement_id` for organization contractors the same as person contractors.
