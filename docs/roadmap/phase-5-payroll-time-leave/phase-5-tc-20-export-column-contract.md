# TC-20 — Payroll & settlement export column contract (TC-21 interchange)

Normative goal: outbound CSV/XLSX row shapes must stay aligned with **TC-21 Payroll and Settlement CSV/XLSX Import** so processors can round-trip or reconcile files.

## Payroll export (`Payroll::PayrollExportFileBuilder`)

UTF-8 CSV / XLSX. Header row order:

| Column | Meaning |
| --- | --- |
| `pay_period_id` | `PayPeriod` id |
| `pay_period_start_on` | ISO date |
| `pay_period_end_on` | ISO date |
| `payroll_input_batch_id` | Source batch id |
| `payroll_input_batch_reference` | Human batch reference (e.g. `PIB-…`) |
| `engagement_id` | `Engagement` id |
| `team_member_number` | Agency-scoped team member number (may be blank) |
| `party_id` | `Party` id for the team member |
| `party_display_name` | Display label |
| `earning_code` | `PayrollEarningCode` code string |
| `direction` | `earning` or `deduction` |
| `hours` | Decimal string or blank |
| `amount` | Decimal string or blank |
| `currency` | ISO currency code |

Rows are ordered by `engagement_id`, `earning_code`, row id. Values reflect **frozen** `PayrollInputRow` snapshots only (no recalculation in TC-20).

## Contractor settlement export (`Financials::ContractorSettlement::SettlementExportFileBuilder`)

| Column | Meaning |
| --- | --- |
| `contractor_settlement_run_id` | Run id |
| `agency_id` | Agency id |
| `period_start_on` / `period_end_on` | ISO dates |
| `engagement_id` | Contractor engagement |
| `team_member_number` | May be blank |
| `party_id` | Party id |
| `party_display_name` | Display label |
| `gross_commission_cents` | Integer cents |
| `charge_deductions_cents` | Integer cents |
| `manual_adjustment_positive_cents` | Integer cents |
| `manual_adjustment_negative_cents` | Integer cents |
| `net_settlement_cents` | Integer cents |

Rows follow `ContractorSettlementLine` order by `engagement_id`, line id.

## Validation summaries

`payroll_exports.validation_summary` and `contractor_settlement_exports.validation_summary` store JSON snapshots (row/line counts, closure-validation excerpts for payroll, lightweight warnings for settlement). They are operational metadata, not payroll math.

## References

- [ADR-0002 — Payroll period and workweek foundations](../../adr/adr-0002-payroll-period-and-workweek-foundations.md)
- [ADR-0004 — Leave vs time and payroll hooks](../../adr/adr-0004-leave-vs-time-and-payroll-hooks.md) (leave policy context for payroll rows)
- [phase-5-tc-23-a-downstream-dependency-contracts.md](phase-5-tc-23-a-downstream-dependency-contracts.md) — TC-20 / TC-21 boundaries
