# Modeling note — Party, Team Member, and Engagement

**Related:** OD-001 in [`open-decisions.md`](../open-decisions.md). TC-02 domain specification: [`docs/domain/party-team-member.md`](../../domain/party-team-member.md).  
**Status:** Accepted  
**Supersedes:** Informal ambiguity in earlier domain-map drafts.

This note is intentionally shorter than an ADR. Promote to `docs/architecture/ADR-xxxx` when engineering requires immutable decision history.

---

## Context

TeamCORE must represent:

- People and organizations that may exist before or outside a workforce relationship
- Agency-specific workforce participation
- Distinct employment and contractor relationships over time

---

## Decision

Use **three** distinct concepts:

| Concept | Role |
| --- | --- |
| **Party** | Identity and legal/contact substrate: person or organization (employee candidate, contractor, contractor org, subcontractor, related contact, vendor-like org, etc.). |
| **Team Member** | Agency-linked **workforce participant** profile; references a Party. |
| **Engagement** | The **relationship instance** between the agency and the team member: employee vs contractor path, lifecycle status, placement, supervisor, and rules that drive downstream domains. |

```text
Party → Team Member → Engagement(s)
```

---

## Rules of thumb

- Party **does not** imply active employment or contractor workflow by itself.
- Team Member is the object most **operational domains** reference together with **Engagement**.
- Engagement is the **spine** for status, required documents/compliance context, compensation vs payroll vs settlement eligibility, and time/leave (employee path).

---

## Consequences (product / schema)

- Historical engagements attach to the same Team Member (and Party) where identity is continuous.
- Promoting a subcontractor to full participation implies creating (or activating) **Team Member** and appropriate **Engagement** when agency policy requires (per OD-004).
- Team360 panels read from Party, Team Member, Engagement, and downstream domains without duplicating ownership.

---

## Out of scope for this note

- Exact table names, STI/polymorphism, or tenancy column layout
- Multi-agency row layout (see OD-011)
