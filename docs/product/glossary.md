# TeamCORE Glossary

## Purpose

This glossary establishes shared terminology for the TeamCORE roadmap. It is intended to keep product planning, issue writing, implementation, documentation, and future user-facing language consistent across the project.

TeamCORE supports both employee and contractor workforce operations. Several terms intentionally distinguish between identity records, workforce relationships, organization structure, compliance readiness, payroll-oriented workflows, and contractor settlement workflows.

---

## Core Product Terms

### TeamCORE

TeamCORE is a workforce operations platform for managing team members, employee and contractor engagements, compliance documents, compensation, contractor settlements, time, leave, payroll inputs, Team360 profiles, reporting, permissions, and audit-ready operational workflows.

---

### MVP

The **MVP** is the minimum viable product scope required for TeamCORE to support its initial operational use case.

The MVP should include the core records, workflows, permissions, reporting, and audit history needed to operate safely, while deferring more advanced automation, integrations, analytics, and self-service features until later phases.

---

### MVP Hardening

**MVP Hardening** is the final stabilization work needed before release.

Hardening may include validation improvements, permission review, audit coverage, import/export error handling, user acceptance testing, documentation, and cleanup of incomplete or inconsistent workflows.

---

### Release Readiness

**Release Readiness** means the product is stable enough for its intended MVP use.

Release readiness includes confirmed scope, tested workflows, acceptable validation coverage, permission checks, audit behavior, import/export reliability, documentation, and resolved blocking issues.

---

## Identity and Workforce Terms

### Party

A **Party** is a person or organization that TeamCORE needs to identify and relate to business records.

A party may be:

- An individual person
- A contractor organization
- A vendor-like organization
- Another organization relevant to workforce operations

A party is an identity record. It does not, by itself, determine whether someone is an employee, contractor, subcontractor, or active team member.

**Schema and rules (Phase 1 / TC-02):** [`party-team-member.md`](../domain/party-team-member.md).

---

A **Team Member** is a party that participates in the agency’s workforce operations through one or more engagements.

A team member may be an employee, contractor, or another workforce participant depending on the engagement type and project configuration.

A team member is not the same thing as a party. The party identifies the person or organization; the team member represents that party’s workforce relationship to TeamCORE.

---

### Employee

An **Employee** is a team member with an employment engagement.

Employees may participate in employee-specific workflows such as time tracking, leave requests, timesheet approval, and payroll input workflows.

Employees are distinct from contractors because they are handled through payroll-oriented workflows rather than contractor settlement workflows.

---

### Contractor

A **Contractor** is a team member with a contractor engagement.

Contractors may participate in contractor-specific workflows such as compliance tracking, compensation plan assignment, commission calculation, contractor charge tracking, draw recovery, and contractor settlement.

Contractors are distinct from employees because they are handled through settlement-oriented workflows rather than employee payroll workflows.

---

### Contractor Organization

A **Contractor Organization** is an organization party that provides contractor services or is associated with one or more contractor engagements.

A contractor organization may represent a business entity, agency, firm, or other organization through which contractor work is performed.

A contractor organization is not automatically the same thing as an individual contractor. TeamCORE should be able to distinguish the organization from the people related to it.

---

### Subcontractor

A **Subcontractor** is a person or organization related to a contractor or contractor organization that performs work under that contractor relationship.

Subcontractors may be modeled as related contacts or as first-class team members depending on configuration and implementation decisions.

Subcontractor support should clarify whether the subcontractor needs their own engagement, document requirements, compliance tracking, Team360 visibility, or settlement-related records.

---

## Organization Structure Terms

### Agency

An **Agency** is the primary operating organization using TeamCORE and, in Phase 1 schema, the top-level **`Agency`** model (`agencies` table). All departments, locations, and teams in TC-01 belong to one agency.

The agency is the business context in which team members, engagements, documents, compensation, payroll inputs, contractor settlements, and reports are managed.

---

### Organization

**Organization** refers to the agency’s **internal structure**: departments, locations, teams, placements, supervision, and authority relationships.

In product language “organization” can also mean a **structured business entity** elsewhere (for example a **Contractor Organization** as a party). When precision is needed:

- Use **`Agency`** for the TeamCORE tenant / operating context (**OD-011**, **ADR-0001**).
- Use **Department**, **Location**, **Team** for internal structure **models**.
- Use **Contractor Organization** (or **organization party**) when the party is not the internal structure.

