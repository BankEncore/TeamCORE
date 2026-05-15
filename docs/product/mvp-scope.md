# TeamCORE MVP Scope

This document establishes a **firm scope boundary** for the TeamCORE MVP. All roadmap phases (0–6) should converge on this MVP definition unless the **open decisions register**, **overview**, or formal change control deliberately amend it.

**Companion docs:** [`overview.md`](overview.md), [`domain-map.md`](domain-map.md), [`open-decisions.md`](open-decisions.md). Payroll and settlement vocabulary aligns with **OD-007** and **OD-008**.

---

## TeamCORE MVP scope (summary)

The MVP is an **agency-scoped workforce operations** product for **travel agencies** with a mixed workforce: **employees** and **contractors** (individuals or organizations), with optional subcontractor tracking. MVP delivers unified **Party → Team Member → Engagement** foundations, operational domains through payment preparation and result recording (**not** becoming a payroll tax engine or full accounting suite), **Team360**, limited **employee self-service** (time and leave), and **documents + compliance + activation readiness** with clear legal boundaries.

Anything not listed under **MVP includes** defaults to **out of MVP** unless it appears under **explicit deferrals** as a phased deliverable planned for MVP release trains.

---

## MVP includes

Capabilities below are MVP commitments, delivered across phases 1–6 as described in **`domain-map.md`**.

### Phase 1 — Identity, agency context, organization, engagement foundation

| Capability | MVP behavior |
| --- | --- |
| **Agency context** | Top-level operating tenant for workforce data (implementation pattern subject to OD-011). |
| **Organization** | Departments, locations, teams, supervisory/reporting hierarchy. |
| **Party** | Person and organization identity and contact anchors. |
| **Team Member** | Agency-linked workforce participant profile referencing a Party (OD-001). |
| **Engagement** | Employment vs contractor relationships, lifecycle statuses (type-specific rules, OD-003), placement in organization, supervisory links. |
| **Multiple engagements** | Historical engagements preserved; concurrency rules per OD-002. |
| **Subcontractors (MVP)** | Related-party treatment with promotion path to Team Member when needed (OD-004). |

### Phase 2 — Documents and compliance

| Capability | MVP behavior |
| --- | --- |
| **Documents** | Document types; files or references; verification state on artifacts; alerts for missing/expired/expiring-soon docs. |
| **Compliance** | Requirement rules; completeness against configuration; deterministic **activation readiness** owned by Compliance (concept OD-006; detailed rule catalog phased). |
| **Verification** | Document verification by authorized roles (admin/HR/compliance per overview). |
| **Upload policy** | **Admin-only upload** for MVP documents (no employee/contractor self-service upload). |
| **Classification support** | Records that **support** contractor classification; TeamCORE does **not** render legal IC/EE determinations (see Compliance boundary below). |

### Phase 3 — Team360 and operational reporting

| Capability | MVP behavior |
| --- | --- |
| **Team360** | Unified profile/read model pulling authoritative data from owning domains—not a duplicate source of truth. |
| **Panels** | Functional panels for MVP domains; placeholders for Benefits, Training, Performance, Assets (lightweight summaries or “not yet configured”). |
| **Operational reporting** | Rosters, exception lists, expirations, missing docs, summaries with drill-through to Team360/source records where applicable. |

### Phase 4 — Compensation, contractor charges, settlement foundations

| Capability | MVP behavior |
| --- | --- |
| **Compensation** | Salary/hourly; commission plan assignment at engagement level; manually entered/imported gross sales and **commissionable revenue**; **flat-rate commission** in MVP (no tiers/splits/overrides in MVP unless explicitly pulled in later). |
| **Draws** | Repayable draws with automatic recovery rules against future settlements where specified in product rules (detailed ownership OD-012 in later modeling). |
| **Contractor charges** | Fees, renewals, recurring charges, pass-through/recoverables; statuses (draft/open/due/paid/deducted/waived, etc.—not full AR aging MVP); waivers supported. |
| **Settlement shell** | Basic contractor **settlement run** constructs and linkage to calculations/results as phased (OD-008 terms). |

### Phase 5 — Employee time, leave, payroll/settlement workflows

