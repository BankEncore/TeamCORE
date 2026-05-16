# TeamCORE Phase 4 Developer Brief

## Compensation, Contractor Charges, Minimum Commission Draws, and Contractor Settlement

**Phase:** Phase 4 — Compensation, Contractor Charges, and Settlement Basics **Epics:** TC-13 through TC-19 **Audience:** Product, engineering, implementation planning, issue refinement **Status:** Authoritative product / workflow spec for TC-13–TC-19. **Persistence and implementation locks:** [`../domain/workforce-financial-modeling.md`](../domain/workforce-financial-modeling.md) (hub) · [`../domain/compensation-financials.md`](../domain/compensation-financials.md) · [`../domain/contractor-charges.md`](../domain/contractor-charges.md) · [`../domain/contractor-settlement.md`](../domain/contractor-settlement.md) (migrations, models, services).

---

## 1\. Purpose

Phase 4 introduces the financial relationship between the agency and team members. The phase must preserve a strict distinction between:

1. **Compensation** — what the agency may owe a team member.  
2. **Minimum commission draw recovery** — employee-only protection/recovery logic for commissioned employees.  
3. **Contractor charges and recoverables** — what an individual contractor or contractor organization may owe the agency.  
4. **Contractor settlement** — the contractor-facing settlement shell that applies contractor commission, selected charge deductions, adjustments, and payment/result recording.

Phase 4 should not become a payroll tax engine, general accounting system, full AR system, booking-level commission engine, or vendor-specific payroll/settlement integration.

---

## 2\. Phase 4 Epic Map

| Epic | Title | Primary Domain(s) | Notes |
| :---- | :---- | :---- | :---- |
| **TC-13** | Compensation Plan Assignment | Compensation | Assign compensation plans to engagements; snapshot terms. |
| **TC-14** | Manual / Imported Revenue Inputs | Compensation, Import/Export | Capture period-level revenue inputs. |
| **TC-15** | Flat-Rate Commission Calculation | Compensation, Import/Export | Calculate commission from commissionable revenue. |
| **TC-16** | Minimum Commission Draw Recovery | Compensation | Employee-only recoverable minimum commission guarantee. |
| **TC-17** | Contractor Charge Tracking | Contractor Charges | Track contractor-to-agency obligations and balances. |
| **TC-18** | Contractor Charge Waiver | Contractor Charges | Full/partial charge waivers with reason and actor. |
| **TC-19** | Contractor Settlement Shell | Settlement, Compensation, Contractor Charges | Contractor settlement runs/lines; applies selected inputs and deductions. |

### Recommended labels

```
TC-13 Compensation Plan Assignment
  domain:compensation
  control:financial
  type:epic

TC-14 Manual / Imported Revenue Inputs
  domain:compensation
  domain:import-export
  control:financial
  type:epic

TC-15 Flat-Rate Commission Calculation
  domain:compensation
  domain:import-export
  control:financial
  type:epic

TC-16 Minimum Commission Draw Recovery
  domain:compensation
  control:financial
  control:audit
  type:epic

TC-17 Contractor Charge Tracking
  domain:contractor-charges
  control:financial
  type:epic

TC-18 Contractor Charge Waiver
  domain:contractor-charges
  control:financial
  control:audit
  type:epic

TC-19 Contractor Settlement Shell
  domain:settlement
  domain:compensation
  domain:contractor-charges
  control:financial
  type:epic
```

---

## 3\. Core Domain Boundaries

### 3.1 Compensation

Compensation tracks what the agency may owe the team member.

In Phase 4, compensation includes:

* employee salary setup  
* employee hourly setup  
* employee commission eligibility  
* individual contractor commission  
* contractor organization commission  
* flat-rate commission plan assignment  
* commissionable revenue basis  
* employee-only minimum commission draw recovery

Compensation does **not** own contractor charges, final payroll tax calculations, statutory withholding, full payroll execution, or full settlement result import/export workflows.

### 3.2 Contractor Charges and Recoverables

