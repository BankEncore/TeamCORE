# Contractor charges — TeamCORE

**Epics:** **TC-17** — Contractor charge tracking · **TC-18** — Contractor charge waiver.

**Purpose:** Locked persistence and boundaries for **contractor / contractor-organization** obligations to the agency (fees, recoverables, balances), **waivers**, and **recoveries** (including linkage to settlement when applied there).

**Product rules:** [phase-4-developer-brief.md](../roadmap/phase-4-developer-brief.md) (§9–§10, §12 contractor charge panel).  
**Adjacent domains:** [compensation-financials.md](compensation-financials.md), [contractor-settlement.md](contractor-settlement.md) · **Modeling hub:** [workforce-financial-modeling.md](workforce-financial-modeling.md) · **ERD:** [model-erd.md](model-erd.md)  
**Migration (DDL):** `db/migrate/20260516120000_phase4_compensation_settlement.rb`

**Scope guard:** Operational charge/recovery records, not a full AR system (brief §1, §14).

---

## 1. Charge & waiver / recovery (TC-17 / TC-18)

### As implemented

- **`ContractorCharge`** — agency, engagement, `charge_type`, `status`, money columns, optional `due_on`, `description`.
- **`ContractorChargeWaiver`** — amount, actor, reason; drives balance / status updates on the charge (see model).
- **`ContractorChargeRecovery`** — `source_type`, `amount_cents`, `occurred_on`, optional `contractor_settlement_line_id` when applied in settlement, optional `actor`.

### Relationship-type guards

See the full matrix in [compensation-financials.md § Relationship-type guards](compensation-financials.md#relationship-type-guards). Charges apply only to **`individual_contractor`** and **`contractor_organization`** in MVP.

---

## Operational history (TC-17 / TC-18)

Use **targeted**, queryable rows — not a generic financial JSON blob ([workforce-financial-modeling.md](workforce-financial-modeling.md)).

| Area | Table / model |
| --- | --- |
| TC-17 / TC-18 | `ContractorChargeRecovery`, `ContractorChargeWaiver` |

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `contractor_charges`, `contractor_charge_waivers`, `contractor_charge_recoveries` with `actor` where applicable. |

---

## Lifecycle storage (Rails vs DB)

- Prefer **Ruby validations** and **constants** for charge `status` early.
- **Defer** native DB enums and broad CHECK constraints until lifecycle semantics stabilize.

---

## Team360 read surfaces (charges)

- **`workforce_financial`** payload: open / **past due** summaries (`due_on` vs assembler `as_of_date`), next due, recent **recoveries** and **waivers**; admin link to engagement charge index when eligible.
- Read-only; admin owns mutations.

---

## Related docs

- [engagement.md](engagement.md) — contractor relationship types
- [team360.md](team360.md)
