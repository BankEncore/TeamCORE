# Revised TeamCORE Roadmap

## 1\. Purpose

The TeamCORE roadmap defines how the product should move from concept to MVP and then into later-phase expansion. The roadmap is organized around domain readiness, workflow readiness, Team360 usefulness, and the need to preserve the legal and operational distinction between employees, independent contractors, contractor organizations, and subcontractors.

The roadmap should not be treated as a flat feature list. Each phase should establish a foundation that later phases can safely build on.

TeamCORE’s MVP should be strong enough to manage the core lifecycle of employees and contractors, but narrow enough to avoid becoming a full payroll tax engine, general accounting system, benefits carrier platform, or travel accounting system.

---

# 2\. Roadmap Principles

## 2.1 Engagement-first architecture

TeamCORE should be built around the idea that a team member has one or more **engagements** with the agency.

The engagement determines whether the person or organization is an employee, individual contractor, contractor organization, subcontractor, former worker, pending hire, active worker, or expired contractor.

Most team members will have one active engagement at a time. TeamCORE should support multiple active engagements when needed, but this should be treated as an exception workflow rather than the normal case.

---

## 2.2 Employee and contractor workflows must remain distinct

TeamCORE must avoid blending employees and contractors into one generic HR model.

Employees may have:

* payroll  
* benefits  
* leave  
* time tracking  
* job positions  
* employee performance reviews  
* employee-specific documents

Contractors may have:

* contracts  
* commission settlements  
* contractor charges  
* recoverable expenses  
* renewals  
* classification documentation  
* contractor performance or compliance reviews

The product should preserve this distinction in the data model, workflows, permissions, documents, payroll/settlement handling, and Team360 display.

---

## 2.3 Team360 should come early, but not every panel must be fully automated

Team360 should be part of the MVP because it is the primary user-facing value of TeamCORE.

MVP Team360 should include functional panels for:

* identity and contact summary  
* current engagement  
* engagement history  
* organization placement and reporting line  
* compensation summary  
* contractor charges and balance summary  
* time summary  
* leave summary  
* payroll or settlement history  
* documents and compliance status  
* alerts and missing items

MVP Team360 may also include lightweight placeholder panels for later-phase domains:

* benefits  
* training and certification  
* performance reviews  
* company assets

These placeholder panels may show “not yet configured,” limited manual summary data, document/compliance references, or links to future module areas.

---

## 2.4 Payroll and settlement should be integration-oriented

TeamCORE MVP should treat payroll and settlement as export/import workflows, not as a full payroll tax engine.

MVP should support:

* generic CSV export  
* generic Excel/XLSX export  
* generic CSV import  
* generic Excel/XLSX import  
* manual entry of final payroll or settlement results

Vendor-specific payroll integrations, payroll APIs, automated reconciliation, and processor-specific mappings should be deferred to later phases.

---

## 2.5 Compliance must be present from the beginning

Because TeamCORE’s central distinction is employee vs contractor, compliance cannot be bolted on later.

MVP should include:

* required document tracking  
* employee and contractor document requirements  
* missing-document alerts  
* expiration alerts  
* expiring-soon alerts  
* contractor classification support  
* document verification by authorized users

TeamCORE should not make legal classification decisions. It should help agencies maintain the records and status information that support those decisions.

---

## 2.6 MVP self-service should be narrow

MVP self-service should focus on employee time and leave.

MVP self-service may include:

* employee timeclock punch in/out  
* manual daily time entry  
* weekly timesheet submission  
* leave request submission  
* leave balance visibility  
* time/leave request status visibility

Broader employee and contractor self-service should be deferred.

Deferred self-service includes:

* contractor portal  
* team member document upload  
* profile update requests  
* training completion self-service  
* certification uploads  
* payroll/settlement statement viewing  
* benefit enrollment  
* asset acknowledgments

---

## 2.7 MVP audit should cover lifecycle and sensitive records

MVP should include audit history beyond basic timestamps.

At minimum, it should track:

* lifecycle events for major records  
* field-level changes for sensitive records

Sensitive records include:

* engagement status and dates  
* contractor classification fields  
* compensation plan assignments  
* pay rates  
* commission rates  
* draw balances  
* contractor charges  
* contractor waivers  
* payroll and settlement results  
* document verification status  
* document expiration dates  
* leave balances  
* timesheet approvals

---

# 3\. Domain Dependency Overview

The roadmap should be driven by the relationships between domains.

```
Organization
   ├── supports reporting lines
   ├── supports approvals
   ├── supports role/context visibility
   └── supports Team360 context

Team Member / Party
   ├── identifies people
   ├── identifies organizations
   ├── supports individual contractors
   ├── supports contractor organizations
   └── supports subcontractor relationships

Engagement
   ├── determines employee vs contractor relationship
   ├── determines active/inactive lifecycle status
   ├── determines compensation rules
   ├── determines contractor charge applicability
   ├── determines time/leave applicability
   ├── determines document requirements
   ├── determines payroll/settlement schedule
   └── drives Team360 status

Documents and Compliance
   ├── validates onboarding/readiness
   ├── tracks required records
   ├── tracks missing/expired/expiring documents
   └── supports contractor classification

Compensation
   ├── defines salary/hourly/commission plans
   ├── supports manually entered or imported sales/revenue
   ├── calculates flat-rate commission in MVP
   └── feeds payroll or contractor settlement

Contractor Charges and Recoverables
   ├── tracks contractor fees
   ├── tracks recoverable expenses
   ├── supports settlement deduction
   ├── supports invoice/direct payment recovery
   └── feeds contractor settlement

Time Tracking
   ├── applies to employees only in MVP
   ├── is configured by engagement or position
   ├── supports timeclock/manual/weekly/supervisor-entered time
   └── feeds employee payroll inputs after review

Leave
   ├── applies to employees only in MVP
   ├── supports manual balances
   ├── supports configurable approvals
   └── feeds payroll/time summaries after review

Payroll and Settlement Runs
   ├── packages employee payroll inputs
   ├── packages contractor settlement inputs
   ├── supports CSV/XLSX export/import
   ├── supports manual final-result entry
   └── stores imported/manual results

Team360
   └── aggregates all of the above into a permission-aware profile
```

---

# 4\. Revised Roadmap Structure

The working draft currently organizes the roadmap into ten phases. I would revise the MVP phase sequence slightly so Documents and Compliance comes before Team360, and so audit/reporting are explicitly part of MVP readiness.

```
Phase 0 — Product framing and domain model
Phase 1 — Core identity, organization, and engagement foundation
Phase 2 — Documents, compliance, and activation readiness
Phase 3 — Team360 MVP and operational reporting
Phase 4 — Compensation, contractor charges, and settlement basics
Phase 5 — Employee time, leave, and payroll input workflows
Phase 6 — MVP hardening, permissions, audit, and release readiness

Later Phase 7 — Benefits expansion
Later Phase 8 — Training and certification expansion
Later Phase 9 — Performance review expansion
Later Phase 10 — Company assets expansion
Later Phase 11 — Advanced automation, analytics, and integrations
```

---

# Phase 0 — Product Framing and Domain Model

## Purpose

Establish the conceptual foundation before implementation begins.

## Key Questions Resolved

* What is a Team Member?  
* What is a Party?  
* What is an Engagement?  
* What distinguishes an employee from a contractor?  
* Can a contractor be an organization?  
* Can a contractor have subcontractors?  
* What does TeamCORE own versus import/export?  
* What belongs in MVP versus later?  
* How does Team360 relate to the underlying domains?  
* How should payroll and settlement boundaries be defined?

## Deliverables

* Product overview  
* Domain map  
* MVP/later scope definition  
* Glossary  
* Engagement model decision  
* Employee vs contractor applicability matrix  
* Payroll/settlement boundary statement  
* Team360 concept  
* Roadmap decision log  
* Open decision register

## Key Decisions Captured

* TeamCORE supports multiple active engagements as an exception workflow.  
* Contractor organizations may have subcontractors.  
* Subcontractors may be related contacts or first-class team members depending on agency configuration and operational need.  
* Employee and contractor status models remain distinct.  
* “On Leave” is derived from the Leave domain rather than treated as a primary employee status.  
* TeamCORE is not a full payroll tax engine.  
* Documents and Compliance is part of MVP.

