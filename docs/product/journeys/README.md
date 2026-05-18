# Persona-centered journeys (UX-0)

UX-0 creates nine journey files: seven current/conditional journey documents plus two future/deferred stubs.

These journeys anchor **workspace entry → concrete admin routes → Team360 (`engagement_id`) → return navigation** using today’s Rails routing. They pair with the IA lock and hub discipline in the [UX design guide](../ux-design-guide.md).

UX-0 and UX-1 define information architecture only. Workspace labels may reference personas, but navigation visibility remains shared for all admins until TC-29 introduces role-aware authorization.

## Personas and navigation visibility

In each journey file, **Primary persona** describes intended operational orientation (who the prose is written for). It does **not** imply role-based navigation, queue scoping, or feature hiding until **TC-29** introduces role-aware authorization. Until then, all admins share the same planned workspace labels and route inventory.

## Journey index

| Journey | File | Status |
| ------- | ---- | ------ |
| Employee onboarding | [employee-onboarding.md](./employee-onboarding.md) | `current` |
| Individual contractor onboarding | [contractor-onboarding-individual.md](./contractor-onboarding-individual.md) | `current` |
| Contractor organization onboarding | [contractor-onboarding-organization.md](./contractor-onboarding-organization.md) | `current` |
| Subcontractor onboarding | [subcontractor-onboarding.md](./subcontractor-onboarding.md) | `conditional` |
| Document review & exceptions | [document-review-and-exceptions.md](./document-review-and-exceptions.md) | `current` |
| Payroll cycle | [payroll-cycle.md](./payroll-cycle.md) | `current` |
| Contractor settlement cycle | [settlement-cycle.md](./settlement-cycle.md) | `current` |
| Supervisor approvals | [supervisor-approvals.md](./supervisor-approvals.md) | `future` |
| Team member self-service | [team-member-self-service.md](./team-member-self-service.md) | `deferred` |

Payroll and settlement journeys stay `current`; phase-dependent behavior is called out in prose and linked to Phase 5 contracts.

## Journey status vocabulary

| Status | Meaning |
| ------ | ------- |
| `current` | Supported by existing admin routes and intended to guide UX-1/UX-4 surfaces. |
| `conditional` | Supported only when the underlying relationship/configuration exists; may not apply to all agencies. |
| `future` | Product-intended journey, but dependent on later workspace/permission work. |
| `deferred` | Not part of current admin UX implementation; retained as planning input for a future spike. |

## Route inventory baseline

Primary source: `config/routes.rb`

This inventory includes **UX-1 workspace hub** routes (`GET /admin/people`, `/admin/onboarding`, `/admin/documents`, `/admin/payroll_settlement`, `/admin/time_leave`, `/admin/configuration`).

After UX-1 merges to main, set: `Last verified against: BankEncore/TeamCORE main @ <commit-sha>`.

Refresh when admin routes change materially.

## Route helper appendix (admin)

Abbreviated inventory derived from `config/routes.rb` at the baseline SHA. Prefer `bin/rails routes` when verifying edge cases.

