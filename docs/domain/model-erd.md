# TeamCORE — model ERD (Active Record)

This diagram reflects **persisted models** under `app/models/` as of the current codebase. It is the engineering counterpart to the conceptual [domain map](../product/domain-map.md). **Workforce financial** tables (compensation / revenue / commission / draw, contractor charges, contractor settlement) appear in the same diagram (edges from **Engagement** / **Agency**). Domains such as full payroll execution, time, and leave **do not** have dedicated tables yet unless they appear here.

**Tenancy:** Almost every row is scoped to an **Agency**. **Users** attach to agencies via **UserAgency** (admin / ops identity is separate from **Party** identity).

**Modeling notes (TC-13–TC-19):** [workforce-financial-modeling.md](workforce-financial-modeling.md) (hub) · [compensation-financials.md](compensation-financials.md) · [contractor-charges.md](contractor-charges.md) · [contractor-settlement.md](contractor-settlement.md)

---

## Spine (agency → workforce → engagement)

Workforce participation is **Party → TeamMember → Engagement**. Operational placement and supervision hang off **Engagement**. Documents attach to **Engagement** / **TeamMember** (and optionally **Party**) with **DocumentType** + **DocumentRequirement** defining rules.

```mermaid
erDiagram
  Agency ||--o{ Department : "org structure"
  Agency ||--o{ Location : "org structure"
  Agency ||--o{ Team : "org structure"
  Agency ||--o{ Party : "identity"
  Agency ||--o{ TeamMember : "workforce"
  Agency ||--o{ Engagement : "relationship spine"
  Agency ||--o{ PartyRelationship : "party graph"
  Agency ||--o{ DocumentType : "compliance catalog"
  Agency ||--o{ DocumentRequirement : "rules"
  Agency ||--o{ DocumentRecord : "artifacts"
  Agency ||--o{ UserAgency : "admin users"

  User ||--o{ UserAgency : ""
  UserAgency }o--|| Agency : ""
  UserAgency }o--|| User : ""

  Department }o--o| Department : "parent (single-level tree)"
  Department ||--o{ Team : ""

  Location ||--o{ Team : ""

  Team }o--|| Agency : ""
  Team }o--o| Department : ""
  Team }o--o| Location : ""

  Party ||--o| PersonProfile : "1:1 if person"
  Party ||--o| OrganizationProfile : "1:1 if org"
  Party ||--o{ PartyContactMethod : ""
  Party ||--o{ TeamMember : ""

  TeamMember }o--|| Party : ""
  TeamMember }o--|| Agency : ""
  TeamMember ||--o{ Engagement : ""

  Engagement }o--|| Agency : ""
  Engagement }o--|| TeamMember : ""
  Engagement ||--o{ EngagementOrganizationPlacement : "dept/loc/team over time"
  Engagement ||--o{ EngagementSupervisionAssignment : "supervised side"
  Engagement ||--o{ EngagementSupervisionAssignment : "supervisor side"
  Engagement ||--o{ DocumentRecord : ""
  Engagement ||--o{ CompensationPlanAssignment : "compensation"
  Engagement ||--o{ RevenueInput : "compensation"
  Engagement ||--o{ CommissionCalculation : "compensation"
  Engagement ||--o| CommissionDrawBalance : "compensation · draw"
  Engagement ||--o{ DrawBalanceEvent : "compensation"
  Engagement ||--o{ ContractorCharge : "charges"
  Engagement ||--o{ ContractorSettlementLine : "settlement"

  Agency ||--o{ PayPeriod : "compensation"
  Agency ||--o{ CompensationPlan : "compensation"
  Agency ||--o{ CompensationPlanAssignment : "compensation"
  Agency ||--o{ RevenueInput : "compensation"
  Agency ||--o{ CommissionCalculation : "compensation"
  Agency ||--o{ CommissionDrawBalance : "compensation"
  Agency ||--o{ DrawBalanceEvent : "compensation"
  Agency ||--o{ ContractorCharge : "charges"
  Agency ||--o{ ContractorChargeWaiver : "charges"
  Agency ||--o{ ContractorChargeRecovery : "charges"
  Agency ||--o{ ContractorSettlementRun : "settlement"
  Agency ||--o{ ContractorSettlementLine : "settlement"

  CompensationPlan ||--o{ CompensationPlanAssignment : "compensation"

  PayPeriod ||--o{ RevenueInput : "compensation"
  PayPeriod ||--o{ CommissionCalculation : "compensation"

  RevenueInput ||--o{ CommissionCalculation : "compensation"
  CommissionCalculation ||--o{ DrawBalanceEvent : "compensation"

  ContractorSettlementRun ||--o{ ContractorSettlementLine : "settlement"
  ContractorSettlementRun ||--o{ ContractorSettlementRunEvent : "settlement"

  ContractorSettlementLine ||--o{ ContractorSettlementLineRevenueInput : "settlement lineage"
  RevenueInput ||--o{ ContractorSettlementLineRevenueInput : "settlement"
  ContractorSettlementLine ||--o{ ContractorSettlementLineCommissionCalculation : "settlement lineage"
  CommissionCalculation ||--o{ ContractorSettlementLineCommissionCalculation : "settlement"

  ContractorCharge ||--o{ ContractorChargeWaiver : "charges"
  ContractorCharge ||--o{ ContractorChargeRecovery : "charges"
  ContractorSettlementLine ||--o{ ContractorChargeRecovery : "settlement (optional)"

  EngagementOrganizationPlacement }o--|| Agency : ""
  EngagementOrganizationPlacement }o--|| Engagement : ""
  EngagementOrganizationPlacement }o--o| Department : ""
  EngagementOrganizationPlacement }o--o| Location : ""
  EngagementOrganizationPlacement }o--o| Team : ""

  EngagementSupervisionAssignment }o--|| Agency : ""
  EngagementSupervisionAssignment }o--|| Engagement : "supervised"
  EngagementSupervisionAssignment }o--|| Engagement : "supervisor_engagement"

  DocumentType }o--|| Agency : ""
  DocumentType ||--o{ DocumentRequirement : ""
  DocumentType ||--o{ DocumentRecord : ""

  DocumentRequirement }o--|| Agency : ""
  DocumentRequirement }o--|| DocumentType : ""

  DocumentRecord }o--|| Agency : ""
  DocumentRecord }o--|| DocumentType : ""
  DocumentRecord }o--o| TeamMember : ""
  DocumentRecord }o--o| Engagement : ""
  DocumentRecord }o--o| Party : ""
  DocumentRecord }o--o| User : "verified_by"

  PartyRelationship }o--|| Agency : ""
  PartyRelationship }o--|| Party : "source_party"
  PartyRelationship }o--|| Party : "target_party"
```

