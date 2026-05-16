# TeamCORE Product Overview / Introduction

## Overview

**TeamCORE** is a workforce operations platform designed specifically for travel agencies. It helps agencies manage the full lifecycle of their internal team, including employees, independent contractors, contractor organizations, and related subcontractor relationships.

While TeamCORE shares some characteristics with a traditional human resource management system, its purpose is broader and more specialized. Many travel agencies work with a mixed workforce that includes both W-2 employees and independent sales contractors. These groups may have different legal relationships, compensation structures, reporting expectations, benefits eligibility, time tracking requirements, document obligations, compliance needs, and payment workflows. TeamCORE is designed to preserve those distinctions while still giving agencies a unified view of each team member.

At the center of TeamCORE is the concept of the **Team Member**. A team member may be an employee, an individual independent contractor, a contractor organization such as an LLC or corporation, or, where configured by the agency, a subcontractor associated with a contractor. TeamCORE tracks each team member’s identity, agency relationship, compensation, contractor fees or recoverables, documents, compliance status, time, leave, payroll or settlement history, and other operational details.

TeamCORE should support multiple active engagements for a team member when needed, but this should be treated as an exception rather than the normal workflow. Most team members will have one active engagement at a time, while valid overlapping engagements can be supported when agency operations require them.

## Purpose

The purpose of TeamCORE is to give travel agencies a structured, auditable, and agency-specific system for managing people, contractors, and workforce-related obligations.

TeamCORE should help agencies answer questions such as:

* Who is currently active with the agency?  
* Is this person an employee, individual contractor, or contractor organization?  
* What is their current position, contract, or engagement?  
* Who do they report to?  
* What compensation or commission plan applies?  
* Are there contractor fees, recoverable expenses, or outstanding balances?  
* What training or certifications are required, completed, expired, or pending?  
* What assets have been issued to this team member?  
* What documents are missing or expiring?  
* What payroll or settlement history is available?  
* What information should supervisors, administrators, payroll staff, and team members themselves be allowed to see?

## Product Positioning

TeamCORE is best understood as a **team management and workforce operations system for travel agencies**, not simply as a generic HR platform.

Traditional HR systems usually assume that most workers are employees. TeamCORE is designed around a more flexible agency model where workers may include:

| Team Member Type | Description |
| :---- | :---- |
| **Employee** | A person employed by the agency, typically with a job position, supervisor, payroll relationship, benefit eligibility, time/leave rules, and performance review process. |
| **Individual Contractor** | A person operating as an independent contractor, often paid through commission or settlement rather than traditional payroll. |
| **Contractor Organization** | A business entity, such as an LLC or corporation, that contracts with the agency and may have a primary contact or its own subcontractors. |
| **Subcontractor** | A person or entity associated with a contractor organization or independent contractor. Subcontractors may be tracked as related contacts or as first-class team members depending on agency configuration and operational need. A subcontractor should generally become a full TeamCORE team member when the agency needs to track access, training, documents, compliance, commission participation, or Team360 visibility. | |

TeamCORE should allow agencies to configure how deeply subcontractors are tracked. Some agencies may only need subcontractor names and contact information. Others may need full Team360 profiles, document requirements, training requirements, compliance status, and settlement-related visibility for subcontractors.

This distinction is important because employees and contractors are subject to different operational, legal, payroll, tax, benefit, and compliance considerations. TeamCORE should help agencies maintain these distinctions clearly rather than forcing every worker into the same HR model.

## Core Concepts

### Engagement

A central concept in TeamCORE is the **Engagement**.

An engagement represents the formal relationship between the agency and a team member. For an employee, the engagement may include employment status, job position, department, supervisor, pay schedule, benefit eligibility, time tracking rules, and leave eligibility. For a contractor, the engagement may include contract terms, commission plan, renewal dates, contractor fees, settlement rules, required documentation, and contract lifecycle status.

This distinction allows TeamCORE to separate:

* the **person or organization** involved with the agency  
* the **legal/operational relationship** between that party and the agency  
* the **rules and obligations** that apply because of that relationship

In practical terms, the engagement becomes the anchor for many other parts of the system, including compensation, benefits, contractor charges, time tracking, leave, payroll or settlement processing, training requirements, documents, and performance expectations.

TeamCORE should preserve the distinction between the underlying party and the engagement. If a person moves from contractor to employee, or from employee to contractor, the preferred model is to retain the same Party record and create a new Engagement that reflects the new legal and operational relationship. This preserves identity history while keeping each employment or contractor relationship distinct.

Historical engagements should be preserved. For MVP, authorized administrators may correct closed engagements when needed, but sensitive changes should be logged. A stricter correction or amendment workflow may be introduced later if greater audit control is required.

#### Engagement Statuses

Employee and contractor engagements should use separate status models.

Recommended employee statuses:

- Draft / Pending  
- Active  
- Suspended  
- Terminated  
- Retired  
- Rehire Eligible  
- Not Rehire Eligible

“On Leave” should generally be displayed as a workforce condition derived from the Leave domain rather than treated as a primary employee engagement status.

Recommended contractor statuses:

- Draft / Pending  
- Active  
- Pending Renewal  
- Expired  
- Suspended  
- Terminated  
- Do Not Renew  
- Inactive

### Team360

**Team360** is the unified profile view for each team member. It brings together information from across TeamCORE so agency users can quickly understand a team member’s current status, history, requirements, and obligations.

Team360 should include fully functional MVP panels for:

- identity and contact summary  
- current engagement  
- engagement history  
- organization placement and reporting line  
- compensation summary  
- contractor charges and balance summary  
- time summary  
- leave summary  
- payroll or settlement history  
- documents and compliance status  
- alerts and missing items

Team360 may also include lightweight placeholder or summary panels for later-phase domains, including:

- benefits  
- training and certification  
- performance reviews  
- company assets

These later-domain panels may initially display limited information, manually maintained summaries, document/compliance references, or “not yet configured” states until the full domain is implemented.

Team360 should be permission-aware. MVP should prioritize administrative, supervisor, payroll, and compliance visibility, with limited employee self-service focused on time and leave. Broader employee and contractor self-service can be expanded in later phases.

Team360 should aggregate information from the rest of TeamCORE, but it should not replace the underlying records owned by each domain.

## Product Boundary

TeamCORE should not try to become every related system at once.

