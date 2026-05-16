# Operational reporting (Phase 3 / TC-12)

## Purpose

Operational reporting provides **filterable lists and exception views** with **drill-through** to **Team360** and authoritative admin records. It is **not** a BI platform, **not** a workflow engine, and **not** a separate source of truth (**TC-3-D06**: no reporting snapshot tables in Phase 3).

**Implementation:** [`Admin::Reports::*`](../../app/controllers/admin/reports/) controllers; hub at **`GET /admin/reports`**.

## UX and styling

- **Layout:** Dense admin workbench per [`ux-design-guide.md`](../product/ux-design-guide.md) — tables (`tc-data-table`), filters (`05_forms` patterns), plain hub index (**not** a marketing-style dashboard).
- **CSS:** [`app/assets/tailwind/teamcore/`](../../app/assets/tailwind/teamcore/) — same `tc-*` vocabulary as Team360.

## Reports hub

The **hub** (`/admin/reports`) lists stable entry points so new reports can be added without rewiring primary nav.

**Minimum links (Phase 3):**

- Team member roster
- Engagement roster  
- Document compliance exceptions  
- *(Optional / PR F)* Contractor documentation exceptions  
- *(Optional / PR F)* Subcontractor relationships  

## Drill-through (**TC-3-D04**)

Report rows should link where useful to:

- **Team360:** `admin_team_member_team360_path(team_member)`  
- **Source records:** e.g. `admin_engagement_path`, `admin_document_record_path`, `admin_party_path`

## Filter vocabulary (**TC-3-D08**)

Reports use **existing domain vocabulary** for filters and query params:

- `engagements.status`, `engagements.relationship_type` — values from [`Engagement`](../../app/models/engagement.rb) constants / DB enums  
- Document alerts: `alert_type`, `severity` as produced by **`Documents::ReadinessEvaluator`** / **`Documents::AlertResult`**  
- `document_type` / `document_type_id`  
- Organization: `department_id`, `location_id`, `team_id`  
- Supervision: `supervisor_engagement_id` where applicable  
- **`as_of_date`:** point-in-time placement and evaluation (default `Date.current`)

**Do not** invent parallel “display statuses” or derived filter enums unless backed by an existing model/helper that **formats without re-interpreting** workflow state.

## Compliance and alerts

Document exception lists consume **`Documents::ReadinessEvaluator`** output — same contract as `Admin::DocumentAlertsController` and Team360 document panels ([`document-alerts.md`](document-alerts.md)).

## Permissions

Same as Team360 Phase 3: agency scope + existing admin auth; **TC-29** masking is out of scope (**TC-3-D05**).

## Related

- [`team360.md`](team360.md)  
- [`documents-compliance.md`](documents-compliance.md)  
- [`domain-map.md`](../product/domain-map.md) — Phase 3 row  
