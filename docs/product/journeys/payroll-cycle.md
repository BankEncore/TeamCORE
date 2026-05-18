# UX0-J06 — Payroll cycle (employees)

## Status

current

## Primary persona

Payroll administrator preparing employee payroll inputs for an external processor.

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Navigate pay periods, manage payroll input batches for the active cycle, progress batch lifecycle actions (recalculate, finalize, exports), and download artifacts—then reconcile history visible from engagement / Team360 contexts.

Phase-dependent behaviors (batch states, export columns, validation snapshots) follow Phase 5 contracts—see [phase-5-tc-23-a-downstream-dependency-contracts.md](../../roadmap/phase-5-payroll-time-leave/phase-5-tc-23-a-downstream-dependency-contracts.md).

## Entry points

- Post UX-1 hub: planned `/admin/payroll_settlement` → deep links to `admin_pay_periods_path`.
- Existing fallback: `admin_pay_periods_path` directly; optionally `admin_root_path` dashboard shortcuts when present.
- Fast path: `admin_search_path` → Team360 payroll panels → link back to pay period / batch routes when UI exposes them.

## Preconditions

- Pay periods generated for the processing window (`generate_admin_pay_periods_path` when used).
- Employee engagements supply compensation, time, and approved leave inputs per agency operations (see Phase 5 docs for downstream dependency framing).

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Pay periods index | `admin_pay_periods_path` | `/admin/pay_periods` |
| Pay period show | `admin_pay_period_path(pay_period)` | `/admin/pay_periods/:id` |
| Generate pay periods | `generate_admin_pay_periods_path` | `POST /admin/pay_periods/generate` |
| Close pay period | `close_admin_pay_period_path(pay_period)` | `POST /admin/pay_periods/:id/close` |
| Payroll batches index | `admin_pay_period_payroll_input_batches_path(pay_period)` | `/admin/pay_periods/:pay_period_id/payroll_input_batches` |
| Batch show | `admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `/admin/pay_periods/:pay_period_id/payroll_input_batches/:id` |
| Recalculate batch | `recalculate_admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `POST …/recalculate` |
| Finalize batch | `finalize_admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `POST …/finalize` |
| Reverse batch | `reverse_admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `POST …/reverse` |
| Complete final export | `complete_final_export_admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `POST …/complete_final_export` |
| Draft payroll export | `draft_payroll_export_admin_pay_period_payroll_input_batch_path(pay_period, batch)` | `POST …/draft_payroll_export` |
| Adjustments new/create | `new_admin_pay_period_payroll_input_batch_payroll_input_adjustment_path(pay_period, batch)`, `admin_pay_period_payroll_input_batch_payroll_input_adjustments_path(pay_period, batch)` | Nested `/payroll_input_adjustments` |
| Export download | `download_admin_payroll_export_path(payroll_export)` | `GET /admin/payroll_exports/:id/download` |
| Adjustment codes | `admin_payroll_adjustment_codes_path` | `/admin/payroll_adjustment_codes` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |

## Happy path

1. Open pay periods listing for cycle selection.
   - Route helper: `admin_pay_periods_path`
   - Path pattern: `/admin/pay_periods`

2. Review target **pay period** detail.
   - Route helper: `admin_pay_period_path(pay_period)`
   - Path pattern: `/admin/pay_periods/:id`

3. Open **payroll input batches** for that period.
   - Route helper: `admin_pay_period_payroll_input_batches_path(pay_period)`
   - Path pattern: `/admin/pay_periods/:pay_period_id/payroll_input_batches`

4. Drill into a specific batch to **recalculate** / **finalize** per operational checklist (exact eligibility gatekeeping lives in Phase 5 docs + implementation—not duplicated here).
   - Route helpers: `recalculate_admin_pay_period_payroll_input_batch_path`, `finalize_admin_pay_period_payroll_input_batch_path`
   - Path patterns: `POST /admin/pay_periods/:pay_period_id/payroll_input_batches/:id/recalculate|finalize`

5. Generate **draft payroll export** when preparing outbound files.
   - Route helper: `draft_payroll_export_admin_pay_period_payroll_input_batch_path(pay_period, batch)`
   - Path pattern: `POST …/draft_payroll_export`

6. Download export artifact when controller attaches **`PayrollExport`** records accessible via member route.
   - Route helper: `download_admin_payroll_export_path(payroll_export)`
   - Path pattern: `GET /admin/payroll_exports/:id/download`

7. Mark **complete final export** when operational cutoff satisfied (semantics per Phase 5 implementation).

8. Cross-check employee readiness issues via Team360 before locking batches when UX surfaces deep links (`admin_team_member_team360_path`).

## Team360 usage

Team360 anchors **employee payroll history summaries** and readiness cues; include `engagement_id` when multiple engagements confuse payroll applicability.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Pay period show | Create/open batch | `admin_pay_period_payroll_input_batches_path` → batch show |
| Batch show | Recalculate / finalize | Same batch show (`admin_pay_period_payroll_input_batch_path`) |
| Batch show | Draft export / complete export | Batch show with refreshed export list; downloads via `download_admin_payroll_export_path` |
| Team360 | Jump to payroll batch fixing flow | Return to Team360 after corrections when `return_to` points there |

## Exceptions / branches

- Manual adjustments: use nested `payroll_input_adjustments` routes (`new_admin_pay_period_payroll_input_batch_payroll_input_adjustment_path`).
- Pay period maintenance (`generate`, `close`) guarded operationally—still cite POST helpers when documenting automation/runbooks.

## Reports vs workbenches

- Payroll preparation remains CRUD + batch show surfaces today; future UX-4 **payroll prep workbench** must stay separate from `/admin/payroll_settlement` hub tables per UX guide hub deny list.

## Out of scope / deferrals

- Supervisor approvals detailed journey (`supervisor-approvals.md`).
- Employee self-service submission UX (`team-member-self-service.md`).

## Verification checklist

- [ ] Nested helpers include both `pay_period_id` and batch `:id` segments matching Rails route definitions.
- [ ] Export download references `download_admin_payroll_export_path`.
- [ ] Phase 5 dependency doc linked for downstream contracts.