In its intended scope, TeamCORE should:

* track team member identity and engagement history  
* distinguish employees from contractors  
* manage agency-specific workforce records  
* support time, leave, compensation, contractor charges, and settlement workflows  
* prepare data for payroll or settlement processing  
* import final payroll or settlement results  
* provide a unified Team360 profile  
* maintain supporting documents, history, and compliance visibility

TeamCORE should not initially attempt to become:

* a full payroll tax engine  
* a tax filing system  
* a general accounting system  
* a full benefits administration carrier platform  
* a replacement for external payroll processors  
* a replacement for travel booking, accounting, or CRM systems

Instead, TeamCORE should integrate with those systems where appropriate.

## MVP Operating Decisions

The following operating decisions guide the proposed MVP roadmap.

### Team Member and Engagement

* TeamCORE should support multiple active engagements for a team member, but this should be treated as an exception workflow rather than the normal case.  
* Contractor organizations may have subcontractors. Subcontractors may be tracked as related contacts or as first-class team members depending on agency configuration and operational need. A subcontractor should generally become a first-class team member when the agency needs to track access, training, documents, compliance status, commission participation, or Team360 visibility.  
* If a person moves between contractor and employee status, the preferred model is to retain the same Party record and create a separate Engagement for the new relationship.  
* Closed engagements should preserve history. In MVP, authorized administrators may correct closed engagements, but sensitive changes should be logged.

### Compensation and Contractor Charges

* TeamCORE will support manually entered or imported gross sales and commissionable revenue.  
* MVP commission calculation will support simple flat-rate commission based on commissionable revenue.  
* **Employee minimum commission draw recovery** (commissioned employees): when commission in a period is below a configured minimum, the system may record a draw up to that minimum and recover the balance from **future employee commission** in later periods—without employee draw recovery being implemented as **contractor settlement** or contractor charge logic.[^p4-draw]  
* Commission plans will generally be assigned at the Engagement level, with possible defaults or suggested plans derived from role, position, contractor program, agency program, or business line.  
* Contractor charges may be recovered through settlement deduction or invoice/direct payment.  
* MVP contractor charges will use basic due/open/paid status tracking rather than full accounts-receivable aging.  
* Fee waivers will be supported in MVP. Formal dispute and write-off workflows will be deferred.

### Payroll and Settlement

* MVP payroll and settlement workflows will use generic CSV and Excel/XLSX export and import.  
* MVP will support manual entry of final payroll or settlement results.  
* Contractor settlement should remain distinct from employee payroll.  
* Payroll and settlement approvals may be optional or agency-configurable, but formal approval workflows are not required in MVP.

### Documents and Compliance

* Documents and Compliance is an MVP domain.  
* MVP will support employee and contractor document requirements, missing-document alerts, expiration alerts, and expiring-soon alerts.  
* Document verification will be limited to agency owner/admin, HR/admin, and compliance users.  
* MVP document upload will be admin-only.  
* TeamCORE will include basic contractor classification support, but it will not make legal classification determinations.

### Time and Leave

* Contractors will not submit time in MVP.  
* Employee time tracking will be configured by engagement, position, or agency policy.  
* MVP time tracking will support web timeclock punches, manual daily hours, weekly timesheet submission, supervisor-entered time, and timesheet approval.  
* Leave applies to employees in MVP.  
* Leave balances will be manually entered or adjusted in MVP.  
* Leave approval behavior may vary by leave type, including auto-approval.  
* Approved paid leave will flow into payroll or time summaries only after supervisor or payroll review.

### Team360, Self-Service, Reporting, and Audit

* Team360 will be included in MVP.  
* Team360 will include functional panels for MVP domains and lightweight placeholder panels for later-phase domains.  
* MVP self-service will focus on employee time and leave.  
* Formal MVP approval workflows will include timesheet approval and leave approval.  
* MVP audit history will include lifecycle events for major records and field-level change history for sensitive records.  
* MVP operational reporting will include active team member lists, employee rosters, contractor rosters, expiring contractor agreements, missing or expired documents, contractor balances owed, payroll run history, settlement run history, time summaries by pay period, leave balances, and organization/reporting views.

## MVP and Later-Phase Scope

TeamCORE should be developed in phases. The proposed MVP should focus on the foundational domains needed to identify team members, define their relationship with the agency, manage core compensation and workforce operations, and provide a unified Team360 profile. Later phases can expand into more specialized workforce management capabilities once the core data model and workflows are stable.

The MVP should prioritize the domains that are necessary to support the central TeamCORE concept: travel agencies need to manage both employees and independent contractors while preserving the legal, operational, compensation, and compliance distinctions between them.

### Proposed MVP Domains

The following domains are recommended for the initial TeamCORE MVP.

#### Organization

The Organization domain tracks the agency’s structure, including departments, locations, teams, reporting relationships, and lines of authority.

This is part of the MVP because TeamCORE needs to understand where team members fit within the agency, who supervises whom, and how authority flows through the organization.

#### Team Member / Party

The Team Member / Party domain stores records for people and organizations associated with the agency, including employees, individual contractors, contractor organizations, and related contacts.

This is a core MVP domain because TeamCORE must support both individual people and organization-based contractors. A contractor may be a person, corporation, LLC, or other business entity, and contractor organizations may also have primary contacts or related subcontractors.

#### Engagement

The Engagement domain tracks the employment or contractor relationship between the agency and the team member. This includes position, contract, lifecycle status, start and end dates, assignment history, job changes, contract renewals, and contract expirations.

Engagement should be treated as a central MVP concept because it defines the legal and operational relationship between the agency and the team member. Many other domains, including compensation, time tracking, leave, payroll, settlement, contractor charges, and compliance, depend on the current engagement.

### Compensation

The Compensation domain tracks amounts the agency may owe to team members, including salary, hourly wages, commission, **employee** minimum-commission draws and recoveries, and compensation plan assignments. Tiered commission and other advanced structures are later-phase capabilities.

For MVP, TeamCORE should support compensation plan setup, engagement-level compensation plan assignment, salary or hourly compensation tracking, and simple flat-rate commission calculation based on manually entered or imported gross sales and commissionable revenue.

Commission plans should generally be assigned at the Engagement level, while allowing defaults or suggested plans to derive from role, position, contractor program, agency program, or business line. This keeps the active employment or contractor relationship as the authoritative source while preserving flexibility for agency-specific compensation structures.

