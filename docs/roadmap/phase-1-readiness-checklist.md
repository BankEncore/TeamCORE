# Phase 1 readiness checklist

Defines what must be **true before starting Phase 1 implementation** (Rails schema, migrations, and application code for identity/organization/engagement foundation).

**Canonical Phase 1 domains** are listed in **[`../product/domain-map.md`](../product/domain-map.md)** § *Phase 1 — Core Identity, Organization, and Engagement Foundation*.

This file supports **GitHub #40** (**TC-00.08**).

---

## Phase 1 domains (named)

Phase 1 establishes the following product domains in code and data model:

| Domain / area | Responsibility (summary) |
| --- | --- |
| **Agency** | Top-level operating context / tenancy boundary (implementation pattern per **OD-011**). |
| **Organization** | Departments, locations, teams, reporting lines, authority. |
| **Party** | Person and organization identity records. |
| **Team Member** | Agency-linked workforce participant profile (links to Party). |
| **Engagement** | Employment vs contractor relationship, lifecycle, placement, supervisor linkage. |
| **Status models** | Employee vs contractor status behavior on Engagement (**OD-003**). |
| **Subcontractor relationship support** | Related-party vs promote-to–Team Member (**OD-004** MVP rule; advanced graph deferred). |

Per **`domain-map.md`**, nothing in Phases 2–6 is meaningfully shippable until this foundation exists.

---

## Required Phase 0 documents (links)

These artifacts should be **accepted** (or explicitly waived by product lead in writing) before Phase 1 work begins.

| Artifact | Path | Notes |
| --- | --- | --- |
| Product overview | [`docs/product/overview.md`](../product/overview.md) | Boundary, MVP operating decisions. |
| Domain map | [`docs/product/domain-map.md`](../product/domain-map.md) | Phases, dependencies, domain list. |
| Glossary (working filename) | [`docs/product/gloassry.md`](../product/gloassry.md) | Stabilize conflicting terms; payroll/settlement language per **OD-007/OD-008**. |
| MVP scope | [`docs/product/mvp-scope.md`](../product/mvp-scope.md) | Firm **includes/excludes** and risky seams. |
| Roadmap decision log | [`docs/product/roadmap-decision-log.md`](../product/roadmap-decision-log.md) | RD-001–RD-008 and epic numbering **TC-00…TC-31**. |
| Open decision register | [`docs/product/open-decisions.md`](../product/open-decisions.md) | OD-001–OD-012; tiered follow-ups. |
| Employee vs contractor applicability matrix | [`docs/product/employee-contractor-applicability-matrix.md`](../product/employee-contractor-applicability-matrix.md) | Who gets payroll vs settlement vs time/leave. |
| Party / Team Member / Engagement modeling note | [`docs/product/modeling-notes/party-team-member-engagement.md`](../product/modeling-notes/party-team-member-engagement.md) | Supports **OD-001**. |

---

## Blocking open decisions before Phase 1 schema work

These must be **closed** (Accepted + documented) or have an **explicit waiver** recorded in **`open-decisions.md`** or **`roadmap-decision-log.md`** before the first **non-reversible** Phase 1 migrations ship.

| OD | Topic | Why blocking | Required output |
| --- | --- | --- | --- |
| **OD-011** | Agency vs Organization **implementation** | Partitions every FK and tenancy story; cannot be retrofitted cheaply if wrong. | **ADR** or **Phase 1 modeling note** choosing pattern (standalone Agency model vs org-root vs other) **before schema freeze**. Concept is already Accepted in register. |
| **OD-001** | Party vs Team Member vs Engagement | Already **Accepted** — ensure team has read modeling note. | — |
| **OD-002** | Multiple engagements | Accepted with constraints — embed in schema uniqueness/index design. | Capture in schema design note or epic TC-03/TC-04 criteria. |
| **OD-003** | Status on Engagement | Accepted — state machine design for Phase 1. | Same. |
| **OD-004** | Subcontractors | **MVP rule Accepted**; advanced graph **explicitly deferred** (no blocker to start). | Implement minimal path per matrix + register. |