## Exit Criteria

Phase 0 is complete when the core domain language is stable enough that development work can be broken into implementation epics and stories.

---

# Phase 1 — Core Identity, Organization, and Engagement Foundation

## Purpose

Create the minimum foundation needed to represent agencies, team members, parties, and their formal relationships.

## Included Domains

* Organization  
* Team Member / Party  
* Engagement

## Capabilities

### Organization

* Create and manage departments.  
* Create and manage teams.  
* Create and manage locations or branches.  
* Track reporting relationships.  
* Assign supervisors or managers.  
* Support basic organization/reporting views.

### Team Member / Party

* Create person records.  
* Create organization records.  
* Track basic contact information.  
* Identify whether a team member is a person or organization.  
* Identify employees, individual contractors, contractor organizations, and subcontractors.  
* Track primary contact for contractor organizations.  
* Track subcontractors as related contacts or first-class team members depending on agency configuration.

### Engagement

* Create employee engagements.  
* Create contractor engagements.  
* Track engagement status.  
* Track start dates, end dates, renewal dates, and expiration dates.  
* Track position or contract summary.  
* Track engagement history.  
* Support multiple active engagements as an exception workflow.  
* Preserve closed engagement history.  
* Allow authorized admin correction with audit history.

## Recommended Employee Statuses

```
Draft / Pending
Active
Suspended
Terminated
Retired
Rehire Eligible
Not Rehire Eligible
```

## Recommended Contractor Statuses

```
Draft / Pending
Active
Pending Renewal
Expired
Suspended
Terminated
Do Not Renew
Inactive
```

## Exit Criteria

At the end of Phase 1, TeamCORE should be able to answer:

* Who is this team member?  
* Is this team member a person or organization?  
* Is this team member an employee, individual contractor, contractor organization, or subcontractor?  
* What is their current engagement?  
* Do they have prior engagements?  
* Where do they fit in the agency structure?  
* Who supervises or oversees them?  
* Is the relationship active, pending, suspended, expired, terminated, or inactive?

---

# Phase 2 — Documents, Compliance, and Activation Readiness

## Purpose

Establish documentation, compliance visibility, and readiness controls before deeper workflow automation is built.

## Included Domains

* Documents and Compliance  
* Engagement readiness  
* Contractor classification support

## Capabilities

### Document Requirements

* Define document types.  
* Define required documents by engagement type.  
* Attach documents to team members or engagements.  
* Track employee document requirements.  
* Track contractor document requirements.  
* Track contractor organization document requirements.  
* Track subcontractor document requirements where applicable.

## MVP Document Categories

MVP should support:

* employee employment agreement or offer letter  
* employee tax withholding forms  
* employee direct deposit form  
* employee handbook or policy acknowledgment  
* contractor agreement  
* contractor W-9 or tax form  
* contractor insurance or E\&O evidence  
* contractor classification/supporting documentation  
* contractor renewal agreement  
* certification evidence  
* identity verification or eligibility-to-work documentation  
* other agency-defined documents

### Document Status and Alerts

* Track missing documents.  
* Track submitted documents.  
* Track verified documents.  
* Track rejected documents.  
* Track expired documents.  
* Track expiring-soon documents.  
* Alert on missing, expired, and expiring-soon documents.  
* Support contractor agreement expiration alerts.  
* Support certification and insurance expiration alerts.

### Verification

* Allow document verification by authorized users only.  
    
* Verification roles should include:  
    
  * agency owner/admin  
  * HR/admin user  
  * compliance user


* Record verifier, verification date, status, and notes.

### Contractor Classification Support

* Track contractor entity type.  
* Track business legal name and DBA where applicable.  
* Track W-9 status.  
* Track agreement status.  
* Track insurance or E\&O status.  
* Track renewal status.  
* Track classification-supporting documentation.  
* Preserve classification support history.

## Exclusions

* Team member self-service document upload is excluded from MVP.  
* Legal classification decisions are outside TeamCORE scope.  
* Full legal/compliance advisory logic is outside TeamCORE scope.

