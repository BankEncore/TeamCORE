# Roadmap decision log

## Purpose

This log records **roadmap-level decisions that have already been made**. The goal is to prevent re-litigation during implementation (“Didn’t we already decide phases?”).

**Unresolved** or **tiered modeling** topics stay in **`open-decisions.md`**. Naming and boundary precision for payroll/settlement vocabulary are expanded there (**OD-007**, **OD-008**); this log states the roadmap **intent** once.

---

## Relationship to other registers

| Register | Holds |
| --- | --- |
| **This log** (`roadmap-decision-log.md`) | Sequencing, milestones, epic numbering, phased delivery intent—accepted for roadmap execution. |
| [`open-decisions.md`](open-decisions.md) | OD-items: modeling choices, glossary locks, provisional MVP defaults—especially schema blockers (**OD-001–OD-012**). |
| [`mvp-scope.md`](mvp-scope.md) | Inclusion/exclusion charter and slippery boundaries (**GH-36**). |
| [`domain-map.md`](domain-map.md) | Domain list and phased domain placement. |

If a question is listed only in **`open-decisions.md`**, it is **not** settled here yet.

---

## Decision index

| ID | Topic | Phase / epic touchpoints | Recorded date | Status |
| --- | --- | --- | --- | --- |
| RD-001 | Phase structure uses Phases **0–6** | Roadmap-wide | 2026-05-14 | Accepted |
| RD-002 | Epic numbering uses **TC-00** … **TC-31** | Roadmap-wide / issue taxonomy | 2026-05-14 | Accepted |
| RD-003 | Phase 0 milestone = **product/domain framing only** | Phase **0**; epics framing (e.g. **TC-00** territory) | 2026-05-14 | Accepted |
| RD-004 | Phase 1 priority backbone | Phase **1**; identity/org epics (**TC-00** onward per plan) | 2026-05-14 | Accepted |
| RD-005 | Team360 timing | Phase **3** shell; deeper panels phased | 2026-05-14 | Accepted |
| RD-006 | Payroll processing boundary | Phases **5–6**, artifacts; precision **OD-007** | 2026-05-14 | Accepted |
| RD-007 | Contractor settlement boundary | Phases **4–5**, artifacts; precision **OD-008** | 2026-05-14 | Accepted |
| RD-008 | Compliance / classification boundary | Phases **2–3+** | 2026-05-14 | Accepted |

Dates reflect **capture in this repository** when no earlier formal log entry existed.

---

## Log entries

### RD-001 — Phase structure

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** The TeamCORE roadmap is organized into **Phases 0 through 6** as documented in **`domain-map.md`** (product framing → identity → docs/compliance → Team360/reporting → comp/charges/settlement shell → time/leave/payroll-settlement workflows → MVP hardening).

**Rationale.** A fixed phase ladder avoids uncontrolled parallel foundational work that later rework.

**Affected phases.** All.

**Unresolved detail.** OD-011 (agency implementation pattern), OD-009/010 hardening depths—tracked in **`open-decisions.md`**, not reopened as “free choice” roadmap shape.

---

### RD-002 — Epic numbering convention

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** Product and engineering roadmap epics/issues use numbering **`TC-00` through `TC-31`** (and consistent sub-issues thereafter) unless a superseding program rule is published.

**Rationale.** Stable labels improve traceability across GitHub Issues, Projects, and documentation.

**Affected epics.** Program-wide numbering scheme.  
**Unresolved detail.** Exact mapping table of epic **TC-xx** ↔ phase gates may live in roadmap or Projects; omission here does **not** change the numbering decision.

---

### RD-003 — Phase 0 milestone scope

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** **Phase 0** is **limited to product and domain framing**—overview alignment, glossary iteration, domain map, MVP scope charter, settled roadmap decisions (**this log** starting entries), **open-decisions register** maintenance—not production application schema or feature delivery.