**Minimum commission draw recovery** is an **employee-only** compensation mechanism: recoverable draw balances are satisfied from **future employee commission** (and related payroll/compensation preparation flows), not from **contractor settlement** processing. Contractors are paid through **contractor settlement**, which applies contractor commission, contractor charge deductions, and adjustments—not employee draw recovery.[^p4-draw]

More advanced commission features, such as tiered commissions, commission splits, overrides, supplier-specific commission rules, booking-level integrations, and complex adjustment logic, should be deferred to later phases.

### Contractor Charges and Recoverables

The Contractor Charges and Recoverables domain tracks amounts that independent contractors may owe to the agency. These may include onboarding fees, annual renewal fees, recurring monthly fees, technology fees, pass-through expenses, reimbursable costs, chargebacks, waivers, and balances recovered through **contractor** settlement deduction or direct payment.[^p4-settlement]

For MVP, contractor charges should support both settlement deduction and invoice/direct-payment recovery. TeamCORE should track basic charge statuses such as draft, open, due, partially paid, paid, deducted, and waived. Full accounts-receivable aging, dispute management, and write-off workflows should be deferred to later phases.

Waivers should be supported in MVP. Waived charges should remain visible in history and should require an authorized user, reason, and timestamp.

Contractor Charges and Recoverables should remain separate from Compensation. Compensation tracks what the agency owes the team member. Contractor Charges and Recoverables tracks what the contractor owes the agency.

### Time Tracking

The Time Tracking domain captures working time for employees who are required to report hours.

For MVP, time tracking should apply to employees only. Contractors should not submit time in TeamCORE, because contractor time tracking may blur the distinction between employee timekeeping and contractor relationship management.

Employee time tracking should be configured by engagement, position, or agency policy. Some employees may use a web-based timeclock, some may submit manual daily hours, some may submit weekly timesheets, and some salaried or exempt employees may not be required to track daily time.

MVP time tracking should support:

- web timeclock punch in/out  
- manual daily hour entry  
- weekly timesheet submission  
- supervisor-entered time  
- timesheet review and approval  
- pay-period time summaries

Manual start/end time entry, contractor activity reporting, external time system imports, scheduling integration, and advanced exception automation can be deferred to later phases.

### Leave

The Leave domain tracks paid and unpaid employee time away from work.

For MVP, leave should apply to employees only. Contractors should not use employee-style leave workflows. If contractor availability tracking is ever needed, it should be modeled separately and carefully distinguished from employee leave benefits.

MVP leave should support agency-defined leave types, including PTO or vacation, sick or medical leave, bereavement, jury duty, FMLA, unpaid leave, unlimited leave, and other agency-defined categories.

Leave balances should be manually entered or adjusted in MVP rather than automatically accrued. Automated accrual rules, tenure-based accruals, carryover rules, negative balance rules, and advanced leave liability reporting can be deferred to later phases.

Leave requests should support approval workflows, but approval behavior may vary by leave type. Some leave types may require supervisor approval, while others may be auto-approved according to agency policy.

Approved paid leave should flow into payroll or time summaries only after supervisor or payroll review.

### Payroll and Settlement Runs

The Payroll and Settlement Runs domain packages pay-related information for external processing and stores the results returned from external systems.

For MVP, TeamCORE should use generic CSV and Excel/XLSX export and import workflows rather than vendor-specific payroll integrations. TeamCORE should also support manual entry of final payroll or settlement results for agencies that cannot provide a structured import file during the initial release.

For employees, payroll runs may include compensation inputs (including employee commission and **minimum commission draw** effects where applicable), approved time, approved paid leave, employee deductions, exported payroll input files, and imported payroll results.

For contractors, settlement runs may include gross sales, commissionable revenue, flat-rate commission calculation, contractor charge deductions, direct-payment references, and settlement results—**not** employee minimum-commission draw recovery, which stays on the employee compensation / payroll side.[^p4-settlement]

Contractor payments may initially be tracked through manual settlement records or a lightweight contractor settlement process. The system should be designed so contractor settlement can later become a formal exportable workflow.

Payroll and settlement run approval should be optional or agency-configurable. MVP does not require a complex formal approval workflow for payroll or settlement runs.

TeamCORE should store final payroll and settlement result details, including:

- gross pay or gross settlement  
- taxes  
- employee deductions  
- contractor charge deductions  
- employee-side minimum commission draw recovery (and related compensation amounts), where applicable[^p4-draw-list]  
- net pay or net settlement  
- payment date  
- payment method  
- external processor reference ID  
- adjustment notes

TeamCORE should not initially become a full payroll tax engine. External payroll processors remain responsible for tax calculations, statutory withholding, filings, and final payment execution unless that scope is intentionally expanded in a later phase.

### Documents and Compliance

The Documents and Compliance domain tracks required documents, supporting evidence, and compliance status for team members and engagements.

This domain is part of the MVP because the employee/contractor distinction creates documentation and compliance needs from the beginning. TeamCORE should help agencies determine whether each active team member has the required records for their current engagement.

MVP document requirements should support:

- employee employment agreement or offer letter  
- employee tax withholding forms  
- employee direct deposit form  
- employee handbook or policy acknowledgment  
- contractor agreement  
- contractor W-9 or tax form  
- contractor insurance or E\&O evidence  
- contractor classification/supporting documentation  
- contractor renewal agreement  
- certification evidence  
- identity verification or eligibility-to-work documentation  
- other agency-defined documents

MVP should include missing-document alerts, expiration alerts, and expiring-soon alerts. These are especially important for contractor agreements, insurance or E\&O evidence, certifications, identity or eligibility records, and required engagement documents.

Document verification should be restricted to authorized agency owner/admin, HR/admin, and compliance users. For MVP, documents should be uploaded and managed by administrative users rather than through team member self-service.

TeamCORE should include basic contractor classification support in MVP. It should not make legal classification decisions, but it should help agencies maintain the records that support contractor classification, such as entity type, signed agreement status, W-9 status, insurance or E\&O evidence, business information, renewal history, and contractor-specific compliance flags.

#### Team360

Team360 is the unified, permission-aware dashboard for each team member. It aggregates information from the other domains into a single profile view.