Contractor charges track what an individual contractor or contractor organization may owe the agency.

Examples:

* onboarding fee  
* annual renewal fee  
* recurring monthly fee  
* technology/platform fee  
* E\&O / insurance pass-through  
* supplier debit memo / chargeback  
* reimbursable expense  
* lost/damaged asset recovery  
* other manual charge

Contractor charges do **not** represent employee deductions, employee draw recovery, employee payroll adjustments, or agency compensation owed to a team member.

### 3.3 Minimum Commission Draw Recovery

Minimum commission draw recovery is an **employee-only** compensation mechanism for commissioned employees.

It is not contractor settlement and not contractor charges.

A minimum commission draw is added when calculated employee commission for a pay period is below a configured minimum gross commission threshold. The draw brings the employee up to the minimum for that period. The resulting draw balance is recovered from future commission amounts above the minimum, without ever reducing a future period below the configured minimum.

### 3.4 Contractor Settlement

Contractor settlement applies only to:

* individual contractor engagements  
* contractor organization engagements

Promoted subcontractor settlement is deferred unless later pulled into scope.

Contractor settlement does not handle employee payroll, employee minimum commission draw recovery, statutory payroll tax calculations, or full accounting/AP/AR.

---

## 4\. Engagement as the Anchor

Compensation, revenue inputs, commission calculations, contractor charges, and settlement lines should be anchored to the **Engagement**, not only to Party or TeamMember.

This preserves the core TeamCORE spine:

```
Party → TeamMember → Engagement(s) → downstream operational domains
```

Practical rules:

* Compensation plan assignments belong to the engagement.  
* Revenue inputs belong to the engagement and settlement/pay period.  
* Commission calculations belong to the engagement and relevant revenue input/period.  
* Contractor charges belong to a contractor engagement.  
* Settlement lines belong to a contractor engagement.  
* Party and TeamMember may summarize financial state, but should not be the source of truth for plan assignment or settlement calculation.

---

## 5\. TC-13 — Compensation Plan Assignment

### Purpose

Define reusable compensation plans and assign them to engagements with effective dating and snapshot behavior.

### Phase 4 supported rails

Phase 4 compensation setup supports:

* employee salary  
* employee hourly rate  
* employee commission eligibility  
* individual contractor commission  
* contractor organization commission

Promoted subcontractor commission is deferred unless explicitly added later.

### Assignment rule

Compensation plans are assigned to **Engagement**.

Plans may be suggested or defaulted from role, position, agency program, business line, or contractor program in the future, but the authoritative assignment for Phase 4 is engagement-level.

### Supported MVP compensation patterns

| Pattern | Phase 4 support |
| :---- | ----: |
| Employee salary only | Yes |
| Employee hourly only | Yes |
| Employee commission only with minimum draw | Yes |
| Contractor flat commission only | Yes |
| Contractor flat commission \+ recurring fees | Yes, but fees are contractor charges, not compensation |
| Contractor organization flat commission | Yes |
| Contractor organization flat commission \+ recurring fees | Yes, same as individual contractor |
| Contractor different rates by business line | Deferred |
| Tiered commission | Deferred |
| Commission splits | Deferred |
| Supplier/product-specific commission rules | Deferred |
| Booking-level commission integration | Deferred |

### Effective dating

Compensation assignments require:

```
effective_start_on required
effective_end_on optional
blank effective_end_on means effective indefinitely
```

### Plan catalog and snapshot approach

Use a hybrid approach:

* agency defines reusable compensation plan catalog entries  
* assignment snapshots key terms at the time of assignment  
* assignment-level overrides are allowed where configured  
* plan changes do not silently rewrite existing assignments

### Plan change rule

Existing assignments keep their original snapshot terms until explicitly reassigned or intentionally updated.

### Precision

```
Money: store in cents
Rates: store in basis points
70.00% = 7000 bps
7.50% = 750 bps
```

### Employee salary/hourly Phase 4 purpose

Employee salary and hourly setup should be captured in Phase 4 but calculation/export behavior is deferred to Phase 5 payroll-input workflows.

