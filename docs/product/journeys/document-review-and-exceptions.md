# UX0-J05 — Document review & exceptions

## Status

current

## Primary persona

Agency administrator focused on **documents and compliance operations** (verification, rejections, exceptions).

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Triage **document requirement outcomes** and **readiness-derived alerts** (source: readiness evaluator output—e.g. missing, expired, expiring soon, pending verification where applicable), complete **document record** verification actions (`verify` / `reject` / `void`), and return operators to the correct operational surfaces—usually workbench queues or Team360—with preserved engagement context.

## Domain vocabulary (readiness vs artifacts)

Use precise layers so journeys stay aligned with documents/compliance contracts (evaluator as source of truth for readiness semantics):

- **Requirement outcome / readiness:** describe gaps using evaluator-facing concepts (e.g. requirement not satisfied, expired, expiring soon, pending verification, readiness `ready` / `not_ready` / `warning` / `not_applicable` as modeled)—do not treat the UI queue as the authority for readiness math.
- **`DocumentRecord` review workflow:** use record-level statuses such as submitted → verified / rejected / voided for actions taken on stored artifacts.
- **Team360:** aggregates readiness signals for orientation; mutations remain on owning routes (`admin_document_record_*`, verify/reject POSTs).

## Entry points

- Post UX-1 hub: planned `/admin/documents` launcher → primary destinations below (UX-1 not shipped at UX-0).
- Existing fallback: `admin_document_workbench_path`, `admin_document_alerts_path`, `admin_document_reviews_path`, `admin_document_records_path`.
- Fast path: `admin_search_path` → open Team360 → drill into document panel affordances that deep-link to `admin_document_record_path`.

## Preconditions

- **Alerts / workbench rows** may reflect readiness evaluator outputs even when no `DocumentRecord` exists yet; **reviews** typically imply submitted records awaiting verification.
- Queues may be empty—honor empty-state guidance per UX guide.

## Authoritative routes used

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Document workbench | `admin_document_workbench_path` | `/admin/document_workbench` |
| Alerts queue | `admin_document_alerts_path` | `/admin/document_alerts` |
| Reviews queue | `admin_document_reviews_path` | `/admin/document_reviews` |
| Records index | `admin_document_records_path` | `/admin/document_records` |
| New record | `new_admin_document_record_path` | `/admin/document_records/new` |
| Record show / edit | `admin_document_record_path(record)`, `edit_admin_document_record_path(record)` | `/admin/document_records/:id`, `/admin/document_records/:id/edit` |
| Verify | `verify_admin_document_record_path(record)` | `POST /admin/document_records/:id/verify` |
| Reject | `reject_admin_document_record_path(record)` | `POST /admin/document_records/:id/reject` |
| Void | `void_admin_document_record_path(record)` | `POST /admin/document_records/:id/void` |
| Requirement maintenance | `admin_document_requirements_path`, `new_admin_document_requirement_path` | `/admin/document_requirements`, `/admin/document_requirements/new` |
| Type maintenance | `admin_document_types_path` | `/admin/document_types` |
| Compliance report | `admin_reports_document_compliance_index_path` | `/admin/reports/document_compliance` |
| Contractor documentation report | `admin_reports_contractor_documentation_index_path` | `/admin/reports/contractor_documentation` |
| Team360 | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |

## Happy path

1. Open **document workbench** for capped triage lists.
   - Route helper: `admin_document_workbench_path`
   - Path pattern: `/admin/document_workbench`
   - Primary return: remain on workbench index unless drilling down.

2. Sweep **alerts** / **reviews** queues for requirement gaps (readiness/evaluator-driven) or submitted records needing verification.
   - Route helpers: `admin_document_alerts_path`, `admin_document_reviews_path`
   - Path patterns: `/admin/document_alerts`, `/admin/document_reviews`

3. From a queue row, either open an existing **`DocumentRecord`** or start intake when no satisfactory artifact exists yet.
   - Existing record: `admin_document_record_path(record)` — `/admin/document_records/:id`
   - New record intake: `new_admin_document_record_path` — `/admin/document_records/new`

4. Apply **`DocumentRecord` verify** or **reject** actions (POST member routes)—these are record workflow transitions, distinct from readiness rollup refresh.
   - Route helpers: `verify_admin_document_record_path(record)`, `reject_admin_document_record_path(record)`
   - Path patterns: `POST /admin/document_records/:id/verify`, `POST /admin/document_records/:id/reject`

5. Return to **Team360** with engagement focus when the originating context was a person-centric review (`team360_return_to` / `return_to` per UX guide).

6. Optionally validate cohort-level compliance via **reports** (not hub surfaces).
   - Route helper: `admin_reports_document_compliance_index_path`
   - Path pattern: `/admin/reports/document_compliance`

## Team360 usage

Use Team360 when reviewing **readiness summary** and drill-through for a **specific team member + engagement**. Prefer URLs that include `engagement_id` when alerts stem from engagement-scoped requirements. Treat panels as **read/orientation**; authoritative verification remains on document record routes.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Document workbench | Drill into record | `admin_document_record_path`; filters preserved when UX-4 supports it |
| Team360 | Launch document fix flow | Team360 with same `engagement_id` after save when returns honored |
| Reviews / alerts | Verify document | `admin_document_reviews_path` / `admin_document_alerts_path` or workbench |
| Record detail | Reject / void | Parent queue (`admin_document_reviews_path`) or Team360 per `return_to` |

## Exceptions / branches

- **Maintenance**: adjusting types/requirements uses `admin_document_types_path` / `admin_document_requirements_path`—configuration lane, not daily verification lane.

## Reports vs workbenches

- Workbench + queues = operational triage (cap lists).
- `admin_reports_document_compliance_index_path` + contractor documentation report = analysis exports—not UX-1 hub tables.

## Out of scope / deferrals

- Role-aware restriction messaging pending **TC-29** (verification privileges described at product level in overview).

## Verification checklist

- [ ] Every POST action cites explicit helper (`verify_`, `reject_`, `void_`).
- [ ] Distinction between workbench/queues vs `/admin/reports/document_compliance` documented.
- [ ] Team360 return expectations mention `team360_return_to`.
- [ ] Copy distinguishes **readiness / requirement outcomes** (evaluator) from **`DocumentRecord` review** transitions (`verify` / `reject` / `void`).