Team360 belongs in the MVP because it is the primary way users will experience the value of TeamCORE. Even if some domains are initially simple, Team360 should provide a consolidated view of identity, engagement, compensation, charges, time, leave, payroll or settlement history, documents, and compliance status.

---

### Later-Phase Domains

The following domains are important, but may be better suited for later phases after the core TeamCORE foundation is stable.

#### Benefits

The Benefits domain tracks benefit plans, eligibility, enrollment, employer cost, team member deductions, and coverage tiers.

Benefits should likely be deferred because plan rules, dependent tiers, enrollment windows, deduction timing, eligibility rules, and external provider coordination can become complex quickly. For the MVP, TeamCORE may only need to preserve basic benefit-related references or placeholders.

#### Training and Certification

The Training and Certification domain tracks required and optional training, assigned training, completions, certifications, expiration, and renewal tracking.

This is highly relevant for travel agencies, but it can be phased after the core Team Member, Engagement, Documents, and Team360 models are established.

#### Performance Reviews

The Performance Reviews domain tracks review cycles, role-based metrics, supervisor reviews, contractor performance reviews, and review history.

This should come later because it depends on stable roles, reporting lines, engagement status, and performance expectations. Contractor performance reviews may also need different terminology and workflows than employee performance reviews.

#### Company Assets

The Company Assets domain tracks agency assets assigned to team members, including issue and return history, lost asset status, replacement value, and recovery handling.

This is operationally useful, but it can be deferred unless asset tracking is a first-release requirement. Later, lost or damaged asset recovery can integrate with employee payroll deduction instructions or contractor charges and recoverables.

---

### MVP vs Later Summary

| Domain | Phase | Reason |
| :---- | :---- | :---- |
| Organization | MVP | Needed for structure, reporting lines, and authority |
| Team Member / Party | MVP | Core identity model for people and organizations |
| Engagement | MVP | Defines employment or contractor relationship |
| Compensation | MVP | Needed for pay and settlement context |
| Contractor Charges and Recoverables | MVP | Core contractor-specific financial capability |
| Time Tracking | MVP | Supports hourly work, approvals, and payroll inputs |
| Leave | MVP | Supports employee time away and payroll inputs |
| Payroll and Settlement Runs | MVP | Provides export/import structure and run history |
| Documents and Compliance | MVP | Supports employee/contractor documentation and classification |
| Team360 | MVP | Primary unified profile and dashboard |
| Benefits | Later | Complex rules and external coordination |
| Training and Certification | Later | Valuable, but can follow the core profile foundation |
| Performance Reviews | Later | Depends on stable roles, reporting, and metrics |
| Company Assets | Later | Useful operational add-on, but not foundational |

## Major Product Domains

TeamCORE is organized around several major domains.

### Organization

The Organization domain tracks the agency’s internal structure, including departments, branches, teams, reporting relationships, lines of authority, and organizational charts.

### Team Member / Party

The Team Member / Party domain stores identity and profile information for people and organizations. This includes employees, individual contractors, contractor organizations, primary contacts, contact information, addresses, and related parties.

### Engagement

The Engagement domain tracks the formal employment or contractor relationship between the agency and the team member. This includes employee positions, contractor agreements, contract lifecycle, job changes, renewals, expirations, and status history.

### Compensation

The Compensation domain tracks amounts the agency may owe to team members, including salary, hourly wages, commissions, tiered commission plans (later phases), **employee** minimum-commission draws and recoveries, and compensation plan assignments.[^p4-draw]

### Contractor Charges and Recoverables

The Contractor Charges and Recoverables domain tracks amounts that independent contractors may owe to the agency. These may include onboarding fees, annual renewal fees, recurring monthly fees, technology fees, pass-through expenses, reimbursable costs, chargebacks, waivers, write-offs, and balances recovered through **contractor** settlement or direct payment.

### Benefits

The Benefits domain tracks benefit plans, eligibility, enrollment, employer costs, team member deductions, coverage tiers, and related history. Benefits primarily apply to employees, although the system should be careful to distinguish any contractor-related programs from employee benefits.

### Time Tracking

The Time Tracking domain tracks working hours through timeclock punches, manual timesheets, daily hour entries, start/end times, and pay-period summaries. Some salaried employees may be configured not to track daily working time.

### Leave

The Leave domain tracks paid and unpaid time off, including PTO, medical leave, FMLA, bereavement, leave banks, requests, approvals, balances, and paid leave hours shared with time tracking and payroll processing.

### Payroll and Settlement Runs

The Payroll and Settlement Runs domain packages pay-related information for external processing. For employees, this may include payroll input exports, compensation inputs (including employee commission and **minimum commission draw** mechanics where applicable), and imported payroll results. For contractors, this may include **contractor settlement** runs: commission, contractor charge deductions, and imported payment results—distinct from employee draw recovery.[^p4-settlement] TeamCORE should prepare payroll and settlement information, while external processors remain responsible for payroll tax calculations, statutory withholdings, filings, and final payment execution unless a future scope explicitly expands that boundary.

### Training and Certification

The Training and Certification domain tracks required and optional training, assigned training, completion status, certifications, expiration dates, renewal requirements, and supporting evidence.

### Performance Reviews

The Performance Reviews domain tracks role-based metrics, review cycles, supervisor reviews, contractor performance reviews, acknowledgments, and review history.

### Company Assets

The Company Assets domain tracks agency-owned assets assigned to team members, including equipment, issue dates, return dates, assignment history, lost or damaged status, replacement value, and recovery handling.

### Documents and Compliance

The Documents and Compliance domain tracks required records such as employment documents, contractor agreements, tax forms, benefit forms, policy acknowledgments, certifications, classification documentation, insurance evidence, and other compliance materials.

## Summary

TeamCORE is a specialized workforce operations platform for travel agencies that need to manage both employees and independent contractors in a clear, structured, and compliant way. Its core value is combining HR-like functionality, contractor management, commission and settlement support, document tracking, training, asset assignment, and Team360 profile visibility into a single agency-focused system.

By centering the product around **Team Members**, **Engagements**, and **Team360**, TeamCORE can give agencies a complete operational view of their workforce while preserving the important legal and business distinctions between employees, individual contractors, and contractor organizations.

## Domains

TeamCORE is organized around the following domains:

* **Organization** — agency structure, departments, locations, teams, reporting relationships, and lines of authority.  
* **Team Member / Party** — person and organization records for employees, individual contractors, contractor organizations, and related contacts.  
* **Engagement** — the employment or contractor relationship between the agency and the team member, including position, contract, lifecycle, status, and assignment history.  
* **Compensation** — salary, hourly wage, commission, tiered commission, **employee** minimum-commission draws and recovery, and compensation plan assignment.  
* **Contractor Charges and Recoverables** — onboarding fees, renewal fees, recurring contractor fees, reimbursable expenses, pass-through costs, waivers, write-offs, and contractor balances owed to the agency.  
* **Benefits** — benefit plans, eligibility, enrollment, employer cost, team member deductions, and coverage tiers.  
* **Time Tracking** — timeclock punches, manual timesheets, salaried no-daily-time configurations, timesheet approvals, and pay-period time summaries.  
* **Leave** — paid and unpaid leave banks, requests, approvals, usage, balances, and payroll/time integration.  
* **Payroll and Settlement Runs** — employee payroll input exports, contractor settlement runs, external processor imports, final payment results, and payroll/settlement history.  
* **Training and Certification** — required and optional training, assigned training, completions, certifications, expiration, and renewal tracking.  
* **Performance Reviews** — review cycles, role-based metrics, supervisor reviews, contractor performance reviews, and review history.  
* **Company Assets** — agency assets assigned to team members, issue/return tracking, lost asset status, replacement value, and recovery handling.  
* **Documents and Compliance** — employment documents, contractor agreements, tax forms, certification evidence, policy acknowledgments, classification documentation, and compliance status.  
* **Team360** — a permission-aware dashboard that aggregates information from the other domains into a unified team member profile.

# Comprehensive Domain Descriptions for TeamCORE

The following section expands the proposed TeamCORE domains into fuller product descriptions. These descriptions are written for an overview or product concept document, not as a detailed technical specification.

TeamCORE is organized around domains because each major area of the system owns a different part of the team member lifecycle. Some domains are foundational for the MVP, while others may be implemented in later phases after the core workforce, engagement, compensation, and Team360 model is stable. The domain structure should preserve the key distinction identified in the original proposal: travel agencies may work with both employees and independent contractors, including contractor organizations, and TeamCORE must manage those relationships without treating them as identical.

---

# Proposed MVP Domains

## Organization

The **Organization** domain tracks the agency’s internal structure and lines of authority. It defines how the agency is organized, where team members are assigned, who supervises whom, and how responsibility flows through the business.

This domain may include departments, branches, locations, divisions, teams, job families, reporting lines, and supervisory relationships. It should support both formal organizational hierarchy and practical operating relationships, such as a contractor reporting to an agency manager without being treated as an employee.

Organization is included in the MVP because TeamCORE cannot provide meaningful Team360 profiles, approvals, leave routing, performance workflows, or authority-based visibility without knowing where each team member fits within the agency.

### Key Responsibilities

* Track agency structure, departments, locations, and teams.  
* Maintain reporting relationships and lines of authority.  
* Support organization charts and supervisory views.  
* Identify managers, supervisors, and operational owners.  
* Provide structure for approvals, reviews, and visibility rules.  
* Distinguish organizational placement from legal employment status.

### Example Use Cases

* View all team members assigned to a department.  
* Identify a team member’s supervisor.  
* Route leave requests to the correct approver.  
* Display reporting relationships in Team360.  
* Show contractor oversight relationships without misclassifying contractors as employees.

---

## Team Member / Party

The **Team Member / Party** domain is the identity foundation of TeamCORE. It stores the people and organizations that have a relationship with the agency.

A team member may be an employee, an individual independent contractor, or a contractor organization such as a corporation or LLC. Employees are generally people, while contractors may be either individuals or legal entities. For contractor organizations, TeamCORE should track the organization itself as well as its primary contact and, where applicable, related subcontractors.

This domain should separate the underlying identity record from the agency relationship. In other words, a person or organization exists as a party, while their employment or contractor relationship is handled through the Engagement domain.

### Key Responsibilities

* Store person records.  
* Store organization records.  
* Track names, contact information, addresses, and profile details.  
* Identify whether a team member is a person or organization.  
* Track primary contacts for contractor organizations.  
* Support related parties, such as subcontractors or organization representatives.  
* Provide identity data used throughout TeamCORE.

### Example Use Cases

* Create a profile for a new employee.  
* Create a profile for an independent contractor operating as an LLC.  
* Track the primary contact for a contractor organization.  
* Store multiple contact methods for a team member.  
* View related persons or organizations connected to a contractor.

### Important Boundary

The Team Member / Party domain identifies **who or what the party is**. It should not own the employment contract, job position, compensation plan, leave balance, payroll history, or contractor charges. Those records belong to other domains.

---

## Engagement

The **Engagement** domain defines the formal relationship between the agency and a team member. This is one of the most important domains in TeamCORE.

For employees, an engagement may include employment status, position, job title, department assignment, supervisor, start date, end date, and job history. For contractors, an engagement may include contract terms, contract status, renewal dates, expiration dates, commission arrangement, contractor classification, and contract lifecycle history.

Engagement should become the anchor for many other domains. Compensation, contractor charges, benefits eligibility, time tracking rules, leave eligibility, payroll schedule, settlement schedule, required documents, and review expectations may all depend on the active engagement.

### Key Responsibilities

* Track employment relationships.  
* Track contractor agreements.  
* Maintain active, inactive, terminated, expired, or pending statuses.  
* Store start dates, end dates, renewal dates, and expiration dates.  
* Track job position and assignment history.  
* Track contract lifecycle events and modifications.  
* Connect team members to compensation, payroll, settlement, document, and compliance rules.  
* Preserve historical engagement records.

### Example Use Cases

* View a team member’s current employment position.  
* Track a contractor agreement renewal.  
* Record a job change or department transfer.  
* Show whether a team member is active, inactive, terminated, or expired.  
* Determine which compensation plan or contractor fee schedule applies.  
* Review a team member’s prior engagements with the agency.

### Important Boundary

Engagement defines the **relationship**. It should not replace the identity record, compensation calculations, payroll run, or document storage. Instead, it provides the context that determines which rules and records apply.

---

## Compensation

The **Compensation** domain tracks how team members are paid or become eligible to be paid by the agency.