## Exit Criteria

At the end of Phase 2, TeamCORE should be able to answer:

* What documents are required for this engagement?  
* Which documents are missing?  
* Which documents are expired or expiring soon?  
* Who verified a document and when?  
* Is this contractor properly documented for the current engagement?  
* Is this team member ready for activation from a documentation standpoint?

---

# Phase 3 — Team360 MVP and Operational Reporting

## Purpose

Make the core data usable through a unified profile and operational views.

## Included Domains / Capabilities

* Team360  
* Operational reporting  
* Alerts and missing items  
* Lightweight placeholders for later domains

## Team360 Functional MVP Panels

Team360 should include functional panels for:

* identity and contact summary  
* current engagement  
* engagement history  
* organization placement and reporting line  
* compensation summary  
* contractor charges and balance summary  
* time summary  
* leave summary  
* payroll or settlement history  
* documents and compliance status  
* alerts and missing items

Some of these panels may initially be empty or minimally populated until later phases are completed, but the Team360 layout and navigation model should exist early.

## Team360 Placeholder Panels

Team360 may include lightweight panels for later domains:

* benefits  
* training and certification  
* performance reviews  
* company assets

These may show “not yet configured,” limited manual summary data, or document/compliance references.

## Operational Reporting MVP

MVP operational reports/views should include:

* active team member list  
* employee roster  
* contractor roster  
* expiring contractor agreements  
* missing/expired documents  
* contractor balances owed  
* payroll run history  
* settlement run history  
* time summary by pay period  
* leave balances  
* org chart / reporting view

In this phase, some reports may be framework views or placeholder lists that become fully populated as later MVP phases are completed.

## Reporting Behavior

MVP reporting should focus on operational lists rather than advanced analytics.

Reports should support:

* filtering  
* sorting  
* status visibility  
* drill-through to Team360  
* CSV/XLSX export where practical

## Exit Criteria

At the end of Phase 3, users should have a useful Team360 profile and basic operational views for team members, engagements, document/compliance status, and organization placement.

---

# Phase 4 — Compensation, Contractor Charges, and Settlement Basics

## Purpose

Introduce the financial relationship between the agency and team members.

## Included Domains

* Compensation  
* Contractor Charges and Recoverables  
* Contractor settlement basics  
* Payroll and Settlement Runs, partial

## Capabilities

### Compensation

* Define salary compensation plans.  
* Define hourly compensation plans.  
* Define flat-rate commission plans.  
* Assign compensation plans to engagements.  
* Allow role/program/agency defaults with engagement-level overrides.  
* Track effective dates.  
* Store compensation history.  
* Support manual entry of gross sales.  
* Support manual entry of commissionable revenue.  
* Support imported gross sales and commissionable revenue.  
* Calculate flat-rate commission on commissionable revenue.  
* Track repayable draw balances.  
* Automatically recover repayable draws from future settlements.

### Contractor Charges and Recoverables

* Define contractor charge types.  
* Assess one-time onboarding fees.  
* Assess recurring monthly fees.  
* Assess annual renewal fees.  
* Track reimbursable expenses.  
* Track pass-through costs.  
* Track charge due/open/paid status.  
* Track partial payment or partial recovery.  
* Support settlement deduction.  
* Support invoice/direct-payment recovery.  
* Support fee waivers in MVP.  
* Record waiver reason, user, and timestamp.  
* Track contractor balances owed.

### Settlement Basics

* Create contractor settlement periods.  
* Show gross sales and commissionable revenue.  
* Calculate flat-rate commission.  
* Show draw recoveries.  
* Show contractor charge deductions.  
* Show direct-payment references where applicable.  
* Show net settlement amount.  
* Store settlement history.  
* Support manual settlement records.  
* Support CSV/XLSX settlement export if straightforward.

## Exclusions

* Tiered commission plans are deferred.  
* Commission splits are deferred.  
* Supplier/product-specific commission rules are deferred.  
* Booking-level commission integration is deferred.  
* Full AR aging is deferred.  
* Formal dispute workflows are deferred.  
* Formal write-off workflows are deferred.  
* Automated invoicing is deferred.

