# UX0-J01 — Employee onboarding

## Status

current

## Primary persona

Agency administrator or HR staff onboarding a new **employee** (person workforce type).

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Create identity and workforce records, establish an active **employee engagement** with placement and supervision, attach required **documents**, assign **compensation**, and confirm readiness from **Team360**—without a mega-form.

## Entry points

- Post UX-1 hub: planned `/admin/onboarding` launcher → guided employee checklist (`admin_guided_employee_path`).
- Existing fallback: `admin_guided_setup_path` → hub, then `admin_guided_employee_path`; or `new_admin_team_member_path` / Party-first creation via `admin_new_person_party_path`.
- Fast path: `admin_search_path` → matching team member → `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` once an engagement exists.

## Preconditions

- Agency context selected (existing admin behavior).
- Operator knows whether the person already exists as a **Party** or needs a new person record.

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Guided hub | `admin_guided_setup_path` | `/admin/guided` |
| Guided employee flow | `admin_guided_employee_path` | `/admin/guided/employee` — includes derived setup checklist (`#guided-onboarding-checklist`; mirrors Team360 engagement checklist signals when party + engagement exist; see [UX design guide](../ux-design-guide.md)). |
| New person party | `admin_new_person_party_path` | `/admin/parties/new/person` |
| Create person party | `admin_person_parties_path` | `POST /admin/parties/person` |
| Party hub (identity) | `admin_party_path(party)` | `/admin/parties/:id` |
| New team member | `new_admin_team_member_path` | `/admin/team_members/new` |
| Team member show | `admin_team_member_path(team_member)` | `/admin/team_members/:id` |
| New engagement | `new_admin_engagement_path` | `/admin/engagements/new` |
| Engagement show | `admin_engagement_path(engagement)` | `/admin/engagements/:id` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |
| Placements | `admin_engagement_placements_path(engagement)` | `/admin/engagements/:engagement_id/placements` |
| New placement | `new_admin_engagement_placement_path(engagement)` | `/admin/engagements/:engagement_id/placements/new` |
| Supervision | `admin_engagement_supervision_assignments_path(engagement)` | `/admin/engagements/:engagement_id/supervision_assignments` |
| New supervision assignment | `new_admin_engagement_supervision_assignment_path(engagement)` | `/admin/engagements/:engagement_id/supervision_assignments/new` |
| Compensation assignments | `admin_engagement_compensation_plan_assignments_path(engagement)` | `/admin/engagements/:engagement_id/compensation_assignments` |
| New compensation assignment | `new_admin_engagement_compensation_plan_assignment_path(engagement)` | `/admin/engagements/:engagement_id/compensation_assignments/new` |
| Document record create | `new_admin_document_record_path` | `/admin/document_records/new` |
| Document workbench | `admin_document_workbench_path` | `/admin/document_workbench` |

## Happy path

1. Open guided employee onboarding.
   - Intent: Use orchestration entry points and deep links instead of memorizing CRUD order.
   - Route helper: `admin_guided_employee_path`
   - Path pattern: `/admin/guided/employee`
   - **Setup checklist (UX-3):** `#guided-onboarding-checklist` summarizes party → team member → engagement shell, then (when an engagement exists for this flow’s relationship type) rows aligned with `Admin::EngagementSetupChecklistPresenter` plus an activation readiness row with Team360. Preserve query params such as `party_id` / `team_member_id` so CTAs and returns stay on the same guided URL.
   - Team360: not yet unless returning to an existing profile.
   - Primary return destination after step: same guided screen or `admin_guided_setup_path` when exiting hub scope.

2. Ensure a **Party** person exists (if greenfield).
   - Intent: Anchor identity before workforce shell.
   - Route helper: `admin_new_person_party_path` → submit via `admin_person_parties_path`
   - Path pattern: `/admin/parties/new/person` → `POST /admin/parties/person`
   - Team360: N/A.
   - Primary return destination after step: `admin_party_path(party)` or continue guided flow per UI links.

3. Create or open **TeamMember** for the employee.
   - Intent: Establish workforce record linked to party.
   - Route helper: `new_admin_team_member_path` / `admin_team_member_path(team_member)`
   - Path pattern: `/admin/team_members/new`, `/admin/team_members/:id`
   - Team360: optional preview via `admin_team_member_team360_path` once minimum associations exist.
   - Primary return destination after step: `admin_team_member_path(team_member)`.

