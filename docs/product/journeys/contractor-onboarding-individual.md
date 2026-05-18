# UX0-J02 — Individual contractor onboarding

## Status

current

## Primary persona

Agency administrator onboarding an **individual independent contractor** (person workforce type with contractor engagement semantics).

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Stand up Party → TeamMember → contractor **Engagement**, then complete placement, supervision as needed, documents, compensation assignment, and readiness review via **Team360**—mirroring employee onboarding with contractor-specific document and compensation expectations.

## Entry points

- Post UX-1 hub: planned `/admin/onboarding` → `admin_guided_individual_contractor_path`.
- Existing fallback: `admin_guided_setup_path` then `admin_guided_individual_contractor_path`; Party-first via `admin_new_person_party_path`; organization path is **not** used here (see [contractor-onboarding-organization.md](./contractor-onboarding-organization.md)).
- Fast path: `admin_search_path` → Team360 once identifiers exist.

## Preconditions

- Contractor should be modeled as a **person** party (not an organization).
- Agency understands contractor document pack (W-9, agreement, insurance/E\&O as **configured requirements**). TeamCORE provides **classification support** (records + statuses), not legal classification outcomes.

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Guided hub | `admin_guided_setup_path` | `/admin/guided` |
| Guided individual contractor | `admin_guided_individual_contractor_path` | `/admin/guided/individual_contractor` |
| Person party new/create | `admin_new_person_party_path`, `admin_person_parties_path` | `/admin/parties/new/person`, `POST /admin/parties/person` |
| Party hub | `admin_party_path(party)` | `/admin/parties/:id` |
| Team member CRUD | `new_admin_team_member_path`, `admin_team_member_path(team_member)` | `/admin/team_members/new`, `/admin/team_members/:id` |
| Engagement CRUD | `new_admin_engagement_path`, `admin_engagement_path(engagement)` | `/admin/engagements/new`, `/admin/engagements/:id` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |
| Placements | `admin_engagement_placements_path(engagement)`, `new_admin_engagement_placement_path(engagement)` | `/admin/engagements/:engagement_id/placements`, `/new` |
| Supervision | `admin_engagement_supervision_assignments_path(engagement)`, `new_admin_engagement_supervision_assignment_path(engagement)` | `/admin/engagements/:engagement_id/supervision_assignments`, `/new` |
| Compensation assignments | `admin_engagement_compensation_plan_assignments_path(engagement)`, `new_admin_engagement_compensation_plan_assignment_path(engagement)` | `/admin/engagements/:engagement_id/compensation_assignments`, `/new` |
| Documents | `new_admin_document_record_path`, `admin_document_record_path(record)`, `admin_document_workbench_path` | `/admin/document_records/new`, `/admin/document_records/:id`, `/admin/document_workbench` |
| Contractor charges queue | `admin_contractor_charges_path` | `/admin/contractor_charges` |
| Reporting | `admin_reports_contractor_documentation_index_path` | `/admin/reports/contractor_documentation` |

## Happy path

1. Open guided individual contractor flow.
   - Route helper: `admin_guided_individual_contractor_path`
   - Path pattern: `/admin/guided/individual_contractor`
   - Primary return: guided hub `admin_guided_setup_path` when exiting.

2. Create or confirm **Party** person.
   - Route helper: `admin_new_person_party_path` → `admin_person_parties_path`
   - Path pattern: `/admin/parties/new/person` → `POST /admin/parties/person`
   - Primary return: `admin_party_path(party)`.

3. Create **TeamMember** shell linked to party.
   - Route helper: `new_admin_team_member_path`
   - Path pattern: `/admin/team_members/new`
   - Team360: optional `admin_team_member_team360_path` after engagement exists.

4. Create contractor **Engagement**.
   - Route helper: `new_admin_engagement_path` → `admin_engagement_path(engagement)`
   - Path pattern: `/admin/engagements/new` → `/admin/engagements/:id`
   - Team360: `admin_team_member_team360_path(team_member, engagement_id: engagement.id)`.

5. Add **Placement** and **Supervision** consistent with agency oversight model.
   - Route helpers: `new_admin_engagement_placement_path`, `new_admin_engagement_supervision_assignment_path`
   - Path patterns: `/admin/engagements/:engagement_id/placements/new`, `/admin/engagements/:engagement_id/supervision_assignments/new`

6. Record contractor **documents** and drive verification workflow.
   - Route helpers: `new_admin_document_record_path`, `verify_admin_document_record_path(record)` / `reject_admin_document_record_path(record)` when acting from queues
   - Path patterns: `/admin/document_records/new`, `POST /admin/document_records/:id/verify`, `POST /admin/document_records/:id/reject`

7. Assign contractor **compensation** plan to engagement.
   - Route helper: `new_admin_engagement_compensation_plan_assignment_path(engagement)`
   - Path pattern: `/admin/engagements/:engagement_id/compensation_assignments/new`

8. Review contractor readiness and obligations on **Team360**, including contractor charges context when applicable.
   - Route helper: `admin_team_member_team360_path(team_member, engagement_id: engagement.id)`
   - Supporting queue: `admin_contractor_charges_path` for fee posture separate from compensation rail.

## Team360 usage

Treat Team360 as the contractor **record hub**: contract status signals, documents, compensation summary hooks, and pathway into settlement-relevant history panels as those domains mature. Always pass `engagement_id` when validating contractor engagement specifics.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Team360 | Upload / fix contractor document | Team360 with same `engagement_id` when returns round-trip |
| Guided contractor flow | Save nested engagement resource | `admin_guided_individual_contractor_path` or engagement show |
| Document verification form | Verify or reject record | `admin_document_reviews_path` / `admin_document_workbench_path` or Team360 per `return_to` |
| Compensation assignment form | Save assignment | `admin_engagement_compensation_plan_assignments_path` or Team360 |

## Exceptions / branches

- Contractor transitions from individual to organization entity: migrate workflow to [contractor-onboarding-organization.md](./contractor-onboarding-organization.md); preserve Party history per product overview guidance.
- Agencies without supervision requirements may skip supervision assignments while retaining engagement validity—operations remain TC-29 gated for visibility, not UX-0 documentation.

## Reports vs workbenches

- Operational triage: **`admin_document_workbench_path`**, **`admin_document_alerts_path`**, **`admin_document_reviews_path`**.
- Contractor documentation overview: **`admin_reports_contractor_documentation_index_path`** (report-style listing—not a hub table).

## Out of scope / deferrals

- Legal or jurisdictional **classification determinations** (product stores **classification-supporting** evidence only—see product overview).
- Subcontractor modeling—see [subcontractor-onboarding.md](./subcontractor-onboarding.md) when relationships exist.

## Verification checklist

- [ ] Guided helper uses `admin_guided_individual_contractor_path` (distinct from employee + org contractors).
- [ ] Engagement-scoped URLs include `:engagement_id` segments matching `config/routes.rb`.
- [ ] Team360 links include `engagement_id` query param when validating contractor readiness.
- [ ] Document verification actions cite POST helpers `verify_admin_document_record_path` / `reject_admin_document_record_path`.