## Exit Criteria

At the end of Phase 4, TeamCORE should be able to show:

* what the agency owes a team member  
* what a contractor owes the agency  
* how contractor charges affect settlement  
* how repayable draws are recovered  
* basic compensation history  
* basic contractor charge history  
* contractor settlement history in Team360

---

# Phase 5 — Employee Time, Leave, and Payroll Input Workflows

## Purpose

Add employee workforce operations and employee payroll input preparation.

## Included Domains

* Time Tracking  
* Leave  
* Payroll Runs  
* Limited employee self-service

## Capabilities

### Time Tracking

* Employee-only time tracking.  
* Configure time tracking by engagement, position, or agency policy.  
* Web timeclock punch in/out.  
* Manual daily hour entry.  
* Weekly timesheet submission.  
* Supervisor-entered time.  
* Timesheet review.  
* Timesheet approval.  
* Pay-period time summaries.  
* Team360 time summary.

### Leave

* Employee-only leave tracking.  
* Agency-defined leave types.  
* PTO / vacation.  
* Sick / medical.  
* Bereavement.  
* Jury duty.  
* FMLA.  
* Unpaid leave.  
* Unlimited leave category.  
* Manual leave balances.  
* Manual balance adjustments.  
* Leave requests.  
* Configurable approval by leave type.  
* Auto-approval option by leave type.  
* Supervisor-entered leave.  
* Supervisor/payroll review before payroll summary.  
* Leave history.  
* Team360 leave summary.

### Payroll Runs

* Create employee payroll runs.  
* Gather compensation inputs.  
* Gather approved time.  
* Gather approved paid leave after review.  
* Support CSV export.  
* Support Excel/XLSX export.  
* Support CSV import.  
* Support Excel/XLSX import.  
* Support manual final result entry.  
* Store final result details:  
  * gross pay  
  * taxes  
  * employee deductions  
  * net pay  
  * payment date  
  * payment method  
  * external processor reference ID  
  * adjustment notes  
* Display payroll history in Team360.

### Limited Employee Self-Service

* Employee timeclock punch in/out.  
* Employee manual daily time entry.  
* Employee weekly timesheet submission.  
* Employee leave request submission.  
* Employee leave balance visibility.  
* Employee time/leave status visibility.

## Exclusions

* Contractor time submission is excluded from MVP.  
* Manual start/end time entry is deferred.  
* External time system import is deferred.  
* Automated leave accrual is deferred.  
* Tenure-based accrual rules are deferred.  
* Carryover rules are deferred.  
* Negative balance rules are deferred.  
* Advanced FMLA administration is deferred.  
* Payroll provider APIs are deferred.  
* Full employee self-service is deferred.  
* Contractor self-service is deferred.

## Exit Criteria

At the end of Phase 5, TeamCORE should support basic employee time, leave, and payroll-input workflows, including export/import or manual payroll result entry.

---

# Phase 6 — MVP Hardening, Permissions, Audit, and Release Readiness

## Purpose

Turn the foundational phases into a reliable first release.

## Capabilities

### Permissions and Roles

* Agency owner/admin access.  
* HR/admin access.  
* Compliance user access.  
* Payroll user access.  
* Supervisor/manager access.  
* Limited employee self-service access.  
* Permission-aware Team360 panels.  
* Restricted access to sensitive compensation, payroll, document, and compliance data.

### Formal MVP Approval Workflows

Formal approval workflows in MVP should include:

* timesheet approval  
* leave approval

Other control points should be permission-controlled admin actions or statuses rather than full approval workflows.

### Admin Actions / Status Controls

* Document verification.  
* Contractor fee waiver.  
* Payroll/settlement optional review status.  
* Engagement activation.  
* Compensation changes.  
* Payroll result import/manual entry.  
* Settlement result import/manual entry.

### Audit History

MVP audit history should include:

* lifecycle events for major records  
* field-level change history for sensitive records

Lifecycle events may include:

```
Created
Submitted
Approved
Rejected
Verified
Waived
Exported
Imported
Closed
Terminated
Expired
Suspended
Reopened
Corrected
```

