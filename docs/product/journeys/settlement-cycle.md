# UX0-J07 — Contractor settlement cycle

## Status

current

## Primary persona

Finance / contractor ops administrator running contractor settlement cycles distinct from employee payroll.

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Create and advance **contractor settlement runs**, compose settlement lines, finalize runs, generate draft/final settlement exports, download artifacts, and observe outcomes alongside contractor engagements—without folding employee payroll mechanics into settlement rails.

Phase-dependent behaviors tie to Phase 5 downstream contracts: [phase-5-tc-23-a-downstream-dependency-contracts.md](../../roadmap/phase-5-payroll-time-leave/phase-5-tc-23-a-downstream-dependency-contracts.md).

## Entry points

- Post UX-1 hub: planned `/admin/payroll_settlement` → `admin_contractor_settlement_runs_path`.
- Existing fallback: direct `admin_contractor_settlement_runs_path`.
- Fast path: Team360 contractor engagement overview linking into settlement history contexts (`admin_team_member_team360_path`).

## Preconditions

- Contractor engagements configured with commission inputs appropriate to settlement calculations (see engagements nested routes such as `admin_engagement_revenue_inputs_path`—implementation-specific).

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Settlement runs index | `admin_contractor_settlement_runs_path` | `/admin/contractor_settlement_runs` |
| New settlement run | `new_admin_contractor_settlement_run_path` | `/admin/contractor_settlement_runs/new` |
| Settlement run show | `admin_contractor_settlement_run_path(run)` | `/admin/contractor_settlement_runs/:id` |
| Compose line | `compose_line_admin_contractor_settlement_run_path(run)` | `POST /admin/contractor_settlement_runs/:id/compose_line` |
| Finalize run | `finalize_admin_contractor_settlement_run_path(run)` | `POST /admin/contractor_settlement_runs/:id/finalize` |
| Void run | `void_admin_contractor_settlement_run_path(run)` | `POST /admin/contractor_settlement_runs/:id/void` |
| Mark paid | `mark_paid_admin_contractor_settlement_run_path(run)` | `POST /admin/contractor_settlement_runs/:id/mark_paid` |
| Draft settlement export | `draft_settlement_export_admin_contractor_settlement_run_path(run)` | `POST …/draft_settlement_export` |
| Final settlement export | `final_settlement_export_admin_contractor_settlement_run_path(run)` | `POST …/final_settlement_export` |
| Export download | `download_admin_contractor_settlement_export_path(export)` | `GET /admin/contractor_settlement_exports/:id/download` |
| Contractor charges queue | `admin_contractor_charges_path` | `/admin/contractor_charges` |
| Engagement revenue inputs (inputs to settlement math) | `admin_engagement_revenue_inputs_path(engagement)`, `new_admin_engagement_revenue_input_path(engagement)`, `calculate_commission_admin_engagement_revenue_input_path(engagement, revenue_input)` | `/admin/engagements/:engagement_id/revenue_inputs`, `/new`, `POST …/revenue_inputs/:id/calculate_commission` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |

## Happy path

1. Open settlement runs listing.
   - Route helper: `admin_contractor_settlement_runs_path`
   - Path pattern: `/admin/contractor_settlement_runs`

2. Create new settlement run when cycle opens.
   - Route helpers: `new_admin_contractor_settlement_run_path` → `POST admin_contractor_settlement_runs_path`
   - Path patterns: `/admin/contractor_settlement_runs/new` → `POST /admin/contractor_settlement_runs`

3. Compose settlement lines as agency workflow dictates (`compose_line` POST).

4. Finalize run once totals validated internally (`finalize` POST).

5. Generate **draft** / **final** settlement exports for outbound processors (`draft_settlement_export`, `final_settlement_export` POST helpers).

6. Download settlement export attachment (`download_admin_contractor_settlement_export_path`).

7. Transition lifecycle (`void`, `mark_paid`) only when operations approve—document blockers in run notes vs embedding logic here.

8. Cross-reference contractor obligations (`admin_contractor_charges_path`) before finalizing when deductions matter.

## Team360 usage

Team360 places settlement summaries alongside contractor engagement context—always pass `engagement_id` when multiple concurrent contractor engagements exist.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Settlement run show | Compose line / finalize | Same run show (`admin_contractor_settlement_run_path`) |
| Settlement run show | Draft/final export | Same show + downloads (`download_admin_contractor_settlement_export_path`) |
| Contractor charges queue | Resolve blocking charge | Return to queue index or run show depending on `return_to` |
| Team360 | Drill into settlement remediation | Team360 after fixes when returns configured |

## Exceptions / branches

- Engagement-level revenue input corrections use the nested routes enumerated above—cite via assembler/linking layers rather than duplicating formulas here.

## Reports vs workbenches

- Settlement listing (`admin_contractor_settlement_runs_path`) is operational CRUD today; future settlement prep workbench belongs on UX-4 lane per hub deny rules.

## Out of scope / deferrals

- Employee payroll flows (`payroll-cycle.md`).
- Legal interpretation of contractor classification.

## Verification checklist

- [ ] Member POST actions cite exact helper names (`finalize_admin_contractor_settlement_run_path`, etc.).
- [ ] Export download route matches `GET /admin/contractor_settlement_exports/:id/download`.
- [ ] Phase 5 downstream dependency doc linked.