For employees, this may include salary, hourly wage, pay rate history, compensation plan assignment, commission eligibility, and **minimum commission draw** arrangements (recoverable draws for commissioned employees only). For contractors, this may include commission plans, flat-rate commission (MVP), and settlement-related compensation rules paid through **contractor settlement**—without treating employee draw recovery as part of that settlement rail.[^p4-contractor-comp]

Compensation should focus on amounts the agency may owe to the team member. It should be kept separate from contractor charges and recoverables, which represent amounts the contractor may owe back to the agency.

### Key Responsibilities

* Define salary, hourly, and commission-based compensation plans.  
* Track compensation plan assignments.  
* Store effective dates and compensation history.  
* Support fixed, variable, and mixed compensation structures.  
* Track commission eligibility and commission plan terms.  
* Support **employee** minimum commission draw and recovery (employee-only; not contractor settlement).[^p4-draw]  
* Feed **employee** payroll preparation and **contractor** settlement runs with the appropriate compensation inputs (rails stay separate).[^p4-settlement]

### Example Use Cases

* Assign an employee to an hourly wage plan.  
* Assign a contractor to a commission plan.  
* Track a salary change effective on a future date.  
* View a team member’s current compensation arrangement.  
* Calculate or record commissionable earnings for a pay or settlement period (employee vs contractor context).  
* Track whether a **commissioned employee** has an outstanding minimum-commission draw balance.

### MVP Boundary

For the MVP, Compensation may begin with plan setup, assignments, rates, effective dates, flat-rate commission, and **employee** minimum-commission draw visibility where that plan type applies. More advanced features, such as full commission automation, complex tiering, productivity thresholds, and contractor “draw-like” constructs, can be expanded later.

---

## Contractor Charges and Recoverables

The **Contractor Charges and Recoverables** domain tracks amounts that independent contractors may owe to the agency.

This domain exists because contractor relationships often include financial obligations that do not fit cleanly into employee payroll or compensation. Examples may include onboarding fees, annual renewal fees, recurring monthly administrative fees, technology fees, pass-through expenses, reimbursable costs, chargebacks, debit memo recoveries, lost asset recoveries, waivers, write-offs, and other contractually authorized charges.

This domain should be separate from Compensation. Compensation tracks what the agency owes the team member. Contractor Charges and Recoverables tracks what the contractor owes the agency.

### Key Responsibilities

* Track contractor fees and recoverable expenses.  
* Support one-time, recurring, annual, and manually assessed charges.  
* Track due dates, statuses, balances, and recovery methods.  
* Support deductions from contractor settlements.  
* Support direct payment, invoice, waiver, write-off, or dispute workflows.  
* Maintain a contractor receivable balance.  
* Display charge and recovery history in Team360.

### Example Use Cases

* Assess a one-time contractor onboarding fee.  
* Charge an annual contractor renewal fee.  
* Track a monthly platform or technology fee.  
* Record an agency-paid expense that must be reimbursed by the contractor.  
* Deduct an outstanding charge from a **contractor** settlement.  
* Waive a contractor fee.  
* Write off an uncollectible contractor balance.

### Important Boundary

This domain should generally apply to independent contractors, not employees. Employee deductions should be handled through payroll, benefits, or authorized deduction workflows, while contractor charges should be handled through contractor agreement administration, settlement deductions, invoicing, or direct payment tracking.

---

## Time Tracking

The **Time Tracking** domain captures working time for team members who are required to report hours.

This may include web-based timeclock punches, manual timesheets, daily hour entries, start and end times, exception handling, approvals, and pay-period summaries. Some salaried employees may not track daily time worked, so TeamCORE should support a no-daily-time configuration where appropriate.

Time Tracking is included in the MVP because it provides essential input for payroll, supervision, workforce management, and leave integration.

### Key Responsibilities

* Track timeclock punches.  
* Support manual timesheets.  
* Capture daily hours or start/end times.  
* Support salaried employees who do not track daily hours.  
* Provide approval workflows for timesheets.  
* Identify exceptions, missing punches, or incomplete entries.  
* Produce pay-period time summaries for payroll export.  
* Integrate approved paid leave hours where applicable.

### Example Use Cases

* Employee punches in and out using a web timeclock.  
* Employee submits a weekly manual timesheet.  
* Supervisor approves or rejects a timesheet.  
* Payroll manager reviews pay-period time totals.  
* Salaried employee is marked as not requiring daily time entry.  
* Paid leave hours flow into the pay-period time summary.

### Important Boundary

Time Tracking records working time. It should not calculate payroll taxes, final net pay, or statutory withholdings. It should produce approved time inputs for Payroll and Settlement Runs.

---

## Leave

The **Leave** domain tracks paid and unpaid time away from work.

This may include PTO, sick leave, medical leave, FMLA, bereavement, jury duty, unpaid leave, and other agency-defined leave types. Team members may be assigned to leave banks with limited annual hours, accrued balances, fixed allocations, or unlimited availability depending on agency policy.

Leave should support employee requests, supervisor approvals, manual supervisor entry, leave balances, leave usage history, and integration with Time Tracking and Payroll.

### Key Responsibilities

* Define leave types.  
* Track leave banks and balances.  
* Support limited, accrued, fixed, or unlimited leave rules.  
* Allow team members to request leave.  
* Allow supervisors to approve, deny, or manually enter leave.  
* Track paid and unpaid leave usage.  
* Share paid leave hours with Time Tracking and Payroll.  
* Maintain leave history for Team360.

### Example Use Cases

* Employee requests PTO.  
* Supervisor approves medical leave.  
* HR enters bereavement leave manually.  
* TeamCORE reduces the employee’s leave balance.  
* Approved paid leave appears in the pay-period time summary.  
* Team360 displays available PTO and recent leave history.

### Important Boundary

Leave primarily applies to employees. Contractors may have availability or absence tracking, but that should be carefully distinguished from employee leave benefits to avoid confusing contractor status with employee status.

---

## Payroll and Settlement Runs

The **Payroll and Settlement Runs** domain packages pay-related information for external processing and stores the results returned from external systems.

For employees, this includes pay schedules, payroll input exports, approved time, leave hours, benefit deduction instructions, compensation inputs (including employee commission and **minimum commission draw** effects where applicable), and imported payroll results. For contractors, this may include settlement schedules, commission calculations, contractor charge deductions, and contractor payment results—**not** employee draw recovery.[^p4-settlement]

