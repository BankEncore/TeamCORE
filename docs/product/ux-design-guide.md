# UX design guide (Phase 4.5)

This document captures cross-cutting admin UX conventions introduced in Phase 4.5. Prefer updating this file when changing navigation or return behavior instead of scattering one-off comments.

## Admin return navigation contract

Used for post-save redirects and deep-linking back to **Team360** or another admin screen without open redirects.

| Param | Meaning |
| ----- | ------- |
| `return_to` | Safe admin-local path (optional query string). After save, redirect here if valid. |
| `team360_return_to` | Optional explicit Team360 (or other admin) destination; takes precedence over `return_to` when both are present and valid. |
| `engagement_id` | On Team360, focuses panels and readiness on one engagement (query param on `GET /admin/team_members/:id/team360`). |
| `from` | Reserved for display hints only; **never** use for redirects. |

**Rules (server-side):**

- Only same-host URLs whose path is `/admin` or starts with `/admin/` are allowed.
- Reject absolute external URLs, protocol-relative URLs (`//…`), and paths outside `/admin`.
- Invalid values are ignored; use the controller’s normal default redirect.
- Prefer hidden fields on forms to round-trip `return_to` rather than storing arbitrary paths in session.

**Implementation:** [`Admin::ReturnNavigation`](../../app/controllers/concerns/admin/return_navigation.rb), `ApplicationHelper#tc_admin_return_navigation_hidden_fields`, `ApplicationHelper#tc_team360_url`.

## Party Hub

Party **show** is the identity hub: contact methods, workforce (team members), engagements, relationships, tagged documents. Create/edit screens stay separate; no mega-form on a single party page.

## Panels and empty states

New admin surfaces should include useful empty states: what the area is for, why it might be empty, and the next action. Match tone and density used on Party Hub.

## No mega-form

Do not combine Party, TeamMember, Engagement, Placement, Supervision, Documents, and Compensation in one Giant form. Use focused CRUD screens, prefilled links, and thin orchestration (e.g. guided onboarding) instead.

## Workbench vs dashboard vs reports vs hub

- **Hub (workspace shell, UX-1):** orientation plus launchers into existing CRUD, workbenches, and reports. Thin `show` actions; not a new domain layer.
- **Workbench:** operational triage (e.g. document queues) with capped lists and drill-through to records.
- **Dashboard:** counts and quick links (not full report tables or evaluator sweeps).
- **Reports:** tabular exports and analysis; row actions should use shared helpers so drill-through stays consistent.

**Hub pages may contain:**

- Orientation copy  
- Primary launchers  
- Cheap counts  
- Links to workbenches / reports / CRUD  
- Empty-state guidance  

**Hub pages must not contain:**

- Full operational report tables  
- Long evaluator sweeps across all engagements  
- Workflow state machines  
- Role-specific permission logic before TC-29  

## TC-29 / IA-only navigation

UX-0 and UX-1 define information architecture only. Workspace labels may reference personas, but navigation visibility remains shared for all admins until TC-29 introduces role-aware authorization.

## Primary workspace navigation taxonomy (UX-0 lock)

Primary nav labels for UX-1 (IA-first, **all admins** until TC-29):

- Dashboard · People · Onboarding · Documents · Payroll & Settlement · Time & Leave · Reports · Configuration  

**Search** is a **global header affordance** (UX-1), not a nav section. **Reference** (or an equivalent secondary grouping) holds legacy model indexes and deep CRUD entry points.

For persona-centered flows, route helpers, and return expectations locked to today’s Rails routes, see [Persona-centered journeys](./journeys/README.md).

## Planned hub routes → primary destinations

The workspace hub paths below are **planned for UX-1**; they are not defined in `config/routes.rb` at UX-0 closure. Until those hubs ship, use the **existing** route helpers and path patterns in the right-hand column (verified against `config/routes.rb`).

| Planned hub (UX-1) | Path pattern | Primary existing destinations (representative helpers) |
| ------------------ | ------------ | ------------------------------------------------------ |
| People | `/admin/people` | `admin_team_members_path`, `admin_search_path`, `admin_guided_setup_path`, `admin_document_workbench_path` |
| Onboarding | `/admin/onboarding` | `admin_guided_setup_path`, `admin_guided_employee_path`, `admin_guided_individual_contractor_path`, `admin_guided_contractor_organization_path`, `admin_guided_subcontractor_path` |
| Documents | `/admin/documents` | `admin_document_workbench_path`, `admin_document_alerts_path`, `admin_document_reviews_path`, `admin_document_records_path`, `admin_reports_document_compliance_index_path` |
| Payroll & Settlement | `/admin/payroll_settlement` | `admin_pay_periods_path`, `admin_contractor_settlement_runs_path`, `admin_payroll_adjustment_codes_path` |
| Time & Leave | `/admin/time_leave` | `admin_weekly_timesheets_path`, `admin_leave_requests_path`, `admin_leave_types_path` |
| Reports | `/admin/reports` (conventional; today use namespace root) | `admin_reports_root_path`, `admin_reports_team_members_path`, `admin_reports_engagements_path` |
| Configuration | `/admin/configuration` | `admin_agencies_path`, `admin_departments_path`, `admin_locations_path`, `admin_teams_path`, `admin_compensation_plans_path`, `admin_document_types_path`, `admin_document_requirements_path` |

## `/admin/onboarding` vs `/admin/guided`

UX-1 will introduce `/admin/onboarding` as a thin workspace hub. It will not replace `/admin/guided`. Existing `/admin/guided/*` routes remain the implementation routes for guided onboarding flows.

Current guided URLs (reference):

- `admin_guided_setup_path` → `/admin/guided`  
- `admin_guided_employee_path` → `/admin/guided/employee`  
- `admin_guided_individual_contractor_path` → `/admin/guided/individual_contractor`  
- `admin_guided_contractor_organization_path` → `/admin/guided/contractor_organization`  
- `admin_guided_subcontractor_path` → `/admin/guided/subcontractor`  

## Team360 usage (journey + UX-1 handoff)

When a journey centers on a person/team member, Team360 is the record hub.

Use Team360 when:

- reviewing current state  
- checking readiness  
- choosing the next action  
- returning after focused edits  

Use `engagement_id` when a specific engagement drives placement, supervision, documents, compensation, payroll, or settlement context.

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Open Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |

Post-save flows should reference `return_to` / `team360_return_to` per [Admin return navigation contract](#admin-return-navigation-contract). Journey-specific return tables live in [Persona-centered journeys](./journeys/README.md).

## Return navigation expectations (product convention)

UX-1 and UX-2 should align implementations with the **Return navigation expectations** tables in each non-deferred journey. Preserve safe round-tripping via `return_to` and `team360_return_to`; reject non-`/admin` destinations server-side as documented above.

## Guided onboarding

Orchestration only: step launchers, links to existing resources, and prefilled params—not a new domain layer or a persisted wizard state machine for v1.