---

## 6\. TC-14 — Manual / Imported Revenue Inputs

### Purpose

Capture gross sales and commissionable revenue used for commission calculation.

### Granularity

MVP revenue input granularity:

```
one summary row per engagement per period
```

Booking-level, invoice-level, or supplier-level revenue details are deferred.

### Period model

Revenue inputs belong to an **agency-defined settlement period** or comparable period record with explicit start and end dates.

### Required fields

Commissionable revenue is required for commission calculation.

Gross sales is optional.

```
commissionable_revenue_cents required
gross_sales_cents optional
```

### Revenue source types

Revenue inputs should support source classification:

* manual  
* imported CSV/XLSX  
* adjustment  
* reversal/correction

### Correction behavior

Imported or manual revenue rows may be edited directly until the associated settlement is finalized.

After settlement finalization, corrections should be made through adjustment or reversal rows rather than editing the finalized source data directly.

---

## 7\. TC-15 — Flat-Rate Commission Calculation

### Purpose

Calculate commission from commissionable revenue using a flat commission rate.

### Commission basis

MVP flat-rate commission uses:

```
commissionable revenue × commission rate
```

It does not calculate commission as a percentage of gross sales.

### Applicability

Phase 4 calculates both employee and contractor commission.

However:

* contractor commission may feed contractor settlement in Phase 4  
* employee commission is calculated for visibility and preparation, but payroll export/input handling belongs to Phase 5

### Timing

Commission calculation happens:

* when creating a settlement draft  
* through manual calculate/recalculate action before finalization

### Persistence

Persist draft calculations and allow recalculation until settlement finalization.

### Stale calculation rule

If revenue or rate changes after calculation:

* mark calculation stale  
* allow recalculation only before settlement finalization  
* after finalization, use adjustment/reversal behavior

### Negative/zero rules

| Scenario | MVP rule |
| :---- | :---- |
| Zero commissionable revenue | Allowed |
| Negative adjustment | Allowed with control |
| Negative final commission | Not allowed in normal calculation |
| Negative net settlement | Not allowed in MVP |

---

## 8\. TC-16 — Minimum Commission Draw Recovery

### Recommended title

```
TC-16 Minimum Commission Draw Recovery
```

### Purpose

Support an employee-only recoverable minimum commission guarantee for commissioned employees.

### Definition

A minimum commission draw is an employee-only compensation mechanism. If calculated commission for a pay period is below the configured minimum gross commission amount, TeamCORE automatically adds a recoverable draw to bring the employee to the minimum. The draw balance carries forward and is recovered from future commission amounts above the minimum, but recovery must never reduce a future period’s gross commission pay below the configured minimum. Authorized administrators may forgive draw balances with reason and timestamp.

### Applicability

Phase 4 MVP:

* applies to employees only  
* contractor advances/draws are deferred as a separate future concept  
* contractor settlement does not apply employee draw recovery

### Minimum basis

Minimum basis is configurable by plan.

Examples of possible minimum bases:

* fixed dollar amount per pay period  
* minimum wage × hours worked  
* greater of fixed amount or minimum wage calculation  
* other plan-defined basis

The plan catalog provides defaults; assignment snapshots the specific minimum/draw terms.

### Below-minimum rule

If calculated commission is below the configured minimum:

```
draw_added = minimum_amount - calculated_commission
gross_commission_pay = minimum_amount
draw_balance increases by draw_added
```

The draw is added automatically.

### Above-minimum recovery rule

If calculated commission is above the configured minimum and a draw balance exists:

```
recoverable_excess = calculated_commission - minimum_amount
draw_recovery = lesser of recoverable_excess and outstanding_draw_balance
gross_commission_pay = calculated_commission - draw_recovery
draw_balance decreases by draw_recovery
```

### Floor rule

Recovery can never reduce gross commission pay below the configured minimum.

### Balance carryforward and forgiveness

Draw balance carries forward until recovered or forgiven.

Forgiveness is allowed in MVP only as an administrative action with:

