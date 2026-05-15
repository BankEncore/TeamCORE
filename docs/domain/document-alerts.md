# Document alerts (TC-07)

**Epic:** Missing and expiration document alerts — derived **presentation** on top of **TC-06** readiness evaluation ([`documents-compliance.md`](documents-compliance.md)).

**Evaluator:** **`Documents::ReadinessEvaluator`** is the sole source of truth for **`readiness_status`**, **`requirement_outcome`**, **`record_review_status`** ([TC-06-D08](documents-compliance.md)), and **virtual `alerts[]`** (**no** persisted alert table).

**Cross-links:** [`documents-compliance.md`](documents-compliance.md), [`domain-map.md`](../product/domain-map.md), [`open-decisions.md`](../product/open-decisions.md) (TC-07-D01–D10).

---

## Purpose

TC-07 surfaces **actionable alerts** — missing, expired, expiring-soon, rejected, pending verification — **at read time** from evaluator output. It does **not** add parallel compliance logic, persisted `document_alerts` rows, notifications, dismissal, waiver, full Team360, or TC-12 reporting frameworks.

---

## Alert taxonomy

| Alert type | Meaning | Severities used in TC-07 MVP |
| --- | --- | --- |
| `missing` | Required applicable requirement has no usable non-void `DocumentRecord` | `blocking` |
| `expired` | Best record has **`expires_on` < `as_of_date`** (record may remain `verified`) | `blocking` |
| `expiring_soon` | Window for “expiring soon” uses the same chain as TC-06 (see **TC-07-D03** in **open-decisions**).
| `rejected` | Best record is **`rejected`** under TC-06 best-candidate rules | `blocking` |
| `pending_verification` | **`verification_required`** and best record **`submitted`** | `blocking` |

**Optional later (not emitted in TC-07):** `voided_current_record`, `configuration_gap`, etc.

**Alerts only for required requirements:** Optional requirements (**`required: false`**) emit **no** alerts unless a future “monitored optional” product rule is introduced (**TC-07-D06**).

---

## Severity and readiness

| Severity | Default use in TC-07 |
| --- | --- |
| `blocking` | `missing`, `expired`, `rejected`, `pending_verification` on required requirements |
| `warning` | `expiring_soon` on required requirements |
| `info` | **Reserved**, **unused by default** in TC-07 MVP (**TC-07-D02**) |

Aggregation of **`readiness_status`** stays in the evaluator (**unchanged TC-06**): blocking outcomes → **`not_ready`**; exclusively satisfied with some expiring-soon → **`warning`**; otherwise **`ready`** / **`not_applicable`**.

---

## Rules (requirements → alerts)

Alerts are derived **after** **`RequirementEvaluation`** rows are computed (**one alert per alerting evaluation row**) — traceability:

`alert → RequirementEvaluation → DocumentRequirement → DocumentType → DocumentRecord (optional)`

### Missing (**TC-07.03**)

When **`requirement_outcome`** is **`missing`** for a **required** row: alert **`missing`**; **`document_record_id`** and **`record_review_status`** are **`nil`**.

Inactive requirements/types are excluded upstream (existing evaluator query).

**Related-only subcontractors:** No engagement-backed evaluation — no engagement alerts (already TC-06). **Promoted** subcontractor engagements follow normal evaluator paths.

### Expired (**TC-07.04**)

**`expires_on` < `as_of_date`** on the evaluated best record. Do **not** persist **`expired`** as `DocumentRecord.status`.

### Expiring-soon (**TC-07.05**)

**`expires_on` ≥ `as_of_date`** AND **`expires_on` ≤ `as_of_date + expiring_soon_days`** (priority: requirement override → `DocumentType#default_expiring_soon_days` → hard **30**). Does **not** force **`not_ready`** if all blocking outcomes clear; readiness may be **`warning`**.

### Rejected (**TC-07.06**)

When best record **`status = rejected`**; include **`rejection_reason`** on **`AlertResult`** when present.

### Pending verification (**TC-07.06**)

When **`verification_required`** and submitted best record yields **`pending_verification`**.

---

## Contractor-facing nuance (**TC-07.07**) — category + code