Sensitive records should include:

* engagement status and dates  
* contractor classification fields  
* compensation plan assignments  
* pay rates  
* commission rates  
* draw balances  
* contractor charges  
* contractor waivers  
* payroll/settlement results  
* document verification status  
* document expiration dates  
* leave balances  
* timesheet approvals

### Import / Export Hardening

* Validate payroll export data.  
* Validate settlement export data.  
* Validate payroll import data.  
* Validate settlement import data.  
* Handle import errors.  
* Preserve imported file history.  
* Preserve manual correction history.  
* Support CSV/XLSX export where practical.

### Operational Reporting Completion

Ensure MVP reports are usable:

* active team member list  
* employee roster  
* contractor roster  
* expiring contractor agreements  
* missing/expired documents  
* contractor balances owed  
* payroll run history  
* settlement run history  
* time summary by pay period  
* leave balances  
* org chart / reporting view

### Release Readiness

* Admin configuration screens.  
* Required field validation.  
* Data migration/import tools, if needed.  
* Team360 usability cleanup.  
* Dashboard alerts.  
* User acceptance testing.  
* MVP documentation.

## Exit Criteria

MVP is ready when TeamCORE can manage the core lifecycle for employees and contractors from onboarding through active management, document/compliance readiness, compensation, contractor charges, time, leave, payroll/settlement visibility, Team360 review, and operational reporting.

---

# Later-Phase Roadmap

## Later Phase 7 — Benefits Expansion

## Purpose

Add benefits administration support after the core employee model is stable.

## Capabilities

* Benefit plans.  
* Eligibility rules.  
* Enrollment records.  
* Coverage tiers.  
* Dependent tiers.  
* Employer cost.  
* Team member deduction.  
* Payroll deduction instructions.  
* Benefit history in Team360.

## Why Later

Benefits can become complex quickly because of eligibility rules, enrollment windows, deduction timing, dependent tiers, and external carrier coordination.

---

## Later Phase 8 — Training and Certification Expansion

## Purpose

Track travel-industry readiness, training completion, certification status, and renewals.

## Capabilities

* Training catalog.  
* Required and optional training.  
* Role-based training assignments.  
* Completion tracking.  
* Certification records.  
* Expiration and renewal alerts.  
* Supporting evidence.  
* Team360 training panel.  
* Team member training self-service, if desired.

## Why Later

This is valuable, but it depends on stable team member, engagement, document, compliance, and Team360 foundations.

In MVP, certification evidence can be tracked through Documents and Compliance.

---

## Later Phase 9 — Performance Review Expansion

## Purpose

Support employee performance reviews and contractor performance/compliance reviews.

## Capabilities

* Review cycles.  
* Review templates.  
* Role-based metrics.  
* Supervisor reviews.  
* Contractor production or quality reviews.  
* Contractor compliance reviews.  
* Team member acknowledgments.  
* Review history in Team360.

## Why Later

This depends on stable organization structure, roles, reporting lines, engagement definitions, and performance expectations.

Employee performance reviews and contractor performance reviews should not necessarily use identical terminology or workflows.

---

## Later Phase 10 — Company Assets Expansion

## Purpose

Track assets issued to team members and related recovery obligations.

## Capabilities

* Asset catalog.  
* Asset assignment.  
* Issue and return tracking.  
* Lost/damaged asset status.  
* Replacement value.  
* Asset acknowledgment documents.  
* Contractor recoverable charges for lost assets.  
* Employee payroll deduction instructions where allowed.  
* Asset history in Team360.

## Why Later

Useful, but not foundational unless asset control becomes a first-release business priority.

---

## Later Phase 11 — Advanced Automation, Analytics, and Integrations

## Purpose

Expand TeamCORE from a structured workforce operations system into an integrated operational intelligence platform.

## Possible Capabilities