* actor/user  
* timestamp  
* reason  
* amount forgiven

### Example

| Pay period | Calculated commission | Minimum | Prior draw balance | Draw added | Draw recovery | Gross commission pay | Ending draw balance |
| ----: | ----: | ----: | ----: | ----: | ----: | ----: | ----: |
| 1 | $700 | $1,000 | $0 | $300 | $0 | $1,000 | $300 |
| 2 | $1,250 | $1,000 | $300 | $0 | $250 | $1,000 | $50 |
| 3 | $1,500 | $1,000 | $50 | $0 | $50 | $1,450 | $0 |

Invariant:

```
gross_commission_pay >= configured minimum
```

### Suggested model concepts

```
MinimumCommissionRule
  compensation_plan_id
  minimum_basis
  minimum_amount_cents
  recovery_rule

CompensationPlanAssignment
  engagement_id
  compensation_plan_id
  effective_start_on
  effective_end_on
  snapshot_minimum_basis
  snapshot_minimum_amount_cents
  snapshot_recovery_rule

CommissionCalculation
  engagement_id
  pay_or_settlement_period_id
  calculated_commission_cents
  draw_added_cents
  draw_recovery_cents
  gross_commission_pay_cents
  ending_draw_balance_cents
  stale/finalized status

DrawBalance
  engagement_id
  balance_cents

DrawBalanceEvent
  engagement_id
  commission_calculation_id
  event_type: draw_added / recovery / forgiveness / correction
  amount_cents
  actor_id
  reason
  occurred_at
```

---

## 9\. TC-17 — Contractor Charge Tracking

### Purpose

Track amounts owed by individual contractors and contractor organizations to the agency.

### Applicability

Contractor charges apply to:

* individual contractors  
* contractor organizations

Promoted subcontractors are deferred unless explicitly added later.

### Supported charge types

MVP supports:

* onboarding fee  
* annual renewal fee  
* recurring monthly fee  
* technology/platform fee  
* E\&O / insurance pass-through  
* supplier debit memo / chargeback  
* reimbursable expense  
* lost/damaged asset recovery  
* other manual charge

### Charge creation

MVP supports:

* manual charge creation  
* recurring schedule generation

### Lifecycle model

Use a small persisted lifecycle status and derive operational conditions.

Persisted status:

```
draft
open
closed
waived
cancelled
```

Derived conditions:

```
due
overdue
partially_recovered
fully_recovered
partially_waived
fully_waived
```

This avoids stale lifecycle values such as due/overdue becoming persisted statuses.

### Recovery methods

Contractor charges may be recovered or resolved through:

* settlement deduction  
* direct payment reference  
* invoice/direct bill reference  
* manual adjustment  
* waiver

Automated invoicing is excluded from MVP.

### Partial recovery

Charges may be partially recovered through:

* settlement deduction  
* direct payment

### Product rule

Contractor charges track amounts owed by an individual contractor or contractor organization to the agency. Charges may be created manually or from configured recurring schedules. Charges maintain an open balance and may be recovered through contractor settlement deduction, direct payment reference, invoice/direct bill reference, manual adjustment, or waiver. MVP does not implement full AR aging, automated invoicing, or dispute/write-off workflows.

---

## 10\. TC-18 — Contractor Charge Waiver

### Purpose

Allow authorized users to waive all or part of a contractor charge while preserving financial history.

### Waiver behavior

MVP supports:

* full waiver  
* partial waiver

Waiver must record:

* charge  
* waived amount  
* actor/user  
* timestamp  
* reason

A waived or partially waived charge remains visible in contractor charge history and Team360.

### Product rule

Authorized users may waive all or part of an open contractor charge. Waivers must record amount, actor, timestamp, and reason. A waived charge or partial waiver remains visible in contractor charge history and Team360.

---

## 11\. TC-19 — Contractor Settlement Shell

### Purpose

Create contractor settlement runs and settlement lines that explain contractor payment amounts from selected revenue inputs, commission calculations, selected contractor charge deductions, and manual adjustments.

