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

## Workbench vs dashboard vs reports

- **Workbench:** operational triage (e.g. document queues) with capped lists and drill-through to records.
- **Dashboard:** counts and quick links (not full report tables or evaluator sweeps).
- **Reports:** tabular exports and analysis; row actions should use shared helpers so drill-through stays consistent.

## Guided onboarding

Orchestration only: step launchers, links to existing resources, and prefilled params—not a new domain layer or a persisted wizard state machine for v1.
