# UX0-J09 — Team member self-service

## Status

deferred

## Primary persona

**Employee** (future authenticated actor) for **narrow MVP self-service**: primarily **time** and **leave** workflows described at product level.

*Persona describes orientation only; admin navigation visibility remains shared for all admins until TC-29.*

## Goal

Capture **deferred** product intent for non-admin self-service without implying routes or portals that do not exist under `/admin` today. **Do not** treat this journey as committing to contractor portals, self-service **document upload**, pay/settlement statements, benefits enrollment, training uploads, or broad profile editing—those remain out of scope until explicit phases (contractor self-service and richer employee self-service are deferred in product overview). UX-5 requires authentication / actor-model decisions before implementing non-admin namespaces.

## Entry points

- None locked in `config/routes.rb` for UX-0 (admin-only baseline). Future spike should propose dedicated namespaces once UX-5 accepts User ↔ TeamMember binding decisions described in [overview](../overview.md).

## Preconditions

- UX-5 spike outputs (ADR, route proposal, policy boundaries) approved before journey graduates beyond `deferred`.

## Authoritative routes used

No stable non-admin helpers exist at UX-0 baseline—defer routing tables until UX-5 lands.

## Happy path

Document after UX-5 defines controllers and safe `return_to` equivalents outside admin.

## Team360 usage

Anticipated pattern (post–UX-5): employee self-service may surface **read-mostly** summaries; authoritative edits remain on admin-owned workflows until product explicitly splits ownership. No commitment to a parallel “Team360” product for non-admin users in UX-0.

## Return navigation expectations

| Starting surface | Action | Return destination |
| ---------------- | ------ | ------------------ |
| TBD (UX-5) | TBD | TBD |

## Exceptions / branches

- Contractor self-service explicitly deferred in product overview until broader permissions exist—do not stretch admin routes to mimic self-service.

## Reports vs workbenches

N/A at UX-0.

## Out of scope / deferrals

- Entire UX-5 program (authentication redesign, policy enforcement, optional separate subdomain/host routing).

## Verification checklist

- [ ] Clearly labeled `deferred`.
- [ ] Does **not** invent helper names absent from `config/routes.rb`.
- [ ] Does **not** imply contractor self-service, document upload, pay statements, or broad profile editing without marking them explicitly deferred/out of scope.