### Applicability

Contractor settlement applies to:

* individual contractors  
* contractor organizations

Promoted subcontractor settlement is deferred.

### Period model

Settlement schedules are configurable, but every settlement run stores explicit:

```
settlement_period_start_on
settlement_period_end_on
```

### Run structure

A settlement run may include:

* one contractor, or  
* many contractors

But each settlement run covers one settlement period.

### Settlement line inputs

Each contractor settlement line may include selected:

* revenue input rows  
* commission calculations  
* open contractor charges to deduct  
* manual adjustments

### Draft behavior

Settlement draft creation should support either:

* automatic suggestion of eligible inputs, or  
* manual selection

Users must review before finalization.

### Charge deductions

Selected charge deductions default to:

```
full remaining charge balance, capped at available net settlement
```

Contractor charge deductions may reduce net settlement to zero but not below zero.

### Manual adjustments

Manual adjustments are allowed, but net settlement cannot go below zero in MVP.

### Settlement statuses

```
draft
calculated
finalized
paid_recorded
voided
```

| Status | Meaning |
| :---- | :---- |
| `draft` | Run/line exists but has not been calculated or reviewed. |
| `calculated` | Amounts have been calculated and are ready for review/finalization. |
| `finalized` | Settlement math is locked; normal edits are no longer allowed. |
| `paid_recorded` | Payment/result has been manually recorded. |
| `voided` | Settlement was voided for correction or cancellation. |

### Post-finalization corrections

After settlement is finalized, corrections happen by:

* voiding and recreating the settlement, or  
* creating adjustment rows in a later settlement

The correct method depends on whether the settlement was paid/exported.

### Settlement flow

```
1. Create settlement run for a configured period.
2. Select one or more contractor engagements.
3. TeamCORE suggests eligible revenue inputs and commission calculations, or user selects them manually.
4. User selects contractor charges to deduct.
5. Selected charge deductions default to full remaining balance, capped by available net settlement.
6. User may add manual adjustments.
7. TeamCORE calculates settlement line totals.
8. User reviews calculated settlement.
9. User finalizes settlement.
10. User records payment/result manually.
11. Later corrections use void/recreate or adjustment in a later settlement, depending on payment/export status.
```

### Settlement math

For each settlement line:

```
gross_commission_cents
+ manual_positive_adjustments_cents
- selected_charge_deductions_cents
- manual_negative_adjustments_cents
= net_settlement_cents
```

Invariant:

```
net_settlement_cents >= 0
```

### Product rule

Contractor settlement applies to individual contractor and contractor organization engagements. A settlement run covers one configured settlement period and may include one or many contractor engagements. Each settlement line explains the contractor’s payable amount from selected revenue inputs, commission calculations, selected contractor charge deductions, and manual adjustments. MVP settlement may suggest eligible inputs automatically or allow manual selection, but users review the draft before finalization. Net settlement cannot be negative in MVP.

---

## 12\. Team360 Requirements

### Compensation panel

Phase 4 Team360 compensation panel should show:

* current compensation plan  
* plan type  
* current rate / salary / hourly amount  
* effective date  
* commission eligibility  
* draw arrangement summary  
* last settlement period  
* outstanding draw balance  
* outstanding contractor charge balance

### Employee draw balance visibility

Employee draw balance should be visible to payroll/admin users only.

If full permissions are not yet implemented, Phase 4 may use existing coarse admin visibility and mark fine-grained visibility for later permissions hardening.

### Contractor charge panel

Phase 4 Team360 contractor charge panel should show:

* outstanding contractor balance  
* open charges count  
* past due charges count  
* next due charge  
* recent recoveries  
* recent waivers  
* link to charge history

### Contractor settlement panel

Phase 4 Team360 settlement panel should show:

* last settlement period  
* last settlement status  
* gross commission  
* charge deductions  
* net settlement  
* open settlement drafts  
* recent settlement history  
* link to settlement run/detail

---

## 13\. Audit and Control Requirements

