# TeamCORE — model ERD (Active Record)

This diagram reflects **persisted models** under `app/models/` as of the current codebase. It is the engineering counterpart to the conceptual [domain map](../product/domain-map.md): product domains like payroll, time, leave, and settlement **do not** have tables yet unless they appear here.

**Tenancy:** Almost every row is scoped to an **Agency**. **Users** attach to agencies via **UserAgency** (admin / ops identity is separate from **Party** identity).

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
| **Team360 / reporting** | No separate tables — read models aggregate the above |
| **Admin auth** | `User` (+ `has_secure_password`), `UserAgency` |

---

## Notable constraints (behavior the ERD does not show)

- **Engagement** enforces relationship type vs **Party** kind (e.g. employee → person party).
- **DocumentRecord** requires at least one of **team_member** or **engagement**; **party** is optional; agency must align with those rows.
- **EngagementSupervisionAssignment** (MVP): supervisor engagement must be **active** **employee**.
- **Department** hierarchy: optional parent must be top-level (no deep trees in MVP).

---

## Rendering

GitHub renders Mermaid in markdown. In other viewers, paste the `erDiagram` block into [Mermaid Live Editor](https://mermaid.live).