---

## How domains intersect (quick reference)

| Conceptual domain | Primary models |
| --- | --- |
| **Agency** | `Agency`, `UserAgency` |
| **Organization (structure)** | `Department`, `Location`, `Team` |
| **Party / identity** | `Party`, `PersonProfile`, `OrganizationProfile`, `PartyContactMethod` |
| **Party graph** | `PartyRelationship` (same agency; source/target parties) |
| **Team member** | `TeamMember` (party within agency) |
| **Engagement** | `Engagement` (relationship type + lifecycle status) |
| **Placement & supervision** | `EngagementOrganizationPlacement`, `EngagementSupervisionAssignment` |
| **Documents & compliance** | `DocumentType`, `DocumentRequirement`, `DocumentRecord` |
| **Compensation (catalog & assignment)** | `CompensationPlan`, `CompensationPlanAssignment` |
| **Pay periods & revenue** | `PayPeriod`, `RevenueInput` |
| **Commission & draw** | `CommissionCalculation`, `CommissionDrawBalance`, `DrawBalanceEvent` |
| **Contractor charges** | `ContractorCharge`, `ContractorChargeWaiver`, `ContractorChargeRecovery` |
| **Contractor settlement** | `ContractorSettlementRun`, `ContractorSettlementLine`, join tables, `ContractorSettlementRunEvent` |
| **Team360 / reporting** | No Team360 table — read models aggregate domain tables |
| **Admin auth** | `User` (+ `has_secure_password`), `UserAgency` |

---

## Notable constraints (behavior the ERD does not show)

- **Engagement** enforces relationship type vs **Party** kind (e.g. employee → person party).
- **DocumentRecord** requires at least one of **team_member** or **engagement**; **party** is optional; agency must align with those rows.
- **EngagementSupervisionAssignment** (MVP): supervisor engagement must be **active** **employee**.
- **Department** hierarchy: optional parent must be top-level (no deep trees in MVP).
- **Workforce financials:** Minimum commission draw recovery is **employee-only**; **contractor settlement** applies to `individual_contractor` and `contractor_organization` engagements only (**subcontractor** excluded in MVP). Net contractor settlement is non-negative in MVP. Hybrid settlement lineage: lines store totals plus join rows to revenue, commission calcs, and charge recoveries.

---

## Rendering

GitHub renders Mermaid in markdown. In other viewers, paste the `erDiagram` block into [Mermaid Live Editor](https://mermaid.live).
