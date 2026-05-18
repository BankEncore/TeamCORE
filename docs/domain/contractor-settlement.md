# Contractor settlement — TeamCORE

**Epic:** **TC-19** — Contractor settlement shell.

**Purpose:** Locked persistence and boundaries for **agency-scoped settlement runs**, per-engagement **lines** with snapshot totals, **hybrid lineage** (links to revenue inputs, commission calculations, charge recoveries), and **run lifecycle** (including void and paid-recorded).

**Product rules:** [phase-4-developer-brief.md](../roadmap/phase-4-developer-brief.md) (§11, §12 settlement panel).  
**Adjacent domains:** [compensation-financials.md](compensation-financials.md) (commission feeds lines), [contractor-charges.md](contractor-charges.md) (deductions / recoveries) · **Modeling hub:** [workforce-financial-modeling.md](workforce-financial-modeling.md) · **ERD:** [model-erd.md](model-erd.md)  
**Migration (DDL):** `db/migrate/20260516120000_phase4_compensation_settlement.rb`

**Scope guard:** Settlement support records, not a general ledger (brief §1, §14).

---

## 1. Settlement period (run) vs pay period

### Decided

- **Contractor settlement-centric** work uses **`ContractorSettlementRun`** with explicit `period_start_on` / `period_end_on` (brief §11).
- **No** requirement that this period match **`PayPeriod`** 1:1 in MVP ([compensation-financials.md § Pay periods](compensation-financials.md#2-pay-periods-commission--employee-rail)).

### As implemented

- **`ContractorSettlementRun`** — `agency_id`, `period_start_on`, `period_end_on`, `status` (`draft` \| `calculated` \| `finalized` \| `paid_recorded` \| `voided`).
- **`ContractorSettlementLine`** — belongs to run + `engagement`; `gross_commission_cents`, `charge_deductions_cents`, manual adjustment columns, **`net_settlement_cents`** (MVP ≥ 0).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `contractor_settlement_runs`, `contractor_settlement_lines`; composition via `Financials::ContractorSettlement::ComposeLine`. |

---

## 2. Lineage (hybrid)

### Decided

- Lines store **snapshot totals** so finalized numbers do not drift when sources change.
- **Plus** persisted **links** to selected sources (join tables), not derived-on-read only.

### Join tables (as implemented)

| Table | Purpose |
| --- | --- |
| `contractor_settlement_line_revenue_inputs` | Line ↔ revenue input (unique pair) |
| `contractor_settlement_line_commission_calculations` | Line ↔ commission calculation (unique pair) |
| `contractor_charge_recoveries` | Optional `contractor_settlement_line_id` when recovery applied in settlement |

Line-level adjustments: `manual_adjustment_positive_cents` / `manual_adjustment_negative_cents` on **`ContractorSettlementLine`**.

### Anti-patterns

- Snapshot-only lines with no source linkage (weak audit trail).
- No snapshots (finalized totals change when sources change).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | Hybrid totals + joins; `ComposeLine` caps deductions so net ≥ 0. |
| 2026-05-17 | `LineComputation`, `PreviewLine`, `SettlementComposerCandidates`; admin line composer UI; compose allowed on `draft` or `calculated` runs for additional engagements. |

---

## 3. Settlement line composer (preview + commit)

### Decisions (locked)

1. **Already settled:** `CommissionCalculation` rows linked to any `ContractorSettlementLine` whose run is **not** `voided` cannot be composed again; enforced in UI defaults and in `ComposeLine`.
2. **Finalized + period overlap:** Only **`finalized`** calculations whose **`revenue_input`** period overlaps the settlement run (`period_start_on` / `period_end_on`) are eligible candidates.
3. **Charges:** Only **`ContractorCharge.status = open`** with **`open_balance_cents > 0`** participate; ordering for deductions is **`due_on IS NULL` first**, then **`due_on ASC`**, then **`id ASC`** (nil due = immediately due).
4. **Formula:** `net = gross_commission + manual_addition − manual_reduction − charge_deductions` (manual reductions are **not** `ContractorChargeRecovery`).
5. **Primary operator path:** Select **commission calculations**; **revenue inputs** are derived from those calculations for join rows. Legacy **`revenue_input_ids`** inference remains supported for seeds/tests.
6. **One line per engagement per run:** `ComposeLine` rejects a second line for the same `engagement_id` on the same run.
7. **`PreviewLine`:** Read-only (no lines, recoveries, or charge mutations).
8. **`ComposeLine`:** Mutates charges/recoveries immediately; run may still be `draft` or `calculated` when adding lines for **different** engagements.
9. **Void with reversal (unpaid, unexported runs):** Runs in `draft`, `calculated`, or `finalized` may be voided when **not** `paid_recorded`, **no** settlement exports exist, and the operator supplies a **required** void reason. **Finalized but unexported** means internally approved but not yet sent externally; void is allowed with reversal. Voiding keeps settlement lines and join rows; restores charge `open_balance_cents`; creates `settlement_deduction_reversal` recovery rows (original `settlement_deduction` rows are retained). Commission calculations and revenue inputs are not mutated; calcs on voided runs become composer-eligible again. See [contractor-charges.md](contractor-charges.md) for reversal `source_type`. MVP does not support void after pay/export, per-line undo UI, or auto-replacement runs.

### Services

| Piece | Role |
| --- | --- |
| `Financials::ContractorSettlement::LineComputation` | Pure gross / manual / per-charge deductions / net validation. |
| `Financials::ContractorSettlement::SettlementComposerCandidates` | Eligible commission/charge rows + default flags + settled calc detection. |
| `Financials::ContractorSettlement::PreviewLine` | Builds preview result + warnings; calls `LineComputation` (waterfall or explicit per-charge cents). |
| `Financials::ContractorSettlement::ComposeLine` | Transactional commit; shares math with preview; optional `charge_deductions_cents_by_id` for partial deductions. |
| `Financials::ContractorSettlement::VoidRunWithReversal` | Transactional void: reverse settlement deductions, mark run `voided`, append event. |

### Admin routes

- **`GET`** `line_composer` — engagement-specific composer with defaults.
- **`POST`** `preview_settlement_line` — recompute preview from posted selections (same screen).
- **`POST`** `compose_line` — commit (array params + optional `charge_deductions[id]` dollar fields parsed to cents).

---

## Operational history (TC-19)

| Area | Table / model |
| --- | --- |
| TC-19 | `ContractorSettlementRunEvent` (`created`, `finalized`, `voided`, `payment_recorded`, etc.) |

### Settlement lifecycle (admin)

- **`finalize`:** from `draft` or `calculated` → `finalized` (+ event).
- **`void`:** from `draft`, `calculated`, or `finalized` when **not** `paid_recorded` and **no** settlement exports → `voided` (+ `voided` event). Composed lines are retained; charge balances restored via `VoidRunWithReversal` and `settlement_deduction_reversal` rows.
- **`mark_paid`:** from `finalized` only → `paid_recorded` (+ `payment_recorded` event).
- Settlement **show** lists run events (audit trail).

### Implementation log

| Date | Notes |
| --- | --- |
| 2026-05-16 | `contractor_settlement_run_events`; void / mark paid wired in admin. |
| 2026-05-17 | Void gated when composed lines exist; settlement composer + preview services. |
| 2026-05-18 | `VoidRunWithReversal`; void with charge reversal rows for unpaid, unexported runs. |

See [workforce-financial-modeling.md](workforce-financial-modeling.md) for cross-domain “no generic financial blob” posture.

---

## Relationship-type guards

Full matrix: [compensation-financials.md § Relationship-type guards](compensation-financials.md#relationship-type-guards). Settlement applies to **`individual_contractor`** and **`contractor_organization`** only in MVP.

---

## Lifecycle storage (Rails vs DB)

- Prefer **Ruby validations** and **constants** for run / line / charge statuses early.
- **Defer** native DB enums and broad CHECK constraints until lifecycle semantics stabilize.

---

## Team360 read surfaces (settlement)

- **`workforce_financial`** payload: agency **open** settlement runs (`draft` / `calculated`), **recent settlement lines** for the focused engagement, **last line** summary; admin link to settlement index.
- Read-only; admin owns runs and events.

---

## Related docs

- [engagement.md](engagement.md)
- [team360.md](team360.md)
