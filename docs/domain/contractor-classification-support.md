# Contractor classification support (TC-09)

**Epic:** Contractor classification support — a **contractor-focused compliance lens** over **TC-06** ([`documents-compliance.md`](documents-compliance.md)), **TC-07** ([`document-alerts.md`](document-alerts.md)), and **TC-08** ([`document-verification.md`](document-verification.md)).

**Cross-links:** [`documents-compliance.md`](documents-compliance.md) (evaluator, requirements); [`engagement.md`](engagement.md) (workflow spine, `relationship_type`, `renewal_on`); [`subcontractor-relationships.md`](subcontractor-relationships.md); [`party-team-member.md`](party-team-member.md); [`domain-map.md`](../product/domain-map.md); decisions [`open-decisions.md`](../product/open-decisions.md) (**TC-09-D01–D08**).

---

## Boundary

**Contractor classification support** means TeamCORE tracks **configured** records and evidence that support contractor administration (tax forms, agreements, insurance evidence where configured, renewals, certifications, classification-supporting documentation).

TeamCORE **does not**:

- Determine legal worker classification or compliance with labor/tax law
- Provide legal advice or misclassification risk scoring
- Recommend employee vs contractor conversion
- Override agency or legal review

**Compliance support is not legal determination.**

---

## Applicability correction (demo and configuration)

TC-09 corrects configuration where contractor classification-support requirements were **broader than the product rule**. Requirements meant only for contractor-class engagements MUST use explicit `DocumentRequirement.relationship_type` values (`individual_contractor`, `contractor_organization`, `subcontractor` as configured), **not** `"any"`, unless the document type is **intentionally universal** (for example an organization-wide policy acknowledgment).

Contractor-only tax/W-9-style requirements **must not** use `relationship_type: any` unless explicitly universal — see **TC-09-D08**.

---

## Questions TC-09 answers vs excludes

**Answers (via configured requirements + evaluator output):**

- What classification-supporting records exist for this contractor engagement?
- Which requirements are missing, rejected, expired, or pending verification?
- What profile facts help identify the contractor entity?
- Is the engagement documentation-ready from a **configured** requirements standpoint?

**Does not answer:**

- Whether a person is legally an independent contractor
- Whether an agency is compliant with labor/tax law
- Whether a contractor should become an employee

---

## Profile and entity source map

| Support item | Source |
| --- | --- |
| Contractor class vs employee | `Engagement.relationship_type` |
| Individual contractor identity | `Party.party_type = person` + `PersonProfile` |
| Contractor organization identity | `Party.party_type = organization` + `OrganizationProfile` |
| Subcontractor promoted | `Engagement.relationship_type = subcontractor` |
| Related-only subcontractor (no engagement) | `PartyRelationship` only; **no** engagement-driven readiness |
| Business legal name | `OrganizationProfile.legal_name` |
| DBA / trade name | `OrganizationProfile.trade_name` |
| Entity kind | `OrganizationProfile.organization_kind` |
| Engagement lifecycle | `Engagement.status`, business dates |
| Renewal planning | `Engagement.renewal_on` (informational); document expirations drive readiness/alerts |

TC-09 does **not** add contractor classification fields on `Party` unless a future decision requires them. Workflow applicability stays on **Engagement**.

---

## Document configuration: category + code

Use **`DocumentType.category`** as the broad bucket and **`DocumentType.code`** as the agency-specific configured kind (no invented enum categories).

### Configuration reference catalog

Illustrative codes (not legal advice). Phase 2 demo seeds may include **only a subset** — see PR scope in implementation planning.

| Code | Category | Label (example) |
| --- | --- | --- |
| `contractor_w9` | `tax_form` | Contractor W-9 / tax form |
| `contractor_agreement` | `contractor_agreement` | Contractor agreement |
| `contractor_renewal_agreement` | `contractor_agreement` | Contractor renewal agreement |
| `contractor_eo_insurance` | `insurance` | E&O insurance evidence |
| `contractor_general_liability` | `insurance` | General liability evidence |
| `contractor_classification_support` | `classification_support` | Classification supporting documentation |
| `contractor_certification` | `certification` | Contractor certification evidence |
| `subcontractor_agreement` | `contractor_agreement` | Subcontractor agreement |
| `subcontractor_classification_support` | `classification_support` | Subcontractor classification support |

**Applicability:** configure `DocumentRequirement.relationship_type` as `individual_contractor`, `contractor_organization`, and/or `subcontractor` — **not** `employee` for contractor classification-support bundles.

**Document codes in demo DB:** Agencies may use **`w9`** or **`contractor_w9`** per seed/configuration choice; canonical codes going forward are listed above. TC-09 does **not** require a production migration for historic demo codes unless non-demo deployments depend on old codes.

---

## Classification support status (readiness summary)

Use the label **Classification support status** (not “classification status”) for aggregate UX.

**Source of truth:** `Documents::ReadinessEvaluator` → `ReadinessResult#readiness_status` (`ready`, `not_ready`, `warning`, `not_applicable`) and per-requirement `requirement_outcome` values.

**Do not** introduce outcomes such as `legally_compliant`, `properly_classified`, or `misclassified`.

**Requirement visibility:** Requirements whose `relationship_type` does not match the engagement (and is not `any`) **do not appear** in `ReadinessResult#requirements` — there is no separate “skipped row.”

---

## Category rollup (admin / Team360)

When rolling multiple requirement rows into one **category-level** summary (for example in admin or future Team360), use **worst outcome wins** with this priority (ties within tier are equivalent for MVP):

| Priority | Outcomes |
| --- | --- |
| 1 (blocking) | `missing`, `expired`, `rejected`, `pending_verification` |
| 2 | `expiring_soon` |
| 3 | `satisfied` |
| 4 | `not_applicable` |

Rollup must use **only** evaluator vocabulary — no new readiness labels.

---

## Admin panel (Phase 2 / TC-11 deferral)

For contractor-class engagements (`individual_contractor`, `contractor_organization`, `subcontractor`), an admin panel MAY show:

- Contractor identity summary (relationship type, engagement status, legal/trade name where applicable)
- **Classification support status** + blocking alerts / warnings from evaluator output
- Category-level rollup for contractor-relevant categories (`tax_form`, `contractor_agreement`, `insurance`, `classification_support`, `certification`)
- Links to `DocumentRecord` and requirement configuration

Implementation consumes **`Documents::ReadinessEvaluator`** output only — no duplicated readiness rules.

If Phase 2 stays minimal, panel requirements may be documented here and implemented under **TC-11** Team360 compliance panels.

---

## Reporting requirements (TC-12 dependency)

Operational lists and exception reporting (filters such as relationship type, readiness status, missing tax form, expired agreement, pending verification) belong to **TC-12**. TC-09 documents intent:

**Suggested filter dimensions:** `relationship_type`, `engagement.status`, document readiness / classification support aggregate status, missing contractor tax form, missing/expired agreement or insurance, pending verification, rejected document, expiring-soon insurance/certification, individual vs contractor organization.

**Drill-through:** `Engagement`, `DocumentRecord`, admin document type/requirement surfaces.

---

## Audit and permissions

Sensitive actions include: configuring classification-support document types and requirements; attaching records; verifying/rejecting/voiding records; changing expiration dates; changing contractor identity profile fields; changing readiness-affecting rules.

**Phase 2 posture:** coarse admin/compliance access — **TC-29** permission hardening, **TC-30** durable audit.

---

## Formal decisions

See [**TC-09-D01–D08**](../product/open-decisions.md).
