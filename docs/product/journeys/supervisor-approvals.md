# UX0-J08 — Supervisor approvals

## Status

future

## Primary persona

Supervisor responsible for **employee timesheets** and **leave requests** (agency-modeled reporting relationships).

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29 enables supervisor-scoped surfaces.*

## Goal

Provide a future workspace-native approvals journey that centralizes supervisor obligations without duplicating evaluator logic. Until workspace hubs and supervisor-aware authorization ship, admins rely on **existing interim routes** listed below.

## Entry points (intent after UX-1 / UX-4)

- Planned supervisor approvals workbench / hub surfaces **do not exist** at UX-0 baseline (`config/routes.rb`).
- Interim entry today: `admin_weekly_timesheets_path`, `admin_leave_requests_path`, optionally Team360 drill-through when presenters expose approval shortcuts (`admin_team_member_team360_path`).

## Preconditions

- **TC-29** must introduce trustworthy supervisor actors before hiding navigation or auto-filtering queues per supervisor persona (UX-0 stays IA-only).

## Authoritative routes used (interim)

| Purpose | Route helper | Path pattern |
| ------- | ------------ | ------------ |
| Weekly timesheets index | `admin_weekly_timesheets_path` | `/admin/weekly_timesheets` |
| Weekly timesheet show | `admin_weekly_timesheet_path(timesheet)` | `/admin/weekly_timesheets/:id` |
| Approve timesheet | `approve_admin_weekly_timesheet_path(timesheet)` | `POST /admin/weekly_timesheets/:id/approve` |
| Send back timesheet | `send_back_admin_weekly_timesheet_path(timesheet)` | `POST /admin/weekly_timesheets/:id/send_back` |
| Reopen timesheet | `reopen_admin_weekly_timesheet_path(timesheet)` | `POST /admin/weekly_timesheets/:id/reopen` |
| Leave requests index | `admin_leave_requests_path` | `/admin/leave_requests` |
| Leave request show | `admin_leave_request_path(request)` | `/admin/leave_requests/:id` |
| Approve leave | `approve_admin_leave_request_path(request)` | `POST /admin/leave_requests/:id/approve` |
| Reject leave | `reject_admin_leave_request_path(request)` | `POST /admin/leave_requests/:id/reject` |
| Submit leave | `submit_admin_leave_request_path(request)` | `POST /admin/leave_requests/:id/submit` |
| Cancel leave | `cancel_admin_leave_request_path(request)` | `POST /admin/leave_requests/:id/cancel` |
| Reopen leave | `reopen_admin_leave_request_path(request)` | `POST /admin/leave_requests/:id/reopen` |
| Team360 context | `admin_team_member_team360_path(team_member, engagement_id: engagement.id)` | `/admin/team_members/:team_member_id/team360?engagement_id=:engagement_id` |

## Happy path

Deferred until UX-4B supervisor workbench + TC-29 authorization land; interim operators continue using the routes above directly.

## Team360 usage

Future presenter-driven **Next Actions** should deep-link supervisors into timesheet / leave surfaces while preserving `team360_return_to` (`admin_team_member_team360_path` expectations mirror other journeys).

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| Team360 (future) | Approve timesheet / leave | Team360 with same `engagement_id` when returns configured |
| Timesheet show | Approve / send back | `admin_weekly_timesheet_path` or index per controller defaults |
| Leave request show | Approve / reject | `admin_leave_request_path` or index |

## Exceptions / branches

- Contractors do not submit time in MVP per product overview—this journey targets employee supervisors only.

## Reports vs workbenches

- Future UX-4B workbenches must host capped queues; interim indexes remain operational references—not hubs.

## Out of scope / deferrals

- Dedicated supervisor portal routes, notifications digest, mobile approvals—all blocked on roadmap phases beyond UX-0.

## Verification checklist

- [ ] Declares `future` status with explicit TC-29 dependency.
- [ ] Documents interim helpers exactly as emitted by `bin/rails routes`.
