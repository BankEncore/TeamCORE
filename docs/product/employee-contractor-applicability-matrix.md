# Employee / contractor / subcontractor applicability matrix

## Purpose

Clarify **which capabilities apply** to:

- **Employees** — individual W-2–style engagements in TeamCORE MVP.
- **Contractors** — **individual independent contractors** and **contractor organizations** (business entities contracting with the agency), unless the notes say otherwise. Primary contacts at contractor orgs are often modeled as Parties/People with their own treatment; columns here assume the **economically contracting** worker or org role unless promoted otherwise.
- **Subcontractors** — parties tied to a contractor or contractor organization. MVP behavior is **staged per OD-004** (see **[Subcontractor handling](#subcontractor-handling-od-004)**).

Companion docs: **[`mvp-scope.md`](mvp-scope.md)**, **[`overview.md`](overview.md)**, **[`open-decisions.md`](open-decisions.md)** (especially **OD-004**).

---

## How to read the matrix

| Cell | Meaning |
| --- | --- |
| **Yes** | In-scope once the phased domain ships (unless a phase is cited in Notes). |
| **No** | Not offered for this category in MVP. |
| **Later** | Post-MVP or explicitly deferred; still “No” for initial MVP delivery. |
| **If promoted** | Applies once subcontractor follows the **elevate to Team Member** path (**OD-004**) with appropriate engagements. |
| **Related-party only** | Contact/party linkage only—no full contractor rails until elevated. |

---

## Applicability matrix

| Capability | Employee | Contractor | Subcontractor | Notes |
| --- | --- | --- | --- | --- |
| Party record | Yes | Yes | **Yes** (related party) or **optional** bare contact | Elevated subcontractors use same Party substrate as everyone else. |
| Team Member profile | Yes | Yes | **If promoted** → Yes · **Related-party only** → No/Maybe | OD-004: promote when docs, settlement, commission, Team360 demands direct tracking. |
| Engagement | Employment | Contractor | **If promoted** → typically contractor engagement · **Otherwise** generally **No** standalone engagement | Engagement is spine for obligations and payouts. |
| Organization placement | Yes | Yes | **If promoted** → Yes · else **typically N/A** | Placement hangs off Engagement. |
| Documents & compliance templates | Yes | Yes | **If promoted** → full path · **else** rules may defer or indirect | Activation readiness aligns with OD-006; admin upload only MVP. |
| Activation readiness signal | Yes | Yes | **If promoted** → Yes · else **minimal or N/A** | Compliance-owned calculation per roadmap. |
| Team360 panels | Yes | Yes | **If promoted** → full contractor-equivalent UX · else **minimal / absent** | Permission-aware OD-009. |
| Compensation (agency owes member) | Yes | Yes | **If promoted as contractor TM** · else **No** | Phase **4** MVP: salary/hourly vs flat-rate commission/draw framing. |
| Time tracking | Yes | No | No | MVP **employee-only** (`overview`, `mvp-scope`). |
| Leave | Yes | No | No | MVP **employee-only**. |
| Payroll artifact workflows | Yes | No | No | Payroll inputs / results / exports / imports—not full processing (**OD-007**); employees only (**Phase 5**). |
| Contractor settlement workflows | No | Yes | **If promoted** with settlement entitlement | Distinct rail from payroll OD-008; Phases **4–5**. |
| Contractor charges / recoverables | No | Yes | **If promoted** on contractor rails | Charges are contractor→agency obligation surface; Phase **4** shell. |
| Self-service MVP | Limited employee | Later / none MVP | None MVP | Punch/time/leave for employees Phase **5**; contractor portals deferred. |

---

## Payroll vs contractor settlement distinction

| Path | Who | MVP stance |
| --- | --- | --- |
| **Payroll artifact path** | Employees | TeamCORE manages **inputs**, **exports**, **imports**, **payroll run** references, and **payroll results** recording—**never** substitutes for statutory payroll processing (**RD-006**, **OD-007**). |
| **Contractor settlement path** | Contractors (and subcontractor-after-promotion) | TeamCORE manages settlement **runs/calculations/results** interchange semantics—**not** full accounting (**RD-007**, **OD-008**). |

These rails **must remain mutually exclusive per engagement**.

---

## Time and leave assumptions (MVP)

Employee-only working-time and absence workflows (**Phase 5**). Contractor time clocks or parity features are intentionally **absent**.

---

## Contractor charge applicability

Applies exclusively on the **contractor economic rail**—not employees unless a future parity decision reverses MVP scope. Elevated subcontractors participate only after promotion modeling links them into charge/settlement constructs (**OD-004**, **mvp-scope risky boundaries**).

---

## Subcontractor handling (OD-004)

| Need | Typical modeling |
| --- | --- |
| Contact/name only | Related party linkage; stays off Team Member rails. |
| Direct documents/compliance on person | Frequently **promote → Team Member** or explicit dual modeling—product prefers elevate when audits matter. |
| Settlement or commission splits involving person | **Promote**, contractor engagement. |

Deferred: advanced subcontractor graphing—tracked under OD-004 post-MVP follow-up (`open-decisions.md` deferred table).

---

## Acceptance criteria (**GH-39**)

- [x] Matrix distinguishes **employees**, **contractors**, **subcontractors** with explanatory column semantics.
- [x] **Payroll vs settlement** articulated in-matrix and in prose.
- [x] **Time/leave employee-only MVP** spelled out.
- [x] **Contractor charge** placement restricted.
- [x] **Subcontractor** ambiguity surfaced with OD-004 promotion tiers vs related-party shorthand.