**Rationale.** Prevents stealth implementation before identity model and scope boundaries stabilize.

**Affected phases.** Phase **0** only; prerequisites for Phase **1** remain listed in **`mvp-scope.md`**.

---

### RD-004 — Phase 1 implementation priority

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** Phase **1** prioritizes foundational workforce identity and relationship primitives:

| Focus | Elements |
| --- | --- |
| Context & structure | **Agency** (implementation pattern per OD-011), **Organization** |
| Identity & participant | **Party**, **Team Member** |
| Relationship spine | **Engagement**, **relationship type**, employee vs contractor **status** behavior (**OD-003**) |
| Subcontractors | Minimal **relationship** pattern per **OD-004** (related party ↔ promote pathway) |

**Rationale.** Downstream phases (documents, Team360 richness, payouts) depend on a correct engagement/participation backbone.

**Affected phases.** **Phase 1** primary; unblock **Phase 2+**.

---

### RD-005 — Team360 delivery timing

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** Deliver **Team360** as a deliberate **Phase 3** milestone: **functional shell**, permission-aware aggregates, placeholders for deferred domains (**Benefits**, **Training**, **Performance**, **Assets**). Financial/time/leave/payroll richness **fills** subsequent phases per **`domain-map.md`**.

**Rationale.** Team360 is central UX value; early framing without stable engagement data is wasted churn.

**Affected phases.** **Phase 3** primary visual milestone; iterative enhancement **4–6**.

---

### RD-006 — Payroll processing boundary

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** TeamCORE **supports payroll inputs**, **exports/imports**, **run/batch identity**, and recording **payroll results**—**without** replacing an external payroll processor for tax computation, withholdings, filings, or disbursement execution. This aligns with **`mvp-scope.md`** and **`overview.md`**.

**Rationale.** Agencies rely on payroll vendors; MVP focuses on authoritative workforce inputs and audited round-trip results.  

**Naming detail.** **OD-007**.

**Affected phases.** **Phases 5–6** for artifact completeness; prerequisites: engagement plus time plus leave pipelines.

---

### RD-007 — Contractor settlement boundary

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** Contractor **settlement workflows** encompass **runs, calculations, and results** (**OD-008** vocabulary), charges/deductions capture, generic **CSV/XLSX** interchange, and **manual** results recording. TeamCORE does **not** replace a general accounting suite or AP. See **`mvp-scope.md`**.

**Rationale.** Coherent settlement bookkeeping for commission-heavy agencies without GL/AP depth creep.  

**Naming detail.** **OD-008**.

**Affected phases.** **Phase 4** shell deepening into **Phase 5** interchange.

---

### RD-008 — Compliance and classification boundary

| Field | Value |
| --- | --- |
| **Recorded date** | 2026-05-14 |
| **Status** | Accepted |

**Decision.** Track **documents**, **classification-supporting records**, verifier actions, and deterministic **activation readiness signaling** (**OD-006** concept). TeamCORE **does not** issue binding **legal** worker-classification rulings.

**Rationale.** Strong operational evidence without implying automated legal adjudication.

**Affected phases.** **Phase 2** document/compliance foundations; surfaced in **Phase 3** Team360.

**Unresolved detail.** Readiness rule catalog and override mechanics— **`open-decisions.md` OD-005/006**.

---

## Open questions (pointer)

Anything still **tiered**, **modeling-heavy**, or **awaiting spike/ADR**—including provisional permission depth (**OD-009**) and audit fidelity (**OD-010**)—remains in **`open-decisions.md`**. No duplicate open list is maintained **here**.

---

## Acceptance criteria (**GH-37**)

- [x] Decision log exists (this file).
- [x] Each logged decision lists **recorded date**, **status**, and **rationale** (above).
- [x] Decisions reference **phases** and epic numbering (**TC-00 … TC-31**).
- [x] **Open questions** explicitly deferred to **`open-decisions.md`**.
