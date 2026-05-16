# Documents and compliance (TC-06)

**Epic / issue:** Document Configuration and Readiness Foundation — [GitHub issue #7](https://github.com/BankEncore/TeamCORE/issues/7) (**TC-06**).

**Cross-links:** Product [**OD-005** / **OD-006**](../product/open-decisions.md); domain map [**Documents** / **Compliance**](../product/domain-map.md); [**Glossary**](../product/glossary.md) (document and compliance terms); [**Engagement**](./engagement.md) (applicability spine, `relationship_type`); [**Subcontractor relationships**](./subcontractor-relationships.md) (**TC-05**); engagement status semantics [`engagement-status.md`](engagement-status.md); **TC-07 alerts** [`document-alerts.md`](document-alerts.md); **TC-08 verification** [`document-verification.md`](document-verification.md) (verify/reject/void via **`Documents::ReviewDocumentRecord`**; readiness still **`Documents::ReadinessEvaluator`**-derived — **TC-08-D07** blocks generic **`DocumentRecord`** status mutation).

---

## Purpose

This hub defines how TeamCORE separates **document artifacts** from **compliance interpretation**, what is configured vs derived, and how **engagement documentation readiness** is computed — without building a full workflow engine in TC-06.

**Core question:** Given an **engagement**, which documents are **required**, what is each requirement’s **effective outcome**, and is the engagement **document-ready** from TeamCORE’s perspective?

TC-06 is **not** legal determination, **not** full RBAC/audit ledger, **not** self-service upload/product UX (**TC-07**+), and **not** payroll/settlement blocking (**explicitly out of scope**).

---

## Domain boundary (OD-005)

| Concept | Owns |
| --- | --- |
| **Document type** | Catalog: code, category, defaults (expiring-soon window, verification default, expiration semantics flags). **Does not** carry applicability in v1 — see **TC-06-D06** below. |
| **Document requirement** | Applicability: `requirement_scope`, `relationship_type`, mandatory vs optional, verification and expiration flags, overrides. |
| **Document record** | Submitted artifact metadata, **persisted review status** on the row, expiry dates, file metadata / `storage_key`. |
| **Verification** | Operational review of a **record** (verifier, timestamps, rejection reason). Sensitive; coarse admin checks in TC-06. |
| **Readiness** | **Derived** interpretation — missing, expired, expiring-soon, pending verification, satisfied — produced only by **`Documents::ReadinessEvaluator`**. |

**Compliance** in OD-005 terms is the **interpretation layer** (requirements + derived readiness signals). **Documents** own **records** and verification fields on those records.

> **`Documents::ReadinessEvaluator`** is the **sole source of truth** for document readiness and derived alert semantics. Controllers, views, Team360, and reporting must **consume** evaluator output — they must not reimplement missing/expired/ready logic (**TC-06-D03**).

**TC-07 — alert presentation:** Virtual **alerts** (`Documents::AlertResult[]` on **`Documents::ReadinessResult`**) are documented in [**`document-alerts.md`**](document-alerts.md). TC-07 surfaces evaluator output in admin (and later Team360/reporting); it does **not** add a persisted alert table or duplicate readiness rules.

---

## Model overview (implementation)

- **`DocumentType`** — agency-scoped catalog row; **`status`** `active` \| `inactive`. No `applies_to` on the type (**TC-06-D06**).
- **`DocumentRequirement`** — links a type to applicability: **`requirement_scope`** **`engagement`** \| **`team_member`** in v1 (**`agency` scope deferred** — **TC-06-D12**). **`relationship_type`** is **never NULL**; use **`"any"`** for broad applicability (**TC-06-D10**). Uniqueness: `(agency_id, document_type_id, requirement_scope, relationship_type)`.
- **`DocumentRecord`** — append-friendly history (**TC-06-D09**): **no** uniqueness on `(engagement_id, document_type_id)` or `(team_member_id, document_type_id)`. Attach to **TeamMember** and/or **Engagement**; if **Engagement** is present, **`team_member_id`** is synced from the engagement (**TC-06-D02**).

**File storage (TC-06-D07):** metadata-first — `storage_key`, `filename`, `content_type`, `byte_size`. **Active Storage** only if an admin upload path (e.g. PR D) explicitly adds uploads.

---

## Persisted vs derived status (TC-06-D01)

**Persisted on `DocumentRecord`** (column `status`; in evaluator payloads also **`record_review_status`**):

`submitted` \| `verified` \| `rejected` \| `voided`

**Never** persist evaluator outcomes such as `missing`, `expired`, `expiring_soon`, **`satisfied`**, or engagement **`readiness_status`** on the document row.

> `DocumentRecord` persists only the four review statuses above. Missing, expired, expiring-soon, pending verification, **satisfied**, and readiness states are **derived** by the readiness evaluator and are **not** stored as `DocumentRecord` statuses.

---

## Evaluator vocabulary (TC-06-D08)

Avoid **vocabulary collision** on **`verified`**: it names **record review status**, **not** the primary label for “requirement met.”

| Layer | Field | Values |
| --- | --- | --- |
| Document record | `record_review_status` | `submitted`, `verified`, `rejected`, `voided` |
| Requirement | `requirement_outcome` | `missing`, `pending_verification`, **`satisfied`**, `rejected`, `expired`, `expiring_soon`, `not_applicable` |
| Engagement | `readiness_status` | `ready`, `not_ready`, `warning`, `not_applicable` |

> **`verified`** is a persisted `DocumentRecord` review status. Requirement evaluation uses **`satisfied`** when a requirement is met. Evaluator output uses explicit keys **`record_review_status`**, **`requirement_outcome`**, and **`readiness_status`**.

**Satisfied vs verified:** **`verified`** = record passed review (`DocumentRecord.status = verified`). **`satisfied`** = requirement outcome after rules (verification, expiration, applicability). Do **not** use **`verified`** as the primary requirement-outcome label when **`satisfied`** is intended.

---

## Multiple records and best candidate (TC-06-D09)

Resubmissions, renewals, and corrections create **additional** rows. The evaluator selects the **best current candidate** per requirement, with tie-break **`submitted_on DESC`**, then **`created_at DESC`**.

Priority among matching records (highest first):

1. `verified` and not expired  
2. `submitted`, verification not required, not expired → can yield **`satisfied`**  
3. `submitted`, verification required → **`pending_verification`**  
4. `rejected` only if no better record → **`rejected`**  
5. `verified` but expired → **`expired`**  
6. No usable row → **`missing`**

**`voided`** records are excluded from candidacy for satisfaction; they remain in the database for audit.

> `DocumentRecord` is append-friendly. The readiness evaluator selects the best applicable record per requirement, preferring current verified records, then current submitted records, while preserving rejected, expired, and voided records for history.

---

## Rejection and validation (TC-06-D11)

When **`DocumentRecord.status = rejected`**, **`rejection_reason`** is **required**, along with **`verified_by_id`** and **`verified_on`**.

| `status` | Required fields |
| --- | --- |
| `submitted` | `submitted_on` |
| `verified` | `verified_by_id`, `verified_on` |
| `rejected` | `verified_by_id`, `verified_on`, **`rejection_reason`** |
| `voided` | optional reason for now |

---

## Readiness aggregation (TC-06-D03)

Overall engagement **`readiness_status`** (document-only slice):

| Condition | `readiness_status` |
| --- | --- |
| No applicable requirements | `not_applicable` |
| Any **required** requirement `missing`, `rejected`, or `expired`, or **`pending_verification`** | `not_ready` |
| All **required** requirements **`satisfied`** (or **`expiring_soon`** only — see below) | `ready` or `warning` |
| All **required`** satisfied, at least one **`expiring_soon`** | `warning` |
| All **required`** satisfied, none expiring soon | `ready` |

**Optional** requirements (`required: false`) do not block **`ready` or `not_ready`**; they may still appear in per-requirement results for visibility.

---

## Subcontractor applicability (TC-06.05 / 06.06)

- **Related-only** subcontractors (**PartyRelationship** only, **no** `subcontractor` **Engagement**): **no** engagement-driven requirement evaluation for that person (no engagement spine to attach to).
- **Promoted** subcontractors (**Engagement** with `relationship_type = subcontractor`): requirements and records use the same engagement-scoped paths as other relationship types when configured.

Authoritative subcontractor nuance: [`subcontractor-relationships.md`](subcontractor-relationships.md).

---

## Contractor classification support (TC-06-D05)

Support contractor classification **documentation** via types, requirements, records, and **existing** profile fields (e.g. organization kind, legal name). TeamCORE **does not** make legal classification determinations in TC-06.

---

## Waivers (TC-06-D04)

**Out of scope for TC-06.** Do not add waiver columns, waiver workflow, or readiness overrides; those pull permission, audit, and policy forward (**TC-29/TC-30**).

---

## Team360 and reporting (TC-06.12)

Document **panel fields** and **report lists** (missing, expired, expiring, pending verification, not document-ready, etc.) are **requirements** for downstream epics (**TC-10/TC-11/TC-12**). TC-06 delivers the evaluator contract; full UIs are not required in TC-06 unless scoped.

---

## Audit and permissions (TC-06.13)

Sensitive actions: configure types/requirements; create/update/verify/reject/void records; change expiry; rules that affect readiness. Map intent to roles in documentation; enforce **admin-only** or coarse checks until **TC-29/TC-30**.

---

## MVP document category catalog (seed-oriented)

Illustrative **categories** (not legal advice): `employee_agreement`, `tax_form`, `contractor_agreement`, `classification_support`, `insurance`, `certification`, `other`. Seeds use a **subset** for demos.

---

## Formal decision IDs (TC-06-D01–D12)

See implementation and tests for **TC-06-D01** through **TC-06-D12** in [open decisions](../product/open-decisions.md) and Rails models/services. Summary:

| ID | Topic |
| --- | --- |
| **D01** | Persisted vs derived status |
| **D02** | Attachment targets (Engagement / TeamMember) |
| **D03** | Evaluator single source of truth |
| **D04** | Waivers excluded |
| **D05** | Classification support via docs + profiles |
| **D06** | No type-level `applies_to` |
| **D07** | Metadata-first file storage; Active Storage with upload PR only |
| **D08** | Evaluator vocabulary (`record_review_status`, `requirement_outcome`, `readiness_status`) |
| **D09** | Multiple records; best-candidate ordering |
| **D10** | `relationship_type` **NOT NULL**, **`"any"`** default |
| **D11** | **`rejection_reason`** required when rejected |
| **D12** | **Defer `agency` `requirement_scope`** — v1: **`engagement`**, **`team_member`** only |

---

## Relation to activation readiness (OD-006)

**OD-006** activation readiness is broader than documents alone. TC-06 defines the **document slice**: configured requirements + records + **`Documents::ReadinessEvaluator`**. Full activation rules (multi-domain) remain a Phase 2+ catalog; document readiness **feeds** OD-006 but does not subsume it.