TC-01 does **not** use a catch-all Active Record model named `Organization` for internal structure. Details: [`domain/organization.md`](../domain/organization.md).

---

### Department

A **Department** is an internal organizational grouping within the agency.

Departments may be used for reporting, management structure, approvals, permissions, team member assignment, or operational filtering.

Field list, lifecycle, placement/reporting hooks, and **code**/naming conventions: **[`organization.md` § Department (TC-01.02)](../domain/organization.md#department-tc-0102)**.

---

### Location

A **Location** is a physical or operational place where team members may work or be assigned.

Locations may support reporting, team assignment, time tracking, document rules, or operational visibility.

Field list, **`location_type`** vocabulary, address/timezone posture, remote/virtual semantics, placement/reporting hooks: **[`organization.md` § Location (TC-01.03)](../domain/organization.md#location-tc-0103)**.

---

### Team

A **Team** is an internal group of team members organized for management, reporting, workflow, or operational responsibility.

A team may belong to a department, location, or other organizational structure depending on implementation decisions.

Field list, **department**/location FKs (optional), deferred **team lead** posture (engagement supervisor instead), placement + **Team360** context contract: **[`organization.md` § Team (TC-01.04)](../domain/organization.md#team-tc-0104)**.

---

### Reporting Line

A **Reporting Line** describes a supervisory or management relationship between team members or organizational roles.

Reporting lines may support approvals, manager visibility, operational reporting, escalation, and permission decisions.

**TC-01 posture:** reporting lines are **anchored on Engagements** (not Team Member alone); planned persistence **`EngagementSupervisionAssignment`** (**TC-03**). Full spec: **[`organization.md` § Reporting line (TC-01.05)](../domain/organization.md#reporting-line-tc-0105)**.

---

### Authority Structure

An **Authority Structure** defines who is allowed to approve, verify, waive, review, or act on specific workflows or records.

Authority structure may be based on role, reporting line, department, location, team, permission, or configured business rule.

---

## Engagement and Lifecycle Terms

### Engagement

An **Engagement** is the formal relationship between a team member and the agency for a defined workforce purpose.

**TC-03 domain spec:** [`../domain/engagement.md`](../domain/engagement.md).  
**TC-04 status semantics** (meanings by `relationship_type`, workflow matrices, audit/reporting hooks): [`../domain/engagement-status.md`](../domain/engagement-status.md).

An engagement determines how the team member participates in TeamCORE workflows. It may identify whether the relationship is employment-based, contractor-based, active, inactive, pending, terminated, or otherwise status-controlled.

A person or organization may potentially have more than one engagement over time.

---

### Employment Engagement

An **Employment Engagement** is an engagement that represents an employee relationship.

Employment engagements support employee-oriented workflows, including time tracking, leave requests, payroll input, employee status management, and employee-specific Team360 panels.

---

### Contractor Engagement

A **Contractor Engagement** is an engagement that represents a contractor relationship.

Contractor engagements support contractor-oriented workflows, including compliance readiness, compensation plans, commission calculation, contractor charges, draw recovery, settlement records, and contractor-specific Team360 panels.

---

### Lifecycle

A **Lifecycle** is the sequence of states or events a record passes through from creation to completion, termination, expiration, or closure.

Lifecycle behavior may apply to engagements, statuses, documents, approvals, timesheets, leave requests, contractor charges, settlements, payroll inputs, imports, exports, and audit records.

---

### Status

A **Status** is a controlled state that describes where a record stands in its lifecycle.

Statuses may apply to team members, engagements, documents, contractor charges, settlements, payroll inputs, approvals, or other workflow records.

Examples may include:

- Pending
- Active
- Inactive
- Suspended
- Terminated
- Missing
- Verified
- Expired
- Waived
- Approved
- Rejected
- Completed

Status rules should be specific to the record type. Employee and contractor statuses should remain distinct where their workflows differ.

---

## Compliance and Document Terms

### Activation Readiness

**Activation Readiness** describes whether a team member or engagement has satisfied the minimum requirements needed to become active or operationally available.

Activation readiness may depend on:

- Required documents
- Document verification
- Expiration status
- Engagement status
- Contractor classification support
- Internal approval or review requirements

Activation readiness does not mean legal compliance has been determined. It means TeamCORE has enough configured requirements satisfied to allow the relevant workflow to proceed.

---

### Document Requirement

A **Document Requirement** is a configured rule stating that a specific type of document is required for a party, team member, engagement, contractor classification, role, or other workforce context.

Examples may include:

- Identification document
- Employment eligibility document
- Contractor agreement
- Insurance certificate
- License
- Certification
- Tax form
- Policy acknowledgment

Document requirements may vary by engagement type, contractor type, location, role, or other configuration.

---

### Verification

**Verification** is the process of reviewing and confirming that a submitted document or record satisfies a configured requirement.

Verification may include confirming that:

- The correct document type was provided
- The document belongs to the correct party or engagement
- The document has not expired
- The document was reviewed by an authorized user
- The verification date and verifier are recorded

Verification is an operational review action. It should be permission-controlled and audit-tracked.

---

### Compliance

**Compliance** refers to TeamCORE’s tracking of required records, documents, statuses, expirations, and readiness conditions.

In the MVP, compliance support means tracking configured requirements and surfacing missing, expired, or expiring items. It does not mean TeamCORE is making legal determinations about worker classification, employment law, payroll law, tax law, or contractor status.

---

### Document Alert

A **Document Alert** is a notification, flag, or report item showing that a document requirement needs attention.

Document alerts may indicate that a required document is missing, expired, expiring soon, unverified, rejected, or otherwise not ready.

---

### Missing Document

A **Missing Document** is a required document that has not been provided or attached to the relevant party, team member, engagement, or compliance context.

Missing documents may prevent activation readiness depending on configured rules.

---

### Expired Document

An **Expired Document** is a document that is no longer valid because its expiration date has passed.

Expired documents may affect compliance status, activation readiness, or operational eligibility.

---

### Expiring-Soon Document

An **Expiring-Soon Document** is a document that is still valid but approaching its expiration date.

The definition of “soon” should be configurable or otherwise defined by product rules.

---

### Contractor Classification Support

**Contractor Classification Support** is the tracking of documents, records, and workflow information that support contractor classification review.

This does not mean TeamCORE makes final legal determinations about whether a worker is properly classified as a contractor. It means TeamCORE stores and surfaces configured supporting records.

---

## Team360 and Reporting Terms

### Team360

**Team360** is the unified profile view for a team member or workforce participant.

Team360 brings together relevant information such as:

- Identity
- Contact details
- Organization placement
- Engagement history
- Status
- Compliance readiness
- Required documents
- Compensation summary
- Contractor charges
- Settlement history
- Time and leave summaries
- Payroll input or result summaries
- Audit history

Team360 is a viewing and navigation surface. It should display authoritative information from underlying domain records rather than becoming the source of truth for every workflow.

---

### Permission-Aware Team360

**Permission-Aware Team360** is the version of Team360 that restricts panels, fields, actions, and sensitive data based on the viewer’s permissions.

This ensures users only see the employee, contractor, compensation, payroll, settlement, compliance, and audit information they are authorized to access.

---

### Team360 Panel

A **Team360 Panel** is a section of the Team360 profile dedicated to a specific area of information.

Examples may include:

- Identity panel
- Engagement panel
- Compliance panel
- Documents panel
- Compensation panel
- Contractor charges panel
- Settlement panel
- Time and leave panel
- Payroll panel
- Audit history panel

---

### Operational Reporting

**Operational Reporting** is the set of filterable lists, summaries, and views used to monitor current workforce activity, exceptions, readiness, and workflow status.

Operational reporting should support drill-through to the underlying Team360 profile or source record when more detail is needed.

---

### Operational List

An **Operational List** is a report-like view of records requiring review, action, or monitoring.

Examples may include lists of team members, active engagements, missing documents, expiring documents, pending timesheets, leave requests, contractor charges, settlements, or payroll inputs.

---

### Drill-Through

**Drill-Through** is the ability to navigate from a summary, report, list, or dashboard item to the underlying detailed record.

For example, a missing document alert may drill through to the Team360 compliance panel or the document requirement record.

---

## Compensation and Revenue Terms

### Compensation Plan

A **Compensation Plan** defines how a team member or engagement is compensated.

Compensation plans may include:

- Salary
- Hourly rate
- Flat-rate commission
- Contractor commission rate
- Draw arrangement
- Other configured compensation rules

A compensation plan provides the basis for payroll input, commission calculation, or contractor settlement, depending on the engagement type.

---

### Gross Sales

**Gross Sales** is the total sales amount before commission eligibility rules, exclusions, adjustments, or other reductions are applied.

Gross sales may be entered manually or imported from an external source.

---

### Revenue Input

A **Revenue Input** is manually entered or imported revenue data used by TeamCORE for compensation, commission, reporting, or settlement workflows.

Revenue inputs may include gross sales, commissionable revenue, adjustments, or other revenue-related values.

---

### Commissionable Revenue

**Commissionable Revenue** is the portion of gross revenue that is eligible for commission calculation.

Commissionable revenue may be manually entered or imported. It may differ from gross sales if exclusions, adjustments, non-commissionable items, chargebacks, or other business rules apply.

For MVP purposes, commissionable revenue supports flat-rate commission calculation.

---

### Flat-Rate Commission

A **Flat-Rate Commission** is a commission calculated by applying a fixed percentage or rate to commissionable revenue.

For MVP purposes, flat-rate commission is the baseline commission calculation model.

---

## Contractor Charge and Settlement Terms

### Contractor Charge

A **Contractor Charge** is an amount owed by or recoverable from a contractor.

Examples may include:

- Fees
- Recoverable costs
- Advances
- Repayable draws
- Adjustments
- Other contractor-related balances

Contractor charges may be open, recovered, waived, adjusted, or closed depending on workflow rules.

---

### Repayable Draw

A **Repayable Draw** is an advance or draw paid to a contractor that is expected to be recovered from future settlement amounts.

Repayable draws should be tracked so outstanding balances can be recovered, adjusted, waived, or reported.

---

### Draw Recovery

**Draw Recovery** is the process of applying future contractor settlement amounts toward an outstanding repayable draw balance.

Draw recovery reduces the amount payable to the contractor until the recoverable balance is satisfied or otherwise resolved.

---

### Waiver

A **Waiver** is an authorized action that forgives, removes, or suppresses a contractor charge, recovery, requirement, or other obligation.

Waivers should be permission-controlled and audit-tracked.

---

### Contractor Settlement

A **Contractor Settlement** is the workflow or record used to calculate and record amounts payable to or recoverable from a contractor.

A contractor settlement may include:

- Commissionable revenue
- Commission calculation
- Contractor charges
- Draw recovery
- Adjustments
- Final settlement result
- Export or import records

Contractor settlement is distinct from employee payroll. It supports contractor payment/recovery workflows rather than payroll processing.

---

### Settlement Result

A **Settlement Result** is the final outcome of a contractor settlement workflow.

Settlement results may include:

- Final payable amount
- Recovered charges
- Waived charges
- Draw recovery
- Adjustments
- Export/import reference
- Settlement date
- Settlement status

Settlement results are distinct from payroll results because they apply to contractor settlement workflows, not employee payroll workflows.

---

### Settlement Export

A **Settlement Export** is an output file or data package containing contractor settlement information for use outside TeamCORE.

Settlement exports may use generic formats such as CSV or XLSX in the MVP.

---

### Settlement Import

A **Settlement Import** is an input file or data load that records settlement results, corrections, statuses, or externally processed settlement information back into TeamCORE.

Settlement imports should include validation and error handling before imported values become authoritative.

---

## Employee Time, Leave, and Payroll Terms

### Time Tracking

**Time Tracking** is the employee-oriented workflow for recording time worked.

In the MVP, time tracking is employee-only unless a later decision expands it to other worker types.

---

### Timeclock

A **Timeclock** is a self-service or administrative workflow used to record clock-in and clock-out activity.

Timeclock records may feed timesheets, payroll inputs, reporting, and Team360 summaries.

---

### Timesheet

A **Timesheet** is a record of employee time for a defined period.

Timesheets may include clocked time, manually entered time, adjustments, submission status, approval status, and payroll input readiness.

---

### Timesheet Approval

**Timesheet Approval** is the review and approval workflow confirming that an employee’s timesheet is ready for payroll input.

Timesheet approval is a formal MVP approval workflow and should be permission-controlled and audit-tracked.

---

### Leave Request

A **Leave Request** is an employee request to use leave time for a specific date, date range, or duration.

Leave requests may require approval depending on leave type and configuration.

---

### Leave Type

A **Leave Type** is a configured category of leave.

Examples may include vacation, sick, personal, unpaid, holiday, bereavement, or other agency-defined categories.

Leave type may determine whether approval is required, whether the request can be auto-approved, and how balances are affected.

---

### Leave Balance

A **Leave Balance** is the amount of leave available, used, pending, or manually recorded for an employee.

In the MVP, leave balances may be manual or limited in scope unless more advanced accrual rules are separately designed.

---

### Payroll Input

**Payroll Input** is the data TeamCORE prepares or exports for payroll processing.

Payroll input may include:

- Employee compensation data
- Approved time
- Reviewed leave
- Deductions or adjustments
- Other payroll-relevant values

Payroll input does not mean TeamCORE is the payroll processor. In the MVP, TeamCORE prepares, imports, exports, or records payroll-related data for use with an external or manual payroll process.

---

### Payroll Result

A **Payroll Result** is the final payroll outcome recorded back into TeamCORE after payroll processing.

Payroll results may be imported or manually entered. They may include payroll run references, final paid amounts, dates, status, or other summary data needed for Team360 and reporting.

Payroll results are distinct from payroll inputs. Inputs are prepared before processing; results reflect what happened after processing.

---

### Payroll Run

A **Payroll Run** is a payroll processing cycle for a defined period, group, or batch of employees.

In TeamCORE MVP terminology, a payroll run may be represented through payroll inputs, exports, imports, and recorded results, but TeamCORE is not assumed to be the payroll processor.

---

### Payroll Export

A **Payroll Export** is an output file or data package containing payroll input information for processing outside TeamCORE.

Payroll exports may use generic formats such as CSV or XLSX in the MVP.

---

### Payroll Import

A **Payroll Import** is an input file or data load that records payroll results, statuses, or externally processed payroll information back into TeamCORE.

Payroll imports should include validation and error handling before imported values become authoritative.

---

### Manual Result Entry

**Manual Result Entry** is the workflow for recording payroll or settlement results directly in TeamCORE without using a structured import file.

Manual result entry is an MVP fallback when export/import automation is not available or not appropriate.

---

## Import, Export, and Validation Terms

### Import

An **Import** is the process of loading externally prepared data into TeamCORE.

Imports may apply to revenue inputs, payroll results, settlement results, or other configured data. Imports should be validated and should produce clear error messages when records cannot be accepted.

---

### Export

An **Export** is the process of producing a file or data package from TeamCORE for use in another system or manual workflow.

Exports may apply to payroll inputs, settlement records, reports, or other operational data.

---

### Import/Export

**Import/Export** refers collectively to workflows that move data into or out of TeamCORE.

In the MVP, import/export may use generic CSV or XLSX files rather than direct integrations.

---

### CSV/XLSX File

A **CSV/XLSX File** is a generic spreadsheet-style file used for import or export.

CSV and XLSX files may be used for payroll inputs, settlement data, revenue inputs, results, or operational reporting.

---

### Validation

**Validation** is the process of checking whether data satisfies required rules before it is saved, imported, exported, approved, verified, or processed.

Validation may check required fields, valid statuses, date ranges, file structure, permission rules, duplicate records, referential relationships, or business rules.

---

### Error Handling

**Error Handling** is the process of detecting, reporting, and safely managing invalid or failed workflow conditions.

Import/export workflows should provide clear error handling so users can understand what failed, why it failed, and what needs to be corrected.

---

## Approval, Permission, and Self-Service Terms

### Approval

An **Approval** is an authorized decision allowing a workflow, record, or exception to proceed.

Approvals may apply to timesheets, leave requests, waivers, document exceptions, contractor charges, or other controlled actions.

Approvals should record who approved the action, when it was approved, and what was approved.

---

### Permission

A **Permission** is an authorization rule controlling whether a user can view, create, update, approve, verify, waive, export, import, or otherwise act on TeamCORE records.

Permissions may control:

- Team360 panel visibility
- Document verification
- Contractor charge waivers
- Timesheet approval
- Leave approval
- Payroll input access
- Settlement access
- Audit history visibility
- Import/export actions

Permission rules should protect sensitive employee, contractor, compensation, payroll, settlement, and compliance information.

---

### Authorized Role

An **Authorized Role** is a role or permission grouping allowed to perform a specific action.

Examples may include roles authorized to verify documents, approve timesheets, approve leave, waive contractor charges, access payroll inputs, or view settlement data.

---

### Self-Service

**Self-Service** refers to limited actions a team member may perform directly without administrative data entry.

In the MVP, self-service is limited and primarily employee-focused. It may include:

- Clocking in or out
- Entering time
- Submitting timesheets
- Requesting leave
- Viewing limited profile or workflow information

Self-service does not imply full employee, contractor, or manager portal functionality unless separately defined.

---

## Audit and Governance Terms

### Audit History

**Audit History** is the recorded history of important changes, decisions, approvals, verifications, waivers, imports, exports, and lifecycle events.

Audit history should help answer:

- What changed?
- Who changed it?
- When did it change?
- Why did it change, if a reason was required?
- What record or workflow did the change affect?

Audit history is especially important for sensitive records involving permissions, compliance, documents, compensation, contractor charges, payroll inputs, settlements, approvals, and status changes.

---

### Audit Event

An **Audit Event** is a specific recorded occurrence in audit history.

Examples may include document verification, status change, engagement activation, timesheet approval, leave approval, contractor charge waiver, payroll import, settlement export, or permission-sensitive record update.

---

### Roadmap Decision

A **Roadmap Decision** is a documented product or implementation decision that affects TeamCORE’s planned scope, sequencing, terminology, or architecture.

Roadmap decisions should be recorded so the project does not repeatedly reopen settled questions.

---

### Open Decision

An **Open Decision** is an unresolved product, domain, workflow, or architecture question.

Open decisions should identify their impact, owner, current status, and whether they block a later phase.

---

### User Acceptance Testing

**User Acceptance Testing**, or **UAT**, is the process of confirming that TeamCORE meets its intended operational requirements from the user’s perspective.

UAT is part of release readiness and MVP hardening.

---

## Boundary Notes

### Party vs Team Member

A party is the identity record for a person or organization.

A team member is a workforce participant derived from or linked to a party.

A party may exist before becoming a team member. A team member should not exist without an underlying party.

---

### Organization vs Contractor Organization

An organization may describe the agency’s internal structure or an organization-type party.

A contractor organization is specifically an organization party associated with contractor services or contractor engagements.

Use the more specific term whenever possible.

---

### Employee vs Contractor

Employees and contractors are both team members, but they participate in different workflows.

Employees generally use payroll, time, leave, and employee status workflows.

Contractors generally use compliance, compensation, commission, contractor charge, draw recovery, and settlement workflows.

---

### Engagement vs Status

An engagement defines the relationship.

A status describes the current lifecycle state of that relationship or record.

For example, a contractor engagement may have a status of pending, active, suspended, or ended.

---

### Verification vs Approval

Verification confirms that a document or record satisfies a requirement.

Approval authorizes a workflow, exception, request, or action to proceed.

A document may be verified, while a timesheet, leave request, waiver, or exception may be approved.

---

### Payroll vs Settlement

Payroll is the employee-oriented workflow for preparing, exporting, importing, or recording payroll-related data.

Settlement is the contractor-oriented workflow for calculating and recording contractor payments, recoveries, charges, draws, and final settlement outcomes.

TeamCORE may support payroll inputs and payroll results without becoming a payroll processor.

---

### Gross Sales vs Commissionable Revenue

Gross sales is the total sales amount before commission rules are applied.

Commissionable revenue is the portion of revenue eligible for commission calculation.

Commissionable revenue may equal gross sales, but it may also differ because of exclusions, adjustments, chargebacks, or other rules.

---

### Compliance vs Legal Determination

TeamCORE tracks configured compliance requirements, document readiness, verification, missing items, expirations, and classification-supporting records.

TeamCORE should not be described as making final legal determinations about employment classification, tax treatment, labor law compliance, or contractor legality unless that capability is explicitly designed and approved in a later phase.

---

### Team360 vs Source of Truth

Team360 is a unified profile and navigation surface.

Team360 should display authoritative information from underlying domain records. It should not become the source of truth for every workflow.

---

## Glossary Maintenance Rules

- Add new terms when a roadmap item introduces a new domain concept.
- Prefer concise operational definitions over legalistic definitions.
- Keep employee and contractor terms distinct when workflows differ.
- Avoid using payroll language for contractor settlement workflows.
- Avoid using settlement language for employee payroll workflows.
- Update this glossary when a later ADR changes terminology.
- Link major terminology changes to the roadmap decision log or an ADR.
- Keep Phase 1 identity, organization, and engagement terms stable before implementation begins.