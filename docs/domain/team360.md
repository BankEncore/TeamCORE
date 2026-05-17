# Team360 — read-only profile surface (Phase 3 / TC-10, TC-11)

## What Team360 is

Team360 is a **read-only administrative profile surface** assembled from authoritative **TeamMember**, **Party**, **Engagement**, organization (placement and supervision), document, and relationship records. It **does not own** lifecycle, compliance outcomes, relationship workflow status, or document readiness. Mutation remains in the underlying admin workflows and domain services.

Team360 **organizes and presents** authoritative data only. **No `team360s` table** and no persisted aggregate (**TC-3-D01**).

**Implementation:** [`Team360::ProfileAssembler`](../../app/services/team360/profile_assembler.rb) builds a [`Team360::ProfileSnapshot`](../../app/services/team360/profile_snapshot.rb) per request. **Admin UI:** [`Admin::Team360Controller`](../../app/controllers/admin/team360_controller.rb) (`GET /admin/team_members/:team_member_id/team360`).

## UX and styling

- **Product interaction and layout:** [`ux-design-guide.md`](../product/ux-design-guide.md) — Team360 page structure, panels, badges, two-column record layout.
- **CSS:** Use existing `tc-*` classes from [`app/assets/tailwind/teamcore/`](../../app/assets/tailwind/teamcore/) (imported via [`app/assets/tailwind/application.css`](../../app/assets/tailwind/application.css)). Do not fork a parallel design system.

## Panel taxonomy

| Type | Examples | Rule |
| --- | --- | --- |
| **Factual** | Identity, contacts, engagements list, placements, supervision, subcontractor relationship links | Render authoritative model attributes and associations. |
| **Computed** | Document readiness, alerts, requirement **outcomes** | Consume **`Documents::ReadinessEvaluator`** → **`Documents::ReadinessResult`** only for outcomes and alert severities ([`documents-compliance.md`](documents-compliance.md), [`document-alerts.md`](document-alerts.md)). |
| **Computed (workforce financials)** | Compensation summary, contractor charges & settlement (read model: `ProfileSnapshot#workforce_financial`) | No Team360-side writes. Payload from **`Team360::ProfileAssembler#build_workforce_financial`**; coarse **draw** visibility via **`User#team360_show_employee_draw_balance?`** until TC-29/30. Product rules: [developer brief §12](../roadmap/phase-4-developer-brief.md); modeling: [`compensation-financials.md`](compensation-financials.md), [`contractor-charges.md`](contractor-charges.md), [`contractor-settlement.md`](contractor-settlement.md); hub: [`workforce-financial-modeling.md`](workforce-financial-modeling.md). |
| **Computed (payroll time)** | Weekly timesheet row(s): status, projected vs approved overtime via **`Payroll::TimesheetOvertimePresenter`**, recent **`WeeklyTimesheetApprovalEvent`** rows | Read-only assembly in **`Team360::ProfileAssembler`**; no duplicated OT math (**ADR‑0003**). |
| **Placeholder** | Employee pay-period payroll totals rollups, leave balances, durable audit timeline | Static copy only; no dummy rows (**TC-3-D07**). |

## `focused_engagement` (display selection)

**`focused_engagement`** is an **in-memory display selection** used to choose which engagement drives **context-sensitive** panels (organization placement, supervision, document readiness, alerts, verification). It is:

- **Not persisted**
- **Not** “primary” for legal, payroll, or compliance authority

### Selection algorithm (default)

1. If `engagement_id` query param is present and belongs to this team member → use it.
2. Else if exactly one engagement with `status = active` → use it.
3. Else if **multiple** `active` engagements → expose all in the UI; default focus is the **lowest `id`** among active (deterministic tie-break).
4. Else if no active engagement → use the **most recent** non-`cancelled` engagement by `start_on` descending, then `id` descending.

Overrides and copy should make clear that changing focus **only** changes which engagement’s org/doc panels are shown.

## Document verification summary (TC-11)

The verification panel may show **linked `DocumentRecord`** attributes (e.g. status, verifier, dates, rejection reason) **as display only**.

**Rule:** Requirement satisfaction, missing/expired/expiring classification, blocking vs warning, and alert **severity** must come from **`ReadinessResult` / evaluator output** — not from ad-hoc interpretation of `DocumentRecord` in the view (**TC-3-D09**).

## Permissions (Phase 3)

Phase 3 uses existing **`Admin::BaseController`** agency scoping and coarse admin auth only (**TC-3-D05**). **Do not** implement panel-level masking or field-level RBAC here; that is **TC-29** (`TODO(TC-29)` where relevant).

## Related domain docs

- [`party-team-member.md`](party-team-member.md)
- [`engagement.md`](engagement.md), [`engagement-status.md`](engagement-status.md)
- [`organization.md`](organization.md) — Team360 organization context fields
- [`documents-compliance.md`](documents-compliance.md), [`document-alerts.md`](document-alerts.md), [`document-verification.md`](document-verification.md)
- [`subcontractor-relationships.md`](subcontractor-relationships.md)
- Workforce financial **read** surfaces (not workflow owner): [`compensation-financials.md`](compensation-financials.md), [`contractor-charges.md`](contractor-charges.md), [`contractor-settlement.md`](contractor-settlement.md), [`workforce-financial-modeling.md`](workforce-financial-modeling.md), [developer brief §12](../roadmap/phase-4-developer-brief.md)
- Operational lists and drill-through: [`operational-reporting.md`](operational-reporting.md)