Phase 4 includes financially sensitive records and actions. The implementation should prepare for audit and permission hardening, even if full TC-29/TC-30-style controls come later.

Sensitive areas include:

* compensation plan assignments  
* salary/hourly rates  
* commission rates  
* commission calculation results  
* revenue input corrections  
* draw balances  
* draw forgiveness  
* contractor charges  
* contractor recoveries  
* contractor charge waivers  
* settlement finalization  
* settlement payment/result recording  
* settlement voiding/correction

At minimum, sensitive actions should capture:

* actor/user  
* timestamp  
* reason or notes where applicable  
* prior value/new value where applicable  
* linkage to source record

---

## 14\. MVP Exclusions

Phase 4 excludes:

* full payroll tax calculation  
* statutory withholding calculation  
* tax filing  
* check printing / direct deposit execution  
* general ledger  
* full AP/AR system  
* full AR aging  
* automated invoicing  
* formal dispute workflow  
* formal write-off workflow  
* vendor-specific payroll/settlement API integrations  
* booking-level commission import  
* supplier/product-specific commission rules  
* tiered commissions  
* commission splits  
* contractor advances/draws  
* promoted subcontractor compensation/settlement unless explicitly added later

---

## 15\. Phase 5 Compatibility Assumptions

Phase 4 must prepare for Phase 5 employee time, leave, payroll input, and payroll/settlement artifact workflows without implementing those workflows early.

### 15.1 Period and schedule boundary

Employee payroll/pay periods and contractor settlement periods may share scheduling concepts, but payroll runs and settlement runs remain separate records and workflows.

Recommended posture:

```
Shared scheduling vocabulary where useful.
Separate payroll and contractor settlement run records.
```

Employee commission calculations attach to employee pay periods. Contractor commission calculations attach to contractor settlement periods.

```
employee commission calculation → pay period
contractor commission calculation → settlement period
```

### 15.2 Minimum commission draw compatibility

Minimum commission draw recovery is employee-only in MVP.

Phase 4 supports configurable minimum-basis terms, but the initial calculation may use fixed configured pay-period minimums without requiring time data.

Future Phase 5 work may add minimum-wage-hours-based calculations using approved time data.

Compatibility rule:

```
Phase 4 must not assume time data is available.
Phase 4 must not block future time-based minimum calculations.
```

### 15.3 Payroll input candidate posture

Phase 4 employee commission and draw calculations must preserve enough structure to become Phase 5 payroll input candidates.

Required future-facing fields include:

* calculated commission  
* draw added  
* draw recovery  
* gross commission pay  
* ending draw balance  
* calculation period  
* compensation assignment / rate snapshot

Conceptual future payload:

```
PayrollInputCandidate
  engagement_id
  pay_period_id
  source_type
  source_id
  earning_type
  gross_amount_cents
  memo
  calculation_snapshot
```

For employee commission/draw:

```
source_type: commission_calculation
earning_type: commission
calculated_commission_cents
draw_added_cents
draw_recovery_cents
gross_commission_pay_cents
ending_draw_balance_cents
```

### 15.4 Payroll result boundary

Phase 4 does not store final employee payroll results.

Phase 5 owns:

* payroll runs  
* payroll input exports  
* payroll input imports  
* manual payroll result entry  
* payroll result history  
* payroll artifact validation/error handling

Phase 4 should create compensation setup and employee commission/draw calculations that Phase 5 can consume.

### 15.5 Time and leave boundary

Phase 4 stores salary, hourly, commission, and minimum draw setup.

Phase 5 owns:

* employee time capture  
* timeclock punches  
* manual daily hours  
* weekly timesheets  
* supervisor-entered time  
* timesheet approval  
* pay-period time summaries  
* leave type configuration  
* leave requests and approvals  
* paid leave inclusion in payroll summaries

Compatibility rule:

```
Do not mix leave with compensation plan assignment.
Leave may later produce payroll input lines, but it is not compensation setup.
```

### 15.6 Contractor settlement export/import boundary

TC-19 may support draft, calculated, finalized, paid\_recorded, and voided settlement states in Phase 4\.