| Capability | MVP behavior |
| --- | --- |
| **Time (employees only)** | Web timeclock, manual daily hours, weekly timesheets, supervisor-entered time, timesheet **approval**. |
| **Leave (employees only)** | Agency-defined leave types; balances **manually** entered/adjusted in MVP; approvals (including configurable auto-approval by leave type); paid leave surfaced to payroll summaries after review. |
| **Contractors and time** | Contractors **do not** submit employee-style time in MVP. |
| **Payroll artifact workflow** | **Payroll inputs** consolidated; generic **CSV/XLSX** export and import; **manual payroll result** entry; **payroll run** references as batch identity (OD-007). |
| **Settlement artifact workflow** | **Settlement calculation** lineage into **settlement runs**/**results**; **export/import/manual result** analogous to payroll for contractors where applicable (OD-008); contractor settlement workflow remains **distinct** from employee payroll. |
| **Self-service (narrow)** | Employee-facing time and leave workflows only—see Self-service MVP limits section. |

### Phase 6 — Hardening (still within MVP envelope)

| Capability | MVP behavior |
| --- | --- |
| **Permissions** | Role-based and domain/action rules; Team360 visibility; coarse org scope; sensitive workflow gates (**not** full field-level security MVP default—OD-009). |
| **Audit** | Lifecycle events plus change history/fidelity per audit policy direction (OD-010); hardened before declaring release-ready. |
| **Import/export** | Validation and error-handling tightening for MVP safety. |

### Cross-cutting (MVP includes)

| Area | MVP commitment |
| --- | --- |
| **Distinct employee vs contractor rail** | Data model and UX preserve different workflows and payouts. |
| **Audit posture** | Sufficient auditing for approvals, payroll/settlement artifact movement, waiver/verification-sensitive actions—as scoped in OD-010 and phased delivery. |
| **Operational reports** | As listed in **`overview.md`** MVP operating decisions for rosters and exception monitoring. |

---

## MVP excludes

Unless explicitly reopened by product governance, MVP **does not** include:

- **Full payroll processing** inside TeamCORE—no in-product calculation of statutory taxes, withholdings schedules, filings, check printing/direct deposit execution.
- **Full tax engine**, **tax filing system**, **general ledger**, **AP** replacement, **full benefits carrier administration**.
- **Travel booking, CRM, or accounting suites** replaced by TeamCORE.
- **Contractor-facing full portal** parity with administrators.
- **Employee/contractor self-service upload** for compliance documents (MVP: admin-mediated upload).
- **Automatic leave accrual engines**—MVP relies on manual balance maintenance unless product explicitly adds accruals later.
- **Advanced contractor charge lifecycle** — formal dispute pipelines, mature AR aging, write-off workflows beyond MVP waiver patterns.
- **Tiered/regional commission complexity** at booking integration depth—MVP is flat-rate commission on supplied revenue totals per overview.
- **Vendor-specific payroll API integrations** — MVP is generic file + manual reconciliation patterns (unless a separate decision expands).

---

## Later scope

**Post-MVP** or **beyond MVP-first release** enhancements (often already listed in **`overview.md`** MVP vs later breakdown):

| Domain / area | Later intent |
| --- | --- |
| **Benefits** | Eligibility, enrollment, carrier coordination, deductions timing. |
| **Training & certification** | Assignments, completions, expirations, renewals aligned to compliance and Team360 panels. |
| **Performance reviews** | Cycles, metrics, differentiated employee vs contractor review patterns. |
| **Company assets** | Issue/return/lost/recovery integrations with deductions or contractor charges where appropriate. |
| **Expanded self-service** | Contractor portal, statement viewing, enrollment, training completions, richer profile workflows. |
| **System integrations** | Processor-specific connectors, webhook/API synchronization, reconciliation automation. |

These remain **explicitly desirable** roadmap directions but outside the **MVP contractual boundary** captured here.

---

## Explicit deferrals

Items **not MVP** today but deliberately **planned for future releases** inside the roadmap narrative (often Phase 7+):

- Commission **tiers**, **splits**, **overrides**, supplier-specific commissions, booking-level commission feeds.
- **Contractor employee dual-hat concurrency** unless administratively sanctioned (OD-002).
- **Field-level masking** enterprise policy engine unless driven by regulated field exceptions.
- Full **SOC-style segregation-of-duties** matrices.
- Contractor **activity time** resembling employee time clocks (distinct product model if introduced).
- **Legal classification engine / automated EE:IC adjudication.**

---

## Assumptions

1. **Agency is the tenancy boundary** for workforce data subject to OD-011 implementation confirmation.
2. **External payroll processor** continues to compute taxes and execute payments unless future scope merges processing.
3. **Agencies accept** MVP **generic CSV/XLSX** interchange for payroll/settlement MVP (and manual entry fallback).
4. **Authorized admins** satisfy document intake for MVP absent self-service uploads.
5. **Engagement** is the authoritative switch for eligibility (employee time/leave vs contractor settlement paths).
6. **Placeholders on Team360** for later domains are UX-acceptable until those modules ship—they must not impersonate audited financial or compliance records.

---

## Risky scope boundaries

These seams generate the most creep if not guarded—and should trigger **explicit change approval** rather than tacit backlog absorption.

### Payroll processing boundary (**OD-007**)

| In MVP | Decisively outside MVP |
| --- | --- |
| **Payroll input** aggregation; **payroll export**; **payroll run** identification for batches; recording **payroll results** | Tax calculation engines, withholdings configurators, payment rails, ACH/wire initiation, filings, garnishment engines |

**Mitigation.** Every story touching “payroll” MUST name whether it touches **inputs**, **export**, **import**, **result capture**, or **run metadata** — not “doing payroll.”

### Contractor settlement boundary (**OD-008**)

| In MVP | Decisively outside MVP |
| --- | --- |
| **Contractor settlement** workflow slices: **runs**, intermediate **calculation** capture, **exports/imports**, **results**, charge deductions/recoveries as recorded outcomes | Replacement for commissions accounting subledger, statutory 1099 processing automation, ACH mass pay execution, nuanced partnership tax scenarios |

**Mitigation.** Disallow vague “handle settlement”; require objects: settlement **run**, **calculation artifact**, **result row**, integration **touchpoint**.

### Self-service MVP limits

| In MVP employee self-service | Not MVP employee/contractor self-service |
| --- | --- |
| Clock/punch/time entry modalities approved in overview; weekly timesheets; leave requests/status; constrained visibility | Document upload/compliance attestations beyond admin; payroll/settlement stubs; contractor full portal; asset acknowledgments |

**Mitigation.** Any “portal” wording gets triaged against this table **before sizing**.

### Compliance and classification boundary

| In MVP | Decisively outside MVP |
| --- | --- |
| Track requirements, evidence artifacts, verifier actions, deterministic readiness signaling, alerting | Determining whether a worker *is legally* contractor vs employee |

**Mitigation.** Product copy and training must say TeamCORE **documents** statuses that support classification — it does **not** issue legal rulings unless future licensed scope emerges.

---

## Phase 1 prerequisites (for roadmap dependency management)

Later MVP phases MUST NOT claim production readiness until **Phase 1** clears the following—they are foundational data model prerequisites:

| # | Prerequisite | Why |
| --- | --- | --- |
| 1 | **Agency** partitioning approach chosen (conceptually Agency ≠ Organization — OD-011) | Prevents cascading migration on every foreign key convention. |
| 2 | **Party**, **Team Member**, **Engagement** concepts implemented per OD-001–OD-003 | Documents, payouts, routing, audit subjects hang off engagements. |
| 3 | **Organization** supervisory structure stable enough to assign placements | Workforce routing, approvals, reporting filters. |
| 4 | **Employee vs contractor** relationship typing and statuses **enforceable** without mixing rails | Payroll vs settlement divergence later. |
| 5 | **Subcontractor representation** minimally viable per OD-004 | Escapes brittle refactors when compliance expands subcontractor breadth. |

Phase 2+ prerequisites are sequenced further in **`domain-map.md`**; the table above gates **everything** else in the MVP roadmap.

For executable checkboxes (Phase 0 sign-off, OD-011 gate, epic links), use **[`../roadmap/phase-1-readiness-checklist.md`](../roadmap/phase-1-readiness-checklist.md)** (**GH-40**).

## Acceptance criteria (**GH-36 / TC-scope** checklist)

Derived from GitHub issue #36:

- [x] MVP capabilities listed **by domain** (above includes tables per phase-aligned domain bundles).
- [x] Later / post-MVP capabilities listed separately (**Later scope**, **explicit deferrals**).
- [x] **Payroll processing** boundary clarified (**Risky boundaries** + **OD-007** terminology).
- [x] **Contractor settlement** boundary clarified (**Risky boundaries** + **OD-008** terminology).
- [x] **Self-service MVP** limits enumerated (**Risky boundaries** **and** MVP includes Phase 5 / excludes).
- [x] **Compliance / classification** boundary explicit (**Risky boundaries** **and** Phase 2 table).
- [x] **Phase 1 prerequisites** identified (**dedicated section**).

---

## References

| Document | Purpose |
| --- | --- |
| [`../roadmap/phase-1-readiness-checklist.md`](../roadmap/phase-1-readiness-checklist.md) | TC0 exit + OD-011 gate + epic sanity (**GH-40**) |
| [`overview.md`](overview.md) | Narrative MVP operating decisions |
| [`domain-map.md`](domain-map.md) | Phases 0–6 domain ordering |
| [`open-decisions.md`](open-decisions.md) | OD-007, OD-008, OD-011, OD-012, OD-009, OD-010 |
| GitHub **#36** | Firm MVP scope charter issue |