* Payroll provider integrations.  
* ADP/Paychex/QuickBooks/Gusto/Paylocity-specific mappings.  
* Payroll API integrations.  
* Commission source integrations.  
* Travel booking/accounting integrations.  
* Automated commission calculation.  
* Tiered commission rules.  
* Commission splits.  
* Supplier/product-specific commission rules.  
* Advanced draw accounting.  
* Automated contractor fee billing.  
* AR aging.  
* Dispute workflows.  
* Write-off workflows.  
* Payment portal integration.  
* Advanced compliance alerts.  
* Advanced org chart visualization.  
* Workforce analytics.  
* Turnover and retention reporting.  
* Contractor productivity dashboards.  
* Broader employee self-service.  
* Contractor self-service.  
* Team member document uploads.  
* Supervisor work queues.

---

# MVP Scope Matrix

| Domain / Capability | MVP Scope | Deferred Scope |
| :---- | :---- | :---- |
| Organization | Departments, locations, teams, reporting lines | Advanced org visualization |
| Team Member / Party | People, organizations, contractors, contractor orgs, subcontractor support | Advanced relationship mapping |
| Engagement | Employee/contractor engagements, statuses, history | Complex amendments workflow |
| Documents and Compliance | Required docs, verification, missing/expired alerts, classification support | Self-service upload, legal advisory logic |
| Team360 | Functional MVP panels plus later-domain placeholders | Advanced workflow shortcuts |
| Compensation | Salary/hourly, flat commission, manual/imported revenue, draw recovery | Tiers, splits, overrides, supplier rules |
| Contractor Charges | Fees, recoverables, direct payment, settlement deduction, waiver | AR aging, disputes, write-offs, automated invoicing |
| Payroll and Settlement | CSV/XLSX export/import, manual result entry, run history | Vendor APIs, automated reconciliation |
| Time Tracking | Employee-only timeclock, daily hours, weekly timesheets, supervisor entry | Contractor time, external import, scheduling |
| Leave | Employee-only, manual balances, configurable approvals | Automated accrual, carryover, advanced FMLA |
| Self-Service | Employee time and leave only | Contractor portal, document upload, profile updates |
| Approvals | Timesheet and leave approvals | Formal payroll, settlement, fee, engagement approval workflows |
| Audit | Lifecycle events and sensitive field-level history | Full audit trail for every record |
| Reporting | Operational lists and views | Advanced analytics and dashboards |

---

# Revised Initial Epic Backlog

```
Epic: Product framing and glossary
Epic: Organization foundation
Epic: Team Member / Party foundation
Epic: Engagement lifecycle
Epic: Employee and contractor status models
Epic: Subcontractor relationship support
Epic: Document type and requirement configuration
Epic: Document upload and verification
Epic: Missing and expiration document alerts
Epic: Contractor classification support
Epic: Team360 MVP shell
Epic: Team360 engagement and compliance panels
Epic: Operational reporting framework
Epic: Compensation plan assignment
Epic: Manual/imported revenue inputs
Epic: Flat-rate commission calculation
Epic: Repayable draw recovery
Epic: Contractor charge tracking
Epic: Contractor charge waiver
Epic: Contractor settlement shell
Epic: Payroll and settlement CSV/XLSX export
Epic: Manual payroll/settlement result entry
Epic: Employee time tracking MVP
Epic: Employee timesheet approval
Epic: Employee leave request MVP
Epic: Leave approval by type
Epic: Payroll input workflow
Epic: Limited employee self-service
Epic: Permission-aware Team360
Epic: MVP audit history
Epic: MVP release hardening
```

---

# Updated Roadmap Decision Log

