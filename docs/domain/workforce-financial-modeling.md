# Workforce financial modeling — index

**Scope:** Compensation (plans, revenue, commission, **employee-only** minimum draw), **contractor charges** (obligations, waivers, recoveries), and **contractor settlement** (runs, lines, lineage). Roadmap epics **TC-13–TC-19** map to these domains; product narrative lives in the [developer brief](../roadmap/phase-4-developer-brief.md).

**Status:** Locked decisions implemented in `db/migrate/20260516120000_phase4_compensation_settlement.rb` and `app/models/`.  
**Link issues/PRs** to the **domain doc below** that matches the change, and to the brief when product rules shift.  
**ERD (code truth):** [model-erd.md](model-erd.md) — update in the same PR as new `app/models` / migrations.

| Domain doc | Epics | Scope |
| --- | --- | --- |
| [**compensation-financials.md**](compensation-financials.md) | TC-13–TC-16 | Plans, assignments, pay periods, revenue, commission, employee-only draw, CSV import, commission **finalized** lock |
| [**contractor-charges.md**](contractor-charges.md) | TC-17–TC-18 | Contractor charges, waivers, recoveries |
| [**contractor-settlement.md**](contractor-settlement.md) | TC-19 | Settlement runs, lines, hybrid lineage, run events, void / paid-recorded |

**DDL:** Initial migration `db/migrate/20260516120000_phase4_compensation_settlement.rb` — new tables/columns should extend this story in the relevant domain doc or add a follow-up migration with a short log row there.

---

## Cross-domain rules

**Engagement is the financial anchor** for plan assignment, revenue inputs, commission calculations, contractor charges, and settlement lines ([brief §4](../roadmap/phase-4-developer-brief.md)).

**Operational history:** Prefer **targeted** event tables (`DrawBalanceEvent`, `ContractorChargeWaiver`, `ContractorChargeRecovery`, `ContractorSettlementRunEvent`) — **do not** introduce one catch-all `FinancialAuditEvent` with opaque JSON for workforce financials ([brief §13](../roadmap/phase-4-developer-brief.md)).

**Relationship-type guards** (single canonical table): [compensation-financials.md § Relationship-type guards](compensation-financials.md#relationship-type-guards).

---

## References

Engineering execution notes may live under `.cursor/plans/` when present.

## Related docs

- [engagement.md](engagement.md) — relationship types and spine
- [team360.md](team360.md) — read-only aggregation; not workflow owner
- [../product/overview.md](../product/overview.md) — product boundaries (employee draw vs contractor settlement)
