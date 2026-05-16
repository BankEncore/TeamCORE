# Document verification (TC-08)

**Epic:** Controlled **review** actions on **`DocumentRecord`**: **`verify`**, **`reject`**, **`void`**. Submission remains **`status: submitted`** (create path). Compliance **readiness** and **TC-07 alerts** are **never** written directly—they are derived by **`Documents::ReadinessEvaluator`** when consumers re-run evaluation after a record changes.

**Cross-links:** [`documents-compliance.md`](documents-compliance.md) (TC-06); [`document-alerts.md`](document-alerts.md) (TC-07); [**open-decisions**](../product/open-decisions.md) (**TC-08-D01–D07**).

---

## Core rule

```text
DocumentRecord.status and review metadata change (via Documents::ReviewDocumentRecord or allowed metadata edits)
↓
Controllers and views consume Documents::ReadinessEvaluator / ReadinessResult (and TC-07 alerts where surfaced)
↓
No parallel “engagement readiness” persistence; no duplicated missing/expired/rejected branching in UI controllers
```

Verification is an **administrative review**. It **does not** determine legal classification, **does not** waive requirements, and **does not** substitute for future durable audit (**TC-30**).

---

## Domain boundaries (included vs excluded)

**TC-08 includes**

- Verification rules and **transition matrix** (see below).
- **Documents::ReviewDocumentRecord** as the sole application path for verify / reject / void (**TC-08-D07**).
- Atomic review persistence (`transaction`).
- **`ReviewDocumentRecordResult`** for expected validation failures (not exceptions).
- Coarse verifier gate (**TC-08-D05**): MVP = signed-in admin with agency context (`require_document_verifier` ≡ existing admin prerequisites).
- Admin UX + **pending-review worklist** (submitted records).
- Tests for transitions, evaluator interaction, agency scoping.

**TC-08 excludes**

- Full RBAC / permission matrix (**TC-29**).
- Durable audit ledger / note history (**TC-30**); **`verification_notes`** stores the **latest** review note only and is **replaced** on each review action.
- Self-service uploads, e-sign, waivers, alert dismiss/snooze, notifications/jobs, payroll/settlement blocking.

---

## Persisted statuses and transitions (**TC-08.03**)

Statuses: **`submitted`**, **`verified`**, **`rejected`**, **`voided`**.

| From | To | Action |
| --- | --- | --- |
| `submitted` | `verified` | verify |
| `submitted` | `rejected` | reject |
| `submitted` | `voided` | void |
| `verified` | `voided` | void |
| `rejected` | `voided` | void |
| `voided` | _(none)_ | terminal (MVP) |

**No in-place resubmission:** **`rejected` → `submitted`** is forbidden (**TC-08-D04**). Corrected artifacts create a **new** **`DocumentRecord`**.

Voiding **`verified`** or **`rejected`** rows **preserves** **`verified_by_id`**, **`verified_on`**, and **`rejection_reason`**; **`void`** only sets **`status = voided`** and may replace **`verification_notes`** when the void action supplies notes (**TC-08-D03**).

---

## Metadata requirements (**TC-08-D01**, **TC-08.07**)

| Status | Required |
| --- | --- |
| `submitted` | **`submitted_on`** |
| `verified` | **`verified_by_id`**, **`verified_on`** |
| `rejected` | **`verified_by_id`**, **`verified_on`**, **`rejection_reason`** |
| `voided` | No verifier columns required MVP; **`verification_notes`** recommended for operational context |

**Naming:** **`verified_on`** / **`verified_by_id`** mean **review actor and review date** for both verify and reject; no schema rename (**TC-08-D01**).

**Review notes:** **`verification_notes`** is **last-write-wins** per review action; **durability deferred** (**TC-30**).

---

## Role intentions vs MVP (**TC-08.02**)

Intent (future refinement under **TC-29**):

| Intended role | Authority (documented intention) |
| --- | --- |
| `agency_owner_admin` | Configure and verify agency documents |
| `hr_admin` | Verify employee/onboarding documents |
| `compliance_user` | Verify compliance/insurance/classification/certification-oriented documents |

**MVP enforcement:** same as admin document access today—authenticated admin user + agency scope. **`require_document_verifier`** aliases that posture until fine-grained roles exist.

---

## Sensitive actions / audit (**TC-08.12**)

Treat as permission- and audit-adjacent: verify, reject, void, altering **`expires_on`**, verifier fields, **`rejection_reason`**, **`submitted_on`** (immutable after leaving **`submitted`** in MVP). **`expires_on`** edits affect readiness via the evaluator and should be tightened under **TC-29/TC-30**.

---

## Implementation (code)

| Concern | Location |
| --- | --- |
| Review command + result | **`app/services/documents/review_document_record.rb`** |
| Review routes | **`post`** **`verify`** / **`reject`** / **`void`** on **`admin/document_records#...`** |
| Pending queue | **`Admin::DocumentReviewsController#index`** — **`GET /admin/document_reviews`** |
| Generic CRUD | **`status`** and review metadata **not** mass-assignable on **`create`** / **`update`** per **TC-08-D07** |

---

## Implementation acceptance checklist

- [x] **`DocumentRecord.status`** cannot change via generic **`create`** (always **`submitted`**) or **`update`** alone; only **`Documents::ReviewDocumentRecord`** performs verify/reject/void transitions.
- [x] **Review command** wraps persistence in **`transaction`** and returns **`ReviewDocumentRecordResult`** for failures.
- [x] **`verification_notes`** = latest note per review action; durable history deferred.
- [x] **Void** preserves prior verifier / **`rejection_reason`** when applicable.
- [x] **TC-08-D06:** worklist defaults to **`DocumentRecord`** rows **`status: submitted`**; optional **`document_type.verification_required`** hint in list columns.