```
## Roadmap Decision Log

1. TeamCORE will support multiple active engagements for a team member, but this is treated as an exception workflow.
2. Contractor organizations may have subcontractors.
3. Subcontractors may be related contacts or first-class team members depending on agency configuration and operational need.
4. A subcontractor should become a first-class team member when access, training, documents, compliance, commission tracking, or Team360 visibility is required.
5. Employee and contractor status models will remain distinct.
6. “On Leave” should generally be derived from the Leave domain rather than treated as a primary employee status.
7. If a person moves between contractor and employee status, the preferred model is the same Party with a separate Engagement.
8. Closed engagements may be corrected by authorized admins in MVP, but sensitive changes should be logged.
9. TeamCORE will support manually entered or imported gross sales and commissionable revenue.
10. MVP commission calculation will support simple flat-rate commission on commissionable revenue.
11. Repayable draws will be automatically recovered from future commission settlements.
12. Commission plans will generally be assigned at the Engagement level, with possible role/program defaults and overrides.
13. Contractor charges may be recovered through settlement deduction or invoice/direct payment.
14. MVP contractor charges will use basic due/open/paid status, not full AR aging.
15. Fee waivers will be supported in MVP; disputes and write-offs will be deferred.
16. MVP payroll/settlement integration will use generic CSV/XLSX export and import.
17. MVP will support manual entry of payroll/settlement results.
18. Contractor settlement should remain distinct from employee payroll.
19. TeamCORE will store gross pay, taxes, employee deductions, contractor charge deductions, draw recoveries, net pay, payment date, payment method, external reference ID, and adjustment notes.
20. Documents and Compliance will be an MVP domain.
21. MVP will support all listed required document categories for employees and contractors.
22. MVP will include missing-document and expiration alerts.
23. Document verification will be limited to owner/admin, HR/admin, and compliance users.
24. Contractor classification support will be included in MVP.
25. MVP document upload will be admin-only.
26. Contractors will not submit time in MVP.
27. Employee time tracking will be configured by engagement or position.
28. MVP time tracking will support timeclock, manual daily hours, weekly timesheets, and supervisor-entered time.
29. MVP leave balances will be manually entered or adjusted.
30. Leave approval behavior may vary by leave type, including auto-approval.
31. MVP will support agency-defined leave types, including PTO, sick/medical, bereavement, jury duty, FMLA, unpaid leave, and unlimited leave.
32. Approved paid leave will flow to payroll/time summaries only after supervisor or payroll review.
33. Team360 will be part of MVP.
34. Team360 will include functional panels for MVP domains and lightweight placeholders for later domains.
35. MVP self-service will focus on employee time and leave.
36. MVP formal approvals will include timesheet approval and leave approval.
37. MVP audit history will include lifecycle events and field-level change history for sensitive records.
38. MVP reporting will include operational views for rosters, expiring agreements, missing/expired documents, balances, payroll/settlement history, time summaries, leave balances, and org/reporting views.
```

---

# Remaining Open Decisions

| Area | Open Decision | Recommended Default |
| :---- | :---- | :---- |
| Subcontractors | Full team members vs related contacts | Agency-configurable; first-class when access, compliance, training, commission, or Team360 visibility is needed |
| Contractor-to-employee movement | Same party with new engagement vs separate profile | Same Party, separate Engagement |
| Closed engagement editing | Admin editable vs correction-only | Admin editable with audit in MVP |
| Commission plan assignment | Exact ownership | Engagement-level assignment with role/program defaults and overrides |
| Contractor payments | Manual record vs exportable settlement | Manual record plus CSV/XLSX settlement export if straightforward |
| Payroll/settlement approval | None vs configurable | Optional/configurable status, not full approval workflow |
| Team360 panels | All vs functional/placeholder split | All visible; MVP domains functional, later domains placeholders |
| Self-service | Limited vs broad | Limited employee time/leave self-service in MVP |

---

# Main Changes from the Preliminary Roadmap

| Preliminary Roadmap | Revised Roadmap |
| :---- | :---- |
| Phase 2 combined Team360 and Documents/Compliance | Splits Documents/Compliance first, then Team360/reporting |
| Team360 “starts shallow” | Team360 is broad in MVP, with functional MVP panels and placeholders for later domains |
| Contractor Charges included write-off status | MVP supports waivers; disputes/write-offs deferred |
| Time Tracking included broader time entry possibilities | MVP is employee-only; no contractor time submission |
| Leave had general employee/contractor language | MVP leave is employee-only |
| Payroll/Settlement was general export/import | MVP explicitly supports CSV/XLSX plus manual result entry |
| Approval workflows not fully clarified | Formal MVP approvals limited to timesheets and leave |
| Audit history was generic | MVP requires lifecycle events plus sensitive field-level history |
| Reporting was part of hardening | Operational reporting gets its own Phase 3 emphasis |

This version is now better aligned with the decisions you made during the roadmap interview.  