Use **`DocumentType.category`** as the **broad bucket** and **`DocumentType.code`** as the specific configured kind (**no invented enum categories**). Examples:

- `tax_form` + `contractor_w9`
- `insurance` + `contractor_eo_insurance`
- `contractor_agreement` + `contractor_renewal_agreement`

Alerts do **not** perform legal classification; they reflect configured types and evaluator outcomes only.

---

## Public API (**TC-07.08`)

**`Documents::ReadinessResult`:** `engagement_id`, **`as_of_date`** (default **`Date.current`** — **TC-07-D08**), **`readiness_status`**, **`requirements`** (requirement evaluations), **`alerts`** (`Documents::AlertResult[]`, sorted per **TC-07-D09**).

**`Documents::AlertResult`:** Stable id-oriented fields **`alert_type`**, **`severity`**, **`requirement_outcome`**, **`record_review_status`**, ids for requirement/type/record/engagement/team member, **`expires_on`**, **`days_until_expiration`**, **`rejection_reason`**, **`message`**.

### Nullability and numbers

- **`missing`** alerts: **`document_record_id`** and **`record_review_status`** are **`nil`**.
- **`days_until_expiration`:** **`expires_on - as_of_date`** in **days** when `expires_on` present; **may be negative** for expired alerts (views may derive “expired N days ago” from this).
- **`expires_on` / days** may be **`nil`** when no date applies.

Human **`message`** strings are centralized in **`Documents::AlertMessageBuilder`** (**TC-07-D07**) — views do not assemble outcome-specific business copy.

### Alert sort order (**TC-07-D09**)

Deterministic ordering for stable UI/tests:

1. Severity: **`blocking` → `warning` → `info`**
2. **`alert_type`:** `missing` → `expired` → `rejected` → `pending_verification` → `expiring_soon`
3. **`expires_on`** ascending (**nil** last)
4. Document type **`code`** (tie-break)

Preload **`DocumentType`** rows for ids on alerts to avoid N+1.

---

## Admin behavior (**TC-07-D10**)

| Surface | Engagement scope |
| --- | --- |
| **Engagement detail** (`Admin::EngagementsController#show`) | Run evaluator for the **shown engagement regardless of terminal status**. |
| **Cross-engagement alert index** | Default engagements to **non-terminal** only (`ended`, `terminated`, `cancelled` excluded). Explicit filter/param to include terminal for historical review. |

The index route is **`GET`** only (**read-only** controller; virtual alerts).

---

## Team360 / reporting handoff (**TC-07.12**)

Future **Team360** (TC-10) and operational reporting (**TC-12**) should consume **`Documents::ReadinessEvaluator`** `/ **ReadinessResult**` (**alerts[]** + summaries) rather than recomputing. Drill-through: **`Engagement`**, **`DocumentRecord`**, document configuration admin surfaces.

---

## Audit / permissions (**TC-07.13**)

Until **TC-29/TC-30:** admin-only/coarse access; viewing alerts is sensitivity-adjacent. No alert dismissal, waiver, notifications, durable audit ledger, or self-service in TC-07.

---

## Locked decisions (TC-07-D01–D10)

See **`open-decisions.md`** for authoritative register summaries. Highlights:

| ID | Decision |
| --- | --- |
| **TC-07-D01** | Virtual alerts; no **`document_alerts`** table |
| **TC-07-D02** | Severities **`blocking` / `warning` / `info`**; **`info` unused by default |
| **TC-07-D03** | Expiring-soon window chain (requirement → type default → agency optional later → **30**) |
| **TC-07-D04** | No dismissal/snooze/waiver |
| **TC-07-D05** | No email/SMS/background jobs |
| **TC-07-D06** | Alerts only **`required`** |
| **TC-07-D07** | **`AlertMessageBuilder`** owns human **`message`** |
| **TC-07-D08** | Default **`as_of_date`** = **`Date.current`** |
| **TC-07-D09** | Deterministic alert sort |
| **TC-07-D10** | Detail always evaluates; index defaults non-terminal |

---

## Explicit exclusions for TC-07

Email/SMS, background aggregation jobs, persisted alert lifecycle, self-service uploads, payroll/settlement blocking, full RBAC/audit ledger, full Team360/reporting UX, waiver workflow.