This domain should be broader than traditional payroll because TeamCORE must support both employee payroll and contractor settlement workflows.

### Key Responsibilities

* Define pay schedules and settlement schedules.  
* Gather payroll inputs for employees.  
* Gather settlement inputs for contractors.  
* Export payroll or settlement data to external processors.  
* Import final payroll or settlement results.  
* Store per-run and per-team-member payment history.  
* Show payroll and settlement history in Team360.  
* Preserve audit history for exported and imported files.

### Example Use Cases

* Generate an employee payroll export file.  
* Generate a contractor settlement run.  
* Include approved time and leave hours in payroll inputs.  
* Deduct contractor charges from a contractor settlement.  
* Import final payroll results from an external processor.  
* View net pay, withholding, or adjustment details returned by the processor.  
* Display prior payroll or settlement runs in Team360.

### Product Boundary

TeamCORE should not initially be a full payroll tax engine. It should prepare payroll and settlement inputs, export them to external processors, import results, and display those results. External payroll processors should remain responsible for tax calculation, statutory withholding, filings, and final payment execution unless that scope is intentionally expanded in a later phase.

---

## Documents and Compliance

The **Documents and Compliance** domain tracks required documents, supporting evidence, and compliance status for team members and engagements.

This domain is especially important because TeamCORE must preserve distinctions between employees, individual contractors, and contractor organizations. Each engagement type may require different documentation, such as employment agreements, contractor agreements, W-4 forms, W-9 forms, benefit forms, policy acknowledgments, certification evidence, insurance records, E\&O documentation, contract amendments, and classification support.

Documents and Compliance should help the agency understand whether a team member is properly documented for their current engagement.

### Key Responsibilities

* Store or reference required documents.  
* Track document types and requirements.  
* Track document status, expiration, and renewal needs.  
* Support employee-specific and contractor-specific document sets.  
* Track contractor classification documentation.  
* Store policy acknowledgments and required attestations.  
* Provide compliance status in Team360.  
* Alert users to missing, expired, or pending documents.

### Example Use Cases

* Upload a signed contractor agreement.  
* Track whether a W-9 has been received.  
* Store an employee policy acknowledgment.  
* Record certification evidence.  
* Alert agency staff that a contractor agreement is expiring.  
* Show missing onboarding documents in Team360.  
* Track whether a contractor organization has required insurance documentation.

### Important Boundary

This domain should not decide legal classification by itself. It should store the records, statuses, and evidence the agency uses to manage and support classification decisions.

---

## Team360

**Team360** is the unified team member dashboard. It aggregates information from the other TeamCORE domains into a single permission-aware profile.

Team360 should give users a complete operational view of a team member without requiring them to visit every individual domain separately. It should show identity, current engagement, organizational placement, compensation summary, contractor charge balance, time and leave status, payroll or settlement history, documents, compliance status, training, certifications, reviews, and assets as those domains become available.

Team360 should be included in the MVP because it is the primary way users experience the value of TeamCORE.

### Key Responsibilities

* Provide a unified team member profile.  
* Aggregate current and historical information from other domains.  
* Show engagement status and key details.  
* Display compensation, payroll, settlement, and charge summaries.  
* Show time, leave, document, and compliance status.  
* Support permission-aware visibility.  
* Provide navigation into the underlying domain records.  
* Avoid duplicating or replacing authoritative domain data.

### Example Use Cases

* Agency admin reviews a contractor’s current contract, commission plan, and outstanding fees.  
* Supervisor views an employee’s reporting line, leave balance, and review history.  
* Payroll staff views payroll schedule, approved time, and recent pay results.  
* Compliance user reviews missing documents and expiring agreements.  
* Team member views their own profile, time entries, leave requests, or training assignments if self-service is enabled.

### Important Boundary

Team360 should be an aggregation and navigation layer. It should not become the system of record for compensation, leave, time, documents, payroll, settlement, or compliance data.

---

# Later-Phase Domains

## Benefits

The **Benefits** domain tracks benefit programs offered to eligible team members.

This may include employer-sponsored health insurance, dental, vision, retirement plans, employer contributions, employee deductions, coverage tiers, dependent tiers, eligibility rules, enrollment periods, and benefit history.

Benefits are important, but they can become complex quickly. Eligibility, enrollment windows, dependent coverage, deduction timing, external carrier coordination, and compliance obligations may require significant domain modeling. For that reason, Benefits may be better suited for a later phase after the core TeamCORE foundation is stable.

### Key Responsibilities

* Define benefit plans.  
* Track eligibility rules.  
* Track enrollment and coverage tiers.  
* Track employer cost and team member deductions.  
* Support flat or percentage-based deductions.  
* Support dependent-based pricing tiers.  
* Feed benefit deduction instructions into payroll.  
* Maintain benefit enrollment history.

### Example Use Cases

* Enroll an employee in a health insurance plan.  
* Track employer and employee cost shares.  
* Apply a per-pay-period benefit deduction.  
* Track coverage tier based on dependents.  
* Show benefit enrollment history in Team360.  
* Identify team members eligible for a benefit plan.

### Important Boundary

Benefits should primarily apply to employees. If any contractor-related benefits, discounts, reimbursements, or programs are tracked, they should be clearly separated from employee benefits to avoid classification ambiguity.

---

## Training and Certification

The **Training and Certification** domain tracks required and optional learning, certifications, credentials, and renewals.

This domain is especially relevant for travel agencies because team members may need supplier training, destination training, industry certifications, compliance training, product certifications, or agency-specific onboarding courses.

Training and Certification should eventually support assignments, completion status, certification dates, expiration dates, renewal requirements, evidence uploads, and reminders.

### Key Responsibilities

* Define training courses and certification types.  
* Track required and optional training.  
* Assign training to team members or roles.  
* Track completion status and completion dates.  
* Store certification attainment, expiration, and renewal dates.  
* Track supporting evidence or documents.  
* Show training and certification status in Team360.

### Example Use Cases

* Assign mandatory onboarding training to a new employee.  
* Track completion of supplier training.  
* Record a travel industry certification.  
* Alert a team member that a certification is expiring.  
* Show completed and pending training in Team360.  
* Require specific training based on role or engagement type.

### Implementation Timing

This can be phased after the Team Member, Engagement, Documents, and Team360 foundations exist. In the MVP, certifications may be represented through Documents and Compliance as a simplified placeholder.