Generic CSV/XLSX settlement export/import may be added in Phase 5\.

Phase 4 must preserve settlement line data so export/import can be added later, but export/import architecture is not required to complete TC-19.

### 15.7 Employee vs contractor rail separation

Employee payroll and contractor settlement rails remain mutually exclusive per engagement.

```
employee engagement → payroll rail
individual_contractor engagement → settlement rail
contractor_organization engagement → settlement rail
subcontractor engagement → deferred unless promoted and explicitly scoped
```

### 15.8 Team360 compatibility

Phase 4 may display:

* compensation summary  
* employee draw balance for payroll/admin users  
* contractor charge balance  
* contractor settlement summary

Phase 5 later populates:

* time summary  
* leave summary  
* payroll run history  
* payroll input/result summary

Team360 remains a read-only assembled surface and must not become the owner of payroll, time, leave, compensation, settlement, or contractor charge workflows.

---

## 16\. Implementation Notes / Open Design Questions

The following should be resolved during implementation planning or ADR/modeling notes.

### 15.1 Compensation plan shape

Decide whether to implement:

1. a single `CompensationPlan` table with plan-type-specific fields,  
2. `CompensationPlan` plus component rows,  
3. plan subclasses/STI, or  
4. a simpler MVP structure with future migration path.

Recommendation: use a plan catalog plus assignment snapshot fields. Avoid over-engineering full component modeling unless needed immediately.

### 15.2 Period model

Clarify whether Phase 4 uses one shared period model for both employee commission calculations and contractor settlement, or separate period concepts:

* pay period for employee commission/minimum draw  
* settlement period for contractor settlement

Recommendation: keep concepts distinct where needed, but consider a reusable period/schedule abstraction if already aligned with later payroll workflows.

### 15.3 Settlement application lineage

Settlement should not store only final net values. It should preserve enough lineage to explain:

* selected revenue inputs  
* selected commission calculations  
* selected charge deductions  
* manual adjustments  
* final net settlement

### 15.4 Draw balance event model

Because draw forgiveness is allowed and financially sensitive, prefer an event-style draw balance history rather than only updating a balance field.

### 15.5 Contractor charge recovery model

Partial recovery through settlement and direct payment implies a charge application/recovery record, not just a status update.

Recommended concept:

```
ContractorChargeRecovery
  contractor_charge_id
  source_type: settlement_deduction / direct_payment / invoice_reference / manual_adjustment / waiver
  amount_cents
  occurred_on
  actor_id
  reference
  notes
```

### 15.6 Settlement status locking

Define which fields are editable by settlement status:

| Status | Editable? |
| :---- | :---- |
| `draft` | Yes |
| `calculated` | Yes, with recalculation |
| `finalized` | No normal edits |
| `paid_recorded` | No normal edits; correction workflow only |
| `voided` | Terminal |

---

## 16\. Summary Rules for Developers

Use the following as high-level implementation guardrails:

1. **Engagement is the financial context.** Attach Phase 4 setup and calculations to engagement.  
2. **Compensation is agency-to-team-member.** It does not own contractor receivables.  
3. **Contractor charges are contractor-to-agency.** They do not represent employee deductions or employee draws.  
4. **Employee minimum commission draws are employee-only.** They are not part of contractor settlement.  
5. **Contractor settlement is contractor-only in MVP.** It applies contractor commission, selected charge deductions, and adjustments.  
6. **Commission is flat-rate only in MVP.** It is based on commissionable revenue.  
7. **Revenue is period summary-level in MVP.** No booking-level integration yet.  
8. **Money uses cents; rates use basis points.**  
9. **Finalized math should not be silently mutated.** Use stale flags before finalization and adjustment/reversal after finalization.  
10. **Net contractor settlement cannot be negative in MVP.**  
11. **Draw recovery cannot reduce employee gross commission pay below the configured minimum.**  
12. **Waivers and forgiveness are sensitive financial actions.** Capture actor, timestamp, amount, and reason.