| Area | Representative helpers | Path patterns |
| ---- | ------------------------ | ------------- |
| Dashboard | `admin_root_path` | `/admin` |
| Workspace hubs (UX-1) | `admin_people_hub_path`, `admin_onboarding_hub_path`, `admin_documents_hub_path`, `admin_payroll_settlement_hub_path`, `admin_time_leave_hub_path`, `admin_configuration_hub_path` | `/admin/people`, `/admin/onboarding`, `/admin/documents`, `/admin/payroll_settlement`, `/admin/time_leave`, `/admin/configuration` |
| Search | `admin_search_path` | `/admin/search` |
| Guided onboarding | `admin_guided_setup_path`, `admin_guided_employee_path`, `admin_guided_individual_contractor_path`, `admin_guided_contractor_organization_path`, `admin_guided_subcontractor_path` | `/admin/guided`, `/admin/guided/employee`, `/admin/guided/individual_contractor`, `/admin/guided/contractor_organization`, `/admin/guided/subcontractor` — each workforce guided URL renders an in-page **setup checklist** (`#guided-onboarding-checklist`; UX-3). The guided hub itself has no checklist panel. |
| Parties | `admin_parties_path`, `admin_party_path(party)`, `admin_new_person_party_path`, `admin_person_parties_path`, `admin_new_organization_party_path`, `admin_organization_parties_path` | `/admin/parties`, `/admin/parties/:id`, `/admin/parties/new/person`, `POST /admin/parties/person`, `/admin/parties/new/organization`, `POST /admin/parties/organization` |
| Team members | `admin_team_members_path`, `admin_team_member_path(team_member)`, `new_admin_team_member_path`, `edit_admin_team_member_path` | `/admin/team_members`, `/admin/team_members/:id`, `/admin/team_members/new`, `/admin/team_members/:id/edit` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: …)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |
| Engagements | `admin_engagements_path`, `admin_engagement_path(engagement)`, `new_admin_engagement_path`, `edit_admin_engagement_path` | `/admin/engagements`, `/admin/engagements/:id`, `/admin/engagements/new`, `/admin/engagements/:id/edit` |
| Placements | `admin_engagement_placements_path(engagement)`, `new_admin_engagement_placement_path(engagement)`, `admin_engagement_placement_path(engagement, placement)` | `/admin/engagements/:engagement_id/placements`, `/new`, `/:id` |
| Supervision | `admin_engagement_supervision_assignments_path(engagement)`, `new_admin_engagement_supervision_assignment_path(engagement)`, `admin_engagement_supervision_assignment_path(engagement, assignment)` | `/admin/engagements/:engagement_id/supervision_assignments`, `/new`, `/:id` |
| Compensation assignments | `admin_engagement_compensation_plan_assignments_path(engagement)`, `new_admin_engagement_compensation_plan_assignment_path(engagement)` | `/admin/engagements/:engagement_id/compensation_assignments`, `/new` |
| Documents | `admin_document_workbench_path`, `admin_document_alerts_path`, `admin_document_reviews_path`, `admin_document_records_path`, `new_admin_document_record_path`, `admin_document_record_path(record)`, `verify_admin_document_record_path(record)`, `reject_admin_document_record_path(record)` | `/admin/document_workbench`, `/admin/document_alerts`, `/admin/document_reviews`, `/admin/document_records`, `/new`, `/:id`, `POST …/verify`, `POST …/reject` |
| Document config | `admin_document_types_path`, `admin_document_requirements_path` | `/admin/document_types`, `/admin/document_requirements` |
| Pay periods & payroll batches | `admin_pay_periods_path`, `admin_pay_period_path(pay_period)`, `admin_pay_period_payroll_input_batches_path(pay_period)`, `admin_pay_period_payroll_input_batch_path(pay_period, batch)`, `finalize_admin_pay_period_payroll_input_batch_path(…)`, `draft_payroll_export_admin_pay_period_payroll_input_batch_path(…)`, `complete_final_export_admin_pay_period_payroll_input_batch_path(…)` | `/admin/pay_periods`, `/admin/pay_periods/:id`, nested `payroll_input_batches`, member POST actions |
| Payroll export download | `download_admin_payroll_export_path(payroll_export)` | `GET /admin/payroll_exports/:id/download` |
| Contractor settlement | `admin_contractor_settlement_runs_path`, `admin_contractor_settlement_run_path(run)`, `draft_settlement_export_admin_contractor_settlement_run_path(run)`, `final_settlement_export_admin_contractor_settlement_run_path(run)`, `finalize_admin_contractor_settlement_run_path(run)` | `/admin/contractor_settlement_runs`, `/:id`, member POST actions |
| Settlement export download | `download_admin_contractor_settlement_export_path(export)` | `GET /admin/contractor_settlement_exports/:id/download` |
| Time & leave | `admin_weekly_timesheets_path`, `admin_weekly_timesheet_path(sheet)`, `approve_admin_weekly_timesheet_path(sheet)`, `admin_leave_requests_path`, `approve_admin_leave_request_path(request)`, `admin_leave_types_path` | `/admin/weekly_timesheets`, `/admin/weekly_timesheets/:id`, `POST …/approve`, `/admin/leave_requests`, `POST …/approve`, `/admin/leave_types` |
| Contractor charges queue | `admin_contractor_charges_path` | `/admin/contractor_charges` |
| Reports | `admin_reports_root_path`, `admin_reports_team_members_path`, `admin_reports_engagements_path`, `admin_reports_document_compliance_index_path`, `admin_reports_contractor_documentation_index_path`, `admin_reports_subcontractors_path` | `/admin/reports`, `/admin/reports/team_members`, `/admin/reports/engagements`, `/admin/reports/document_compliance`, `/admin/reports/contractor_documentation`, `/admin/reports/subcontractors` |
| Reference / configuration CRUD | `admin_agencies_path`, `admin_departments_path`, `admin_locations_path`, `admin_teams_path`, `admin_compensation_plans_path`, `admin_payroll_adjustment_codes_path` | `/admin/agencies`, `/admin/departments`, `/admin/locations`, `/admin/teams`, `/admin/compensation_plans`, `/admin/payroll_adjustment_codes` |