4. Create **Engagement** for employment relationship.
   - Intent: Engagement becomes anchor for placement, supervision, documents, compensation, payroll inputs.
   - Route helper: `new_admin_engagement_path` → `admin_engagement_path(engagement)`
   - Path pattern: `/admin/engagements/new` → `/admin/engagements/:id`
   - Key params: associations to team member per form (implementation-defined IDs).
   - Team360: `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` to confirm engagement-focused panels.
   - Primary return destination after step: `admin_engagement_path(engagement)` or Team360.

5. Add **Placement** (organization placement / reporting context).
   - Intent: Satisfy org structure prerequisites for readiness.
   - Route helper: `new_admin_engagement_placement_path(engagement)`
   - Path pattern: `/admin/engagements/:engagement_id/placements/new`
   - Team360: same engagement-focused Team360 URL as step 4.
   - Primary return destination after step: `admin_engagement_placement_path(engagement, placement)` or placements index.

6. Assign **Supervision**.
   - Intent: Establish supervisory relationships required for operational workflows.
   - Route helper: `new_admin_engagement_supervision_assignment_path(engagement)`
   - Path pattern: `/admin/engagements/:engagement_id/supervision_assignments/new`
   - Team360: engagement-focused Team360.
   - Primary return destination after step: supervision assignment show or index under engagement.

7. Attach / verify **Documents** (requirements-driven).
   - Intent: Close compliance gaps visible on Team360 and document workbench queues.
   - Route helper: `new_admin_document_record_path` (often reached via guided or Team360 drill-through)
   - Path pattern: `/admin/document_records/new`
   - Team360: return hub after uploads when drill-through supplies `team360_return_to` / `return_to` per [UX design guide](../ux-design-guide.md).
   - Primary return destination after step: `admin_document_record_path(record)` or Team360.

8. Assign **Compensation plan** to engagement.
   - Intent: Unlock payroll preparation inputs downstream.
   - Route helper: `new_admin_engagement_compensation_plan_assignment_path(engagement)`
   - Path pattern: `/admin/engagements/:engagement_id/compensation_assignments/new`
   - Team360: engagement-focused Team360 for compensation summary signals.
   - Primary return destination after step: `admin_engagement_compensation_plan_assignments_path(engagement)`.

9. Confirm readiness on **Team360**.
   - Intent: Single place to validate “what’s missing” across domains.
   - Route helper: `admin_team_member_team360_path(team_member, engagement_id: engagement.id)`
   - Path pattern: `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id`
   - Primary return destination after step: remain on Team360 or deep-link to targeted fixes.

## Team360 usage

Align with the UX guide: Team360 is the **record hub** for reviewing state, readiness, next actions, and returning after focused edits. Pass `engagement_id` whenever placement, supervision, documents, compensation, or payroll context must stay pinned to one engagement.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Team360 | Open “add document” (or equivalent drill-through) | Team360 focused on same `engagement_id` when `team360_return_to` / `return_to` round-trip is honored |
| Guided employee onboarding | Save focused child record (placement, supervision, document, compensation) | Guided flow with checklist (`admin_guided_employee_path` + `#guided-onboarding-checklist`) or Team360 (`admin_team_member_team360_path`) per `return_to` / `team360_return_to` |
| Engagement nested form | Save placement / supervision / compensation | Parent engagement show (`admin_engagement_path`) or Team360 with same engagement |
| Document record form | Save upload / metadata | Document record show or Team360 per form defaults and `return_to` |

## Exceptions / branches

- **Existing party**: skip person creation; start at `admin_party_path` or search (`admin_search_path`).
- **Rehire / second engagement**: create new engagement (`new_admin_engagement_path`) while preserving party identity; historical engagements remain on Team360 engagement history panels.

## Reports vs workbenches

- Use **`admin_document_workbench_path`** and **`admin_document_alerts_path`** / **`admin_document_reviews_path`** for operational triage—not the UX-1 onboarding hub.
- Roster-style verification belongs in **`admin_reports_team_members_path`** or **`admin_reports_engagements_path`**, not on a hub surface.

## Out of scope / deferrals

- Dedicated supervisor **self-service** approvals hub (see `supervisor-approvals.md`, `future`).
- Role-aware nav visibility (**TC-29**); UX-0 stays IA-only per [UX design guide](../ux-design-guide.md).

## Verification checklist

- [ ] Guided entry uses `admin_guided_employee_path` with concrete fallbacks documented above; checklist panel `#guided-onboarding-checklist` reflects selection + engagement when present.
- [ ] Engagement-scoped routes include `:engagement_id` segments exactly as listed.
- [ ] Team360 URLs include `engagement_id` when validating onboarding readiness.
- [ ] Return expectations cite `return_to` / `team360_return_to` behavior from the UX guide.
