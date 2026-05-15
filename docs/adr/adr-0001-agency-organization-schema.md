# ADR-0001: Agency vs organization structure (Phase 1 schema)

## Status

Accepted

## Context

TeamCORE separates product language (**Agency** as the tenant-style operating context, **Organization** as internal structure) while needing a Phase 1 schema that does not overload the word “organization” as a Rails model (**OD-011**).

The application has no engagements table in TC-01; placement and supervision must not force premature coupling.

## Decision

TeamCORE models **`Agency`** as the top-level operating context for MVP data. **Departments**, **locations**, and **teams** belong directly to an agency.

TeamCORE does **not** introduce a polymorphic or catch-all **`Organization`** Active Record model for TC-01. In product language, **Organization** remains the domain term for internal structure under an agency; concrete Phase 1 tables are **`Agency`**, **`Department`**, **`Location`**, and **`Team`**.

**Engagement placement**, **reporting lines**, and **supervision** are documented under TC-01 and persisted after the **`Engagement`** model exists (TC-03).

## Lifecycle (TC-01)

Organization foundation entities share string statuses **`active`**, **`inactive`**, **`archived`** with model-level validations, default **`active`**, and an **`.active`** scope. Assignment blocking, audit events, permission gates, and admin UI filtering are intentionally deferred until engagement, workflow, Team360/reporting, and hardening epics consume these records.

See [`docs/domain/organization.md`](../domain/organization.md) for lifecycle semantics and deferrals.

## Consequences

- All organization-structure foreign keys anchor on **`agency_id`** (directly or via parent rows tied to one agency).
- **`agencies.code`** is **globally unique**; child entity codes are unique **per agency**.
- Department hierarchy is intentionally **single-level**: a department may have at most one parent, and that parent must not itself have a parent.
- Locations use **nullable `timezone`**; **`display_address`** and structured postal fields are deferred until TC-10/TC-12 or downstream needs arise.
- **No** **`team_lead`** foreign keys in TC-01; supervisory relationships are engagement-scoped when implemented.

## References

- [`docs/product/open-decisions.md`](../product/open-decisions.md) — **OD-011**
- [`docs/domain/organization.md`](../domain/organization.md)
- Epic **TC-01** Organization Foundation ([GitHub #2](https://github.com/BankEncore/TeamCORE/issues/2))