**Non-blocking for day-one coding** (required by later phases): **OD-009** permissions (provisional MVP), **OD-010** audit ADR timing (Phase 6 focus), **OD-005/006** Phase 2 split, **OD-012** Phase 4 settlement detail.

---

## Phase 1 epics (confirmed in GitHub)

Phase 1 engineering work is tracked as epics/issues under **BankEncore/TeamCORE**:

| Epic ID | GitHub issue | Title |
| --- | --- | --- |
| **TC-01** | [#2](https://github.com/BankEncore/TeamCORE/issues/2) | Organization Foundation |
| **TC-02** | [#3](https://github.com/BankEncore/TeamCORE/issues/3) | Team Member / Party Foundation |
| **TC-03** | [#4](https://github.com/BankEncore/TeamCORE/issues/4) | Engagement Lifecycle |
| **TC-04** | [#5](https://github.com/BankEncore/TeamCORE/issues/5) | Employee and Contractor Status Model |
| **TC-05** | [#6](https://github.com/BankEncore/TeamCORE/issues/6) | Subcontractor Relationship Support |

Parent umbrella: **TC-00** — [#1](https://github.com/BankEncore/TeamCORE/issues/1) (*Product Framing and Domain Model*).

**Confirmation step:** Each epic **open**, **scoped**, and linked to a **milestone** (or equivalent) before sprinting; update this table if issue numbers change.

---

## Exit criteria for **TC0** (Phase 0 framing)

Phase 0 is **product and domain framing only** — no production feature delivery (**RD-003**). **TC0** is satisfied when:

1. Deliverables for **TC-00.02–TC-00.08** (GitHub issues **#34**, **#36–#40** and peers) exist under **`docs/product/`** / **`docs/roadmap/`** as scoped.  
2. **OD-001, OD-002, OD-003, OD-004** (MVP subcontractor rule), and **OD-011 concept** are **Accepted** in **`open-decisions.md`**.  
3. **OD-011 implementation** is **scheduled or completed** (ADR or modeling note **before** freezing Phase 1 schema).  
4. Stakeholders acknowledge **MVP scope** and **applicability matrix** so implementation does not relitigate employee vs contractor rails.

---

## Pre–Phase 1 checklist (executable)

### Product artifacts

- [ ] Product overview accepted (or signed-off exception recorded).  
- [ ] Domain map accepted.  
- [ ] Glossary accepted for Phase 1–touching terms (or explicit “good enough for now” in **TC-00** discussion).  
- [ ] MVP scope accepted.  
- [ ] Roadmap decision log created and current (**RD-xxx**).  
- [ ] Open decision register created and current (**OD-xxx**).  
- [ ] Employee vs contractor applicability matrix accepted.  
- [ ] Party / Team Member / Engagement terminology stable (**modeling note** + glossary entries as needed).

### Decisions

- [ ] Subcontractor modeling — MVP rule **Accepted** per **OD-004**; advanced cases **explicitly deferred** (not a startup blocker).  
- [ ] **OD-011** — **Implementation pattern chosen** (ADR or modeling note) **before irreversible migrations**.

### Epics and governance

- [ ] Phase 1 epic issues confirmed — [#2](https://github.com/BankEncore/TeamCORE/issues/2) … [#6](https://github.com/BankEncore/TeamCORE/issues/6) (**TC-01…TC-05**).  
- [ ] TC0 exit criteria met; program agrees to start **TC-01** implementation.

---

## Acceptance criteria (**GH-40**)

- [x] Phase 1 domains are **named**.  
- [x] Required Phase 0 documents are **linked**.  
- [x] **Blocking** open decisions are **identified**.  
- [x] Phase 1 epics are **confirmed** (linked).  
- [x] Exit criteria for **TC0** are **documented**.