---

## Performance Reviews

The **Performance Reviews** domain tracks formal evaluations, review cycles, role-based metrics, supervisor feedback, and performance history.

For employees, this may include periodic performance reviews, goal tracking, role-based scoring, supervisor comments, acknowledgments, and improvement plans. For contractors, the equivalent may be better framed as contractor performance, production, quality, or compliance reviews rather than employee performance management.

This domain depends on stable organization structure, roles, reporting relationships, and engagement definitions. For that reason, it is a strong later-phase candidate.

### Key Responsibilities

* Define review cycles.  
* Define review templates and role-based metrics.  
* Allow supervisors to create reviews.  
* Track ratings, comments, goals, and outcomes.  
* Support team member acknowledgments.  
* Track historical reviews.  
* Support contractor-specific review language and workflows.  
* Display review history in Team360.

### Example Use Cases

* Supervisor completes an annual employee review.  
* Agency reviews contractor production and compliance.  
* Team member acknowledges a completed review.  
* HR reviews performance history.  
* Team360 displays most recent review date and outcome.  
* Manager tracks goals or follow-up items from a review.

### Important Boundary

Employee performance reviews and contractor performance reviews should not necessarily use identical language or workflows. TeamCORE should preserve the legal and operational difference between managing an employee and evaluating a contractor relationship.

---

## Company Assets

The **Company Assets** domain tracks agency-owned assets assigned to team members.

Assets may include laptops, phones, tablets, office equipment, ID badges, access cards, software licenses, hardware tokens, marketing materials, or other agency property. The domain should track asset type, original value, replacement value, assignment history, issue date, due date, return date, lost or damaged status, and recovery handling.

This is useful operationally, but may be deferred unless the agency needs asset accountability in the first release.

### Key Responsibilities

* Maintain an asset catalog.  
* Track asset types, values, and identifiers.  
* Assign assets to team members.  
* Track issue dates, due dates, and return dates.  
* Track assignment history.  
* Mark assets lost, damaged, returned, or overdue.  
* Support replacement value and recovery handling.  
* Display assigned assets in Team360.

### Example Use Cases

* Issue a laptop to a new employee.  
* Assign a phone to a contractor.  
* Track whether equipment has been returned during offboarding.  
* Mark an asset as lost.  
* Record replacement value.  
* Trigger an employee payroll deduction instruction where allowed.  
* Create a contractor recoverable charge for a lost asset.

### Integration with Other Domains

Company Assets should integrate with:

* **Engagement**, for onboarding and offboarding.  
* **Documents and Compliance**, for asset acknowledgments.  
* **Contractor Charges and Recoverables**, for contractor asset recovery.  
* **Payroll and Settlement Runs**, if employee deductions or contractor settlement deductions are supported.

---

### MVP vs Later Summary

| Domain / Capability | Phase | Reason |
| :---- | :---- | :---- |
| Organization | MVP | Needed for structure, reporting lines, approvals, and authority |
| Team Member / Party | MVP | Core identity model for people and organizations |
| Engagement | MVP | Defines employment or contractor relationship |
| Documents and Compliance | MVP | Supports required records, contractor classification support, missing-document alerts, and expiration alerts |
| Team360 | MVP | Primary unified profile and dashboard |
| Compensation | MVP | Supports salary/hourly tracking, flat-rate commission, and **employee** minimum-commission draw recovery context |  
| Contractor Charges and Recoverables | MVP | Core contractor-specific financial capability |
| Payroll and Settlement Runs | MVP | Provides CSV/XLSX export/import, manual results entry, run history, and Team360 visibility |
| Time Tracking | MVP | Employee-only time capture, review, and payroll input support |
| Leave | MVP | Employee leave requests, balances, approvals, and payroll/time review |
| Limited Employee Self-Service | MVP | Supports employee time entry, timeclock, timesheet submission, and leave requests |
| Operational Reporting | MVP | Provides roster, compliance, contractor balance, payroll, settlement, time, leave, and org views |
| MVP Audit History | MVP | Captures lifecycle events and sensitive field-level changes |
| Benefits | Later | Complex rules, enrollment windows, deduction timing, and external coordination |
| Training and Certification | Later | Valuable, but can follow the core profile and compliance foundation |
| Performance Reviews | Later | Depends on stable roles, reporting, metrics, and engagement definitions |
| Company Assets | Later | Useful operational add-on, but not foundational |
| Contractor Self-Service | Later | Broader permissions and contractor access should follow core workflow stability |
| Advanced Commission Engine | Later | Tiers, splits, overrides, supplier rules, and integrations are deferred |
| Payroll Provider Integrations | Later | Vendor-specific mappings and APIs should follow generic file-based MVP workflows |
| AR Aging / Disputes / Write-Offs | Later | Contractor charge MVP uses basic statuses and waivers only |  
| Advanced Analytics | Later | MVP reporting should focus on operational views, not advanced analytics |  

---

## Footnotes (product copy reconciliations)

[^p4-draw]: **Substantial change — Phase 4 / developer brief (TC-16).** Prior wording suggested repayable draws recovered via “contractor commission settlements,” which conflated **employee** minimum commission draw recovery with **contractor settlement**. The product model is: draw recovery for this mechanism is **employee-only** and runs in the **compensation** rail (future employee commission / payroll-input preparation), not as a deduction inside contractor settlement or contractor charges.

[^p4-settlement]: **Substantial change — Phase 4 / developer brief.** **Employee payroll** (and payroll-oriented preparation) and **contractor settlement** are separate workflows. Contractor settlement includes contractor commission, contractor charge deductions, and adjustments. Employee minimum-commission draw recovery must not be described as part of contractor settlement inputs or results.

[^p4-draw-list]: **Substantial change — Phase 4.** The combined “final results” list previously used an undifferentiated “draw recoveries” line that implied contractor settlement. Draw recovery in that list refers to **employee** minimum-commission draw recovery / compensation-side amounts where applicable, not contractor settlement math.

[^p4-contractor-comp]: **Substantial change — Phase 4.** MVP contractor compensation emphasizes **flat-rate commission** via **contractor settlement**. Prior text implied contractor “draw arrangements” parallel to employee draws; **minimum commission draw recovery** remains **employee-only** unless a future scope explicitly adds a distinct contractor construct.
