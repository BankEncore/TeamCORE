# Recommended MVP wireframe

For the first Team360 version, I would use this:

```
+--------------------------------------------------------------------+
| Team360                                                            |
| [Name]                 [Team Status] [Relationship] [Readiness]    |
| [Current Position] * [Org Unit] * [Location]                       |
|                                                                    |
| [Edit Profile] [Add Document] [Assign Position] [View Audit]       |
+--------------------------------------------------------------------+

+---------------------------------------+----------------------------+
| Readiness                             | Quick Facts                |
|---------------------------------------|----------------------------|
| Overall Status                        | Team Member ID             |
| Missing Requirements                  | Engagement Type            |
| Pending Reviews                       | Current Manager            |
| Expiring Soon                         | Start Date                 |
| Last Evaluated                        | Primary Contact            |
+---------------------------------------+----------------------------+

+---------------------------------------+----------------------------+
| Current Engagement                    | Current Position           |
|---------------------------------------|----------------------------|
| Type                                  | Title                      |
| Status                                | Department / Team          |
| Start Date                            | FTE / Capacity             |
| End Date                              | Effective Date             |
| Related Contractor Organization       | Reports To                 |
+---------------------------------------+----------------------------+

+--------------------------------------------------------------------+
| Documents & Requirements                                           |
|--------------------------------------------------------------------|
| Req. | Applies To | Status | Record | Expire | Review | Action     |
+--------------------------------------------------------------------+

+---------------------------------------+----------------------------+
| Compensation / Settlement Setup       | Recent Activity            |
|---------------------------------------|----------------------------|
| Pay/Settlement Profile                | Profile changes            |
| Commission Plan                       | Document uploads           |
| Payroll/Vendor ID                     | Verification actions       |
| Setup Status                          | Engagement changes         |
+---------------------------------------+----------------------------+

```

---

# Suggested visual hierarchy

## Top header

Use the header for identity and state:

```
Jane Smith
Senior Travel Advisor · Retail Sales · Detroit Office
[Active] [Employee] [Ready to Work]
```

## First row

Use first row for operational answer:

Is this person ready and what should I pay attention to?

So:

* Readiness  
* Alerts  
* Quick facts

## Middle rows

Use middle area for current authoritative state:

* engagement  
* position  
* documents

## Bottom / side area

Use bottom or side for secondary context:

* compensation setup  
* access/assets  
* audit/recent activity

---

# Suggested tabs, if needed later

I would not start with tabs unless the page gets too long.

Later tabs could be:

| Tab | Contents |
| :---- | :---- |
| **Overview** | readiness, current engagement, current position, alerts |
| **Documents** | requirements, records, verification history |
| **Engagements** | current and historical relationships |
| **Positions** | assignment history |
| **Compensation** | payroll, commissions, settlement setup |
| **Access** | roles, permissions, system accounts, assets |
| **Activity** | events, notes, audit trail |

For MVP, I would keep everything on one page and only introduce tabs when the page becomes unwieldy.

---

# My preferred direction

I would use **Option 5: two-column truth \+ context layout**.

## Recommended Team360 page structure

```
Header
├── Identity
├── Status badges
└── Primary actions

Main column
├── Activation readiness
├── Current engagement
├── Current position
├── Documents & requirements
├── Compensation setup
└── Position / engagement history

Right context column
├── Quick facts
├── Alerts
├── Contact summary
├── Related organization
└── Recent activity
```

This gives Team360 a clear identity:

a practical, admin-grade team member command center without making it the owner of every workflow.

# Revised recommendation

## Recommended TeamCORE palette

| Role | Hex | Name | Use |
| :---- | ----: | :---- | :---- |
| **Primary** | `#0F294A` | Midnight Voyage | Headers, nav, major structure |
| **Primary Dark** | `#071A30` | Deep Navy | Dark sidebar, dark hover states |
| **Secondary** | `#007C89` | Harbor Teal | Links, active states, secondary actions |
| **Secondary Soft** | `#DDF4F3` | Pale Teal | Badges, subtle highlights |
| **Accent** | `#D97745` | Muted Terracotta | Limited CTAs, warm highlights |
| **Neutral Dark** | `#1E293B` | Deep Slate | Body text |
| **Neutral Mid** | `#64748B` | Slate Gray | Secondary text, metadata |
| **Neutral Light** | `#F8FAFC` | Clear Sky | App background |
| **Surface** | `#FFFFFF` | White | Cards/panels |
| **Border/Muted** | `#E2E8F0` | Mist Gray | Borders/dividers |

This keeps the “global/travel” character, but makes it more controlled.

---

# Better CTA strategy

I would not use the warm accent for every primary action.

For an operations platform, the safest pattern is:

| Action Type | Color |
| :---- | :---- |
| Primary workflow action | Navy or teal |
| Secondary action | White/outline/slate |
| Compliance warning | Amber |
| Destructive action | Red |
| Promotional/rare CTA | Terracotta |

So instead of:

```
[Approve Contract] = Coral
[Onboard New Contractor] = Coral
[Add Document] = Coral
```

I would use:

```
[Onboard Team Member] = Navy
[Add Document] = Teal
[Approve] = Navy or Teal
[Reject] = Red
[Expiring Soon] = Amber
[Special CTA] = Terracotta
```

That avoids training users to associate a decorative accent with operational authority.

---

# I would revise the “60-30-10” rule

The 60-30-10 idea is fine for branding, but product UI needs more nuance.

For TeamCORE, I would think this way:

| Layer | Approx. Use | Colors |
| :---- | ----: | :---- |
| **Workspace background** | 50–60% | `#F8FAFC` |
| **Surfaces/cards** | 20–30% | `#FFFFFF` |
| **Text/structure** | 10–15% | `#1E293B`, `#0F294A` |
| **Interactive accents** | 3–7% | teal |
| **Warm accent** | 1–3% | terracotta/copper |
| **Semantic statuses** | only when meaningful | green/amber/red |

The warm accent should be used sparingly.

---

# Semantic colors

Your semantic colors are good, but I would slightly tune them to match the palette.

Current:

| Semantic | Current |
| :---- | ----: |
| Success | `#10B981` |
| Warning | `#F59E0B` |
| Danger | `#EF4444` |

These are Tailwind defaults and work fine. But they are a little bright next to the muted enterprise palette.

## Suggested semantic set

| Status | Hex | Use |
| :---- | ----: | :---- |
| **Success** | `#059669` | verified, compliant, active-ready |
| **Success Soft** | `#ECFDF5` | success badge background |
| **Warning** | `#D97706` | pending, expiring soon, attention needed |
| **Warning Soft** | `#FFFBEB` | warning badge background |
| **Danger** | `#DC2626` | expired, rejected, blocked |
| **Danger Soft** | `#FEF2F2` | danger badge background |
| **Info** | `#2563EB` | informational/system notices |
| **Info Soft** | `#EFF6FF` | info badge background |
| **Neutral** | `#64748B` | inactive, draft, unknown |

This keeps statuses readable without feeling too loud.

---

# Recommended final palette

## Brand / UI palette

| Token | Hex | Use |
| :---- | ----: | :---- |
| `--tc-primary` | `#0F294A` | main brand/nav/header |
| `--tc-primary-dark` | `#071A30` | dark hover/sidebar |
| `--tc-secondary` | `#007C89` | links, active states, secondary actions |
| `--tc-secondary-soft` | `#DDF4F3` | subtle teal backgrounds |
| `--tc-accent` | `#D97745` | limited warm accent |
| `--tc-accent-soft` | `#FFF4EC` | subtle warm background |
| `--tc-text` | `#1E293B` | primary text |
| `--tc-text-muted` | `#64748B` | metadata/secondary text |
| `--tc-bg` | `#F8FAFC` | page background |
| `--tc-surface` | `#FFFFFF` | cards/panels |
| `--tc-border` | `#E2E8F0` | borders/dividers |

## Semantic palette

| Token | Hex | Use |
| :---- | ----: | :---- |
| `--tc-success` | `#059669` | verified/compliant |
| `--tc-success-bg` | `#ECFDF5` | success background |
| `--tc-warning` | `#D97706` | pending/expiring |
| `--tc-warning-bg` | `#FFFBEB` | warning background |
| `--tc-danger` | `#DC2626` | expired/rejected/blocked |
| `--tc-danger-bg` | `#FEF2F2` | danger background |
| `--tc-info` | `#2563EB` | informational |
| `--tc-info-bg` | `#EFF6FF` | info background |

---

# Example Team360 application

## Header

```
Background: #0F294A
Text:       #FFFFFF
Badges:     soft semantic colors
```

## Main page

```
Page background: #F8FAFC
Cards:           #FFFFFF
Borders:         #E2E8F0
Text:            #1E293B
Muted text:      #64748B
```

## Links / active states

```
Active tab:       #007C89
Link text:        #007C89
Focus ring:       #007C89 with opacity
Selected row bg:  #DDF4F3
```

## CTA buttons

```
Primary:          #0F294A
Secondary:        white with #CBD5E1 border
Tertiary/link:    #007C89
Rare warm CTA:    #D97745
Danger:           #DC2626
```

# TeamCORE CSS structure for Team360

**CONCEPTUAL starter set — not repo-verified.** This is designed around the prior Team360 direction: a two-column “truth \+ context” record layout, Tailwind as the styling engine, and a TeamCORE-owned component layer instead of a full UI library. The uploaded notes specifically call for `tc-page`, `tc-record-header`, `tc-panel`, `tc-status-badge`, `tc-alert`, `tc-data-table`, `tc-kv-grid`, and similar reusable classes, with Team360 favoring a dense admin/compliance workstation style.

Recommended file layout:

```
app/assets/stylesheets/
├── application.tailwind.css
└── teamcore/
    ├── 01_tokens.css
    ├── 02_base.css
    ├── 03_components.css
    ├── 04_tables.css
    ├── 05_forms.css
    └── 06_workspaces.css
```

Then import them from `application.tailwind.css`.

---

## `app/assets/stylesheets/application.tailwind.css`

```css
@import "tailwindcss";

/*
  TeamCORE design layer.
  Keep these imports after Tailwind so TeamCORE classes can use @apply.
*/

@import "./teamcore/01_tokens.css";
@import "./teamcore/02_base.css";
@import "./teamcore/03_components.css";
@import "./teamcore/04_tables.css";
@import "./teamcore/05_forms.css";
@import "./teamcore/06_workspaces.css";
```

---

# 1\. `01_tokens.css`

Use this as the color, spacing, border, radius, and shadow foundation.

```css
/* app/assets/stylesheets/teamcore/01_tokens.css */

@layer base {
  :root {
    /* Brand / structural palette */
    --tc-primary: #0f294a;
    --tc-primary-dark: #071a30;
    --tc-secondary: #007c89;
    --tc-secondary-soft: #ddf4f3;
    --tc-accent: #d97745;
    --tc-accent-soft: #fff4ec;

    /* Neutral palette */
    --tc-text: #1e293b;
    --tc-text-muted: #64748b;
    --tc-text-subtle: #94a3b8;
    --tc-bg: #f8fafc;
    --tc-surface: #ffffff;
    --tc-surface-muted: #f1f5f9;
    --tc-border: #e2e8f0;
    --tc-border-strong: #cbd5e1;

    /* Semantic palette */
    --tc-success: #059669;
    --tc-success-bg: #ecfdf5;
    --tc-success-border: #a7f3d0;

    --tc-warning: #d97706;
    --tc-warning-bg: #fffbeb;
    --tc-warning-border: #fde68a;

    --tc-danger: #dc2626;
    --tc-danger-bg: #fef2f2;
    --tc-danger-border: #fecaca;

    --tc-info: #2563eb;
    --tc-info-bg: #eff6ff;
    --tc-info-border: #bfdbfe;

    --tc-neutral: #64748b;
    --tc-neutral-bg: #f8fafc;
    --tc-neutral-border: #cbd5e1;

    /* Shape */
    --tc-radius-sm: 0.375rem;
    --tc-radius-md: 0.5rem;
    --tc-radius-lg: 0.75rem;
    --tc-radius-xl: 1rem;

    /* Shadows */
    --tc-shadow-sm: 0 1px 2px rgb(15 41 74 / 0.06);
    --tc-shadow-md: 0 8px 24px rgb(15 41 74 / 0.08);

    /* Layout */
    --tc-page-max-width: 88rem;
    --tc-context-width: 22rem;
  }
}
```

---

# 2\. `02_base.css`

Use this for global app feel: background, typography, links, focus states.

```css
/* app/assets/stylesheets/teamcore/02_base.css */

@layer base {
  html {
    color: var(--tc-text);
    background: var(--tc-bg);
  }

  body {
    @apply antialiased;
    color: var(--tc-text);
    background: var(--tc-bg);
    font-family:
      Inter,
      ui-sans-serif,
      system-ui,
      -apple-system,
      BlinkMacSystemFont,
      "Segoe UI",
      sans-serif;
  }

  a {
    color: var(--tc-secondary);
    text-decoration: none;
  }

  a:hover {
    color: var(--tc-primary);
    text-decoration: underline;
    text-underline-offset: 0.18em;
  }

  :focus-visible {
    outline: 2px solid color-mix(in srgb, var(--tc-secondary) 80%, white);
    outline-offset: 2px;
  }

  ::selection {
    color: var(--tc-primary-dark);
    background: var(--tc-secondary-soft);
  }
}
```

---

# 3\. `03_components.css`

This is the main component layer.

```css
/* app/assets/stylesheets/teamcore/03_components.css */

@layer components {
  /*
    Page shell
  */

  .tc-page {
    @apply mx-auto w-full px-4 py-6 sm:px-6 lg:px-8;
    max-width: var(--tc-page-max-width);
  }

  .tc-page-stack {
    @apply space-y-5;
  }

  .tc-section-stack {
    @apply space-y-4;
  }

  /*
    Record header
  */

  .tc-record-header {
    @apply rounded-xl border p-5 shadow-sm;
    color: white;
    background:
      linear-gradient(
        135deg,
        var(--tc-primary) 0%,
        var(--tc-primary-dark) 100%
      );
    border-color: color-mix(in srgb, var(--tc-primary) 80%, white);
    box-shadow: var(--tc-shadow-md);
  }

  .tc-record-header__top {
    @apply flex flex-col gap-4 md:flex-row md:items-start md:justify-between;
  }

  .tc-record-header__eyebrow {
    @apply text-xs font-semibold uppercase tracking-wide;
    color: color-mix(in srgb, white 74%, var(--tc-secondary-soft));
  }

  .tc-record-header__title {
    @apply mt-1 text-2xl font-semibold tracking-tight sm:text-3xl;
    color: white;
  }

  .tc-record-header__subtitle {
    @apply mt-1 text-sm;
    color: color-mix(in srgb, white 80%, var(--tc-secondary-soft));
  }

  .tc-record-header__badges {
    @apply mt-4 flex flex-wrap gap-2;
  }

  .tc-record-header__actions {
    @apply flex flex-wrap gap-2;
  }

  /*
    Panels
  */

  .tc-panel {
    @apply rounded-xl border bg-white shadow-sm;
    border-color: var(--tc-border);
    box-shadow: var(--tc-shadow-sm);
  }

  .tc-panel--muted {
    background: var(--tc-surface-muted);
  }

  .tc-panel__header {
    @apply flex items-start justify-between gap-4 border-b px-4 py-3;
    border-color: var(--tc-border);
  }

  .tc-panel__title {
    @apply text-sm font-semibold;
    color: var(--tc-text);
  }

  .tc-panel__subtitle {
    @apply mt-0.5 text-xs;
    color: var(--tc-text-muted);
  }

  .tc-panel__body {
    @apply p-4;
  }

  .tc-panel__footer {
    @apply border-t px-4 py-3 text-sm;
    border-color: var(--tc-border);
    background: var(--tc-neutral-bg);
  }

  /*
    Buttons
  */

  .tc-btn {
    @apply inline-flex items-center justify-center rounded-md border px-3 py-2 text-sm font-medium leading-5 transition;
    min-height: 2.25rem;
  }

  .tc-btn:disabled,
  .tc-btn[aria-disabled="true"] {
    @apply cursor-not-allowed opacity-50;
  }

  .tc-btn--primary {
    color: white;
    background: var(--tc-primary);
    border-color: var(--tc-primary);
  }

  .tc-btn--primary:hover {
    color: white;
    background: var(--tc-primary-dark);
    border-color: var(--tc-primary-dark);
    text-decoration: none;
  }

  .tc-btn--secondary {
    color: var(--tc-primary);
    background: white;
    border-color: var(--tc-border-strong);
  }

  .tc-btn--secondary:hover {
    color: var(--tc-primary-dark);
    background: var(--tc-neutral-bg);
    text-decoration: none;
  }

  .tc-btn--teal {
    color: white;
    background: var(--tc-secondary);
    border-color: var(--tc-secondary);
  }

  .tc-btn--teal:hover {
    color: white;
    background: color-mix(in srgb, var(--tc-secondary) 82%, black);
    text-decoration: none;
  }

  .tc-btn--accent {
    color: white;
    background: var(--tc-accent);
    border-color: var(--tc-accent);
  }

  .tc-btn--accent:hover {
    color: white;
    background: color-mix(in srgb, var(--tc-accent) 82%, black);
    text-decoration: none;
  }

  .tc-btn--danger {
    color: white;
    background: var(--tc-danger);
    border-color: var(--tc-danger);
  }

  .tc-btn--danger:hover {
    color: white;
    background: color-mix(in srgb, var(--tc-danger) 84%, black);
    text-decoration: none;
  }

  .tc-btn--quiet {
    color: var(--tc-text-muted);
    background: transparent;
    border-color: transparent;
  }

  .tc-btn--quiet:hover {
    color: var(--tc-primary);
    background: var(--tc-neutral-bg);
    text-decoration: none;
  }

  .tc-action-bar {
    @apply flex flex-wrap items-center gap-2;
  }

  /*
    Badges
  */

  .tc-badge {
    @apply inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium;
  }

  .tc-badge--primary {
    color: var(--tc-primary);
    background: color-mix(in srgb, var(--tc-primary) 8%, white);
    border-color: color-mix(in srgb, var(--tc-primary) 22%, white);
  }

  .tc-badge--secondary {
    color: var(--tc-secondary);
    background: var(--tc-secondary-soft);
    border-color: color-mix(in srgb, var(--tc-secondary) 26%, white);
  }

  .tc-badge--accent {
    color: color-mix(in srgb, var(--tc-accent) 86%, black);
    background: var(--tc-accent-soft);
    border-color: color-mix(in srgb, var(--tc-accent) 28%, white);
  }

  .tc-badge--success,
  .tc-badge--ready,
  .tc-badge--verified,
  .tc-badge--active {
    color: var(--tc-success);
    background: var(--tc-success-bg);
    border-color: var(--tc-success-border);
  }

  .tc-badge--warning,
  .tc-badge--pending,
  .tc-badge--pending-review,
  .tc-badge--expiring-soon {
    color: var(--tc-warning);
    background: var(--tc-warning-bg);
    border-color: var(--tc-warning-border);
  }

  .tc-badge--danger,
  .tc-badge--missing,
  .tc-badge--expired,
  .tc-badge--rejected,
  .tc-badge--blocked,
  .tc-badge--terminated {
    color: var(--tc-danger);
    background: var(--tc-danger-bg);
    border-color: var(--tc-danger-border);
  }

  .tc-badge--info {
    color: var(--tc-info);
    background: var(--tc-info-bg);
    border-color: var(--tc-info-border);
  }

  .tc-badge--neutral,
  .tc-badge--inactive,
  .tc-badge--draft {
    color: var(--tc-neutral);
    background: var(--tc-neutral-bg);
    border-color: var(--tc-neutral-border);
  }

  /*
    Alerts / status strips
  */

  .tc-alert {
    @apply rounded-lg border px-4 py-3 text-sm;
  }

  .tc-alert__title {
    @apply font-semibold;
  }

  .tc-alert__body {
    @apply mt-1;
  }

  .tc-alert--success {
    color: var(--tc-success);
    background: var(--tc-success-bg);
    border-color: var(--tc-success-border);
  }

  .tc-alert--warning {
    color: var(--tc-warning);
    background: var(--tc-warning-bg);
    border-color: var(--tc-warning-border);
  }

  .tc-alert--danger {
    color: var(--tc-danger);
    background: var(--tc-danger-bg);
    border-color: var(--tc-danger-border);
  }

  .tc-alert--info {
    color: var(--tc-info);
    background: var(--tc-info-bg);
    border-color: var(--tc-info-border);
  }

  /*
    Key/value grid
  */

  .tc-kv-grid {
    @apply grid grid-cols-1 gap-x-6 gap-y-3 sm:grid-cols-2;
  }

  .tc-kv-grid--single {
    @apply grid-cols-1;
  }

  .tc-kv {
    @apply min-w-0;
  }

  .tc-kv__key {
    @apply text-xs font-medium uppercase tracking-wide;
    color: var(--tc-text-muted);
  }

  .tc-kv__value {
    @apply mt-1 truncate text-sm font-medium;
    color: var(--tc-text);
  }

  .tc-kv__value--muted {
    color: var(--tc-text-muted);
  }

  /*
    Empty state
  */

  .tc-empty-state {
    @apply rounded-lg border border-dashed px-6 py-8 text-center;
    border-color: var(--tc-border-strong);
    background: var(--tc-neutral-bg);
  }

  .tc-empty-state__title {
    @apply text-sm font-semibold;
    color: var(--tc-text);
  }

  .tc-empty-state__body {
    @apply mt-1 text-sm;
    color: var(--tc-text-muted);
  }

  .tc-empty-state__actions {
    @apply mt-4 flex justify-center gap-2;
  }

  /*
    Timeline
  */

  .tc-timeline {
    @apply space-y-3;
  }

  .tc-timeline__item {
    @apply border-l-2 pl-3 text-sm;
    border-color: var(--tc-border-strong);
  }

  .tc-timeline__item--warning {
    border-color: var(--tc-warning);
  }

  .tc-timeline__item--success {
    border-color: var(--tc-success);
  }

  .tc-timeline__item--danger {
    border-color: var(--tc-danger);
  }

  .tc-timeline__title {
    @apply font-medium;
    color: var(--tc-text);
  }

  .tc-timeline__meta {
    @apply mt-0.5 text-xs;
    color: var(--tc-text-muted);
  }
}
```

---

# 4\. `04_tables.css`

Use this for operational tables, including documents/requirements.

```css
/* app/assets/stylesheets/teamcore/04_tables.css */

@layer components {
  .tc-table-wrap {
    @apply w-full overflow-x-auto rounded-xl border bg-white;
    border-color: var(--tc-border);
  }

  .tc-data-table {
    @apply min-w-full divide-y text-sm;
    divide-color: var(--tc-border);
  }

  .tc-data-table thead {
    background: var(--tc-neutral-bg);
  }

  .tc-data-table th {
    @apply whitespace-nowrap px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide;
    color: var(--tc-text-muted);
  }

  .tc-data-table td {
    @apply whitespace-nowrap px-3 py-2 align-middle;
    color: var(--tc-text);
  }

  .tc-data-table tbody {
    @apply divide-y;
    divide-color: var(--tc-border);
  }

  .tc-data-table tbody tr:hover {
    background: color-mix(in srgb, var(--tc-secondary-soft) 36%, white);
  }

  .tc-data-table__cell-muted {
    color: var(--tc-text-muted);
  }

  .tc-data-table__cell-actions {
    @apply text-right;
  }

  .tc-data-table__number {
    @apply text-right tabular-nums;
  }

  .tc-data-table__primary {
    @apply font-medium;
    color: var(--tc-text);
  }

  .tc-data-table__secondary {
    @apply mt-0.5 text-xs;
    color: var(--tc-text-muted);
  }

  .tc-row--warning {
    background: color-mix(in srgb, var(--tc-warning-bg) 70%, white);
  }

  .tc-row--danger {
    background: color-mix(in srgb, var(--tc-danger-bg) 76%, white);
  }

  .tc-row--success {
    background: color-mix(in srgb, var(--tc-success-bg) 64%, white);
  }
}
```

---

# 5\. `05_forms.css`

Use this for TeamCORE form sections and simple Rails form fields.

```css
/* app/assets/stylesheets/teamcore/05_forms.css */

@layer components {
  .tc-form {
    @apply space-y-6;
  }

  .tc-form-section {
    @apply rounded-xl border bg-white p-4 shadow-sm;
    border-color: var(--tc-border);
    box-shadow: var(--tc-shadow-sm);
  }

  .tc-form-section__header {
    @apply mb-4 border-b pb-3;
    border-color: var(--tc-border);
  }

  .tc-form-section__title {
    @apply text-sm font-semibold;
    color: var(--tc-text);
  }

  .tc-form-section__description {
    @apply mt-1 text-sm;
    color: var(--tc-text-muted);
  }

  .tc-form-grid {
    @apply grid grid-cols-1 gap-4 sm:grid-cols-2;
  }

  .tc-field {
    @apply space-y-1;
  }

  .tc-label {
    @apply block text-sm font-medium;
    color: var(--tc-text);
  }

  .tc-hint {
    @apply text-xs;
    color: var(--tc-text-muted);
  }

  .tc-input,
  .tc-select,
  .tc-textarea {
    @apply block w-full rounded-md border px-3 py-2 text-sm shadow-sm;
    color: var(--tc-text);
    background: white;
    border-color: var(--tc-border-strong);
  }

  .tc-input:focus,
  .tc-select:focus,
  .tc-textarea:focus {
    border-color: var(--tc-secondary);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--tc-secondary) 18%, transparent);
    outline: none;
  }

  .tc-input[disabled],
  .tc-select[disabled],
  .tc-textarea[disabled] {
    @apply cursor-not-allowed;
    color: var(--tc-text-muted);
    background: var(--tc-neutral-bg);
  }

  .tc-field-error {
    @apply text-xs font-medium;
    color: var(--tc-danger);
  }

  .tc-input--error,
  .tc-select--error,
  .tc-textarea--error {
    border-color: var(--tc-danger);
  }

  .tc-form-actions {
    @apply flex flex-wrap items-center justify-end gap-2 border-t pt-4;
    border-color: var(--tc-border);
  }
}
```

---

# 6\. `06_workspaces.css`

This is where Team360-specific layout belongs.

```css
/* app/assets/stylesheets/teamcore/06_workspaces.css */

@layer components {
  /*
    General workspace shell
  */

  .tc-workspace {
    @apply min-h-screen;
    background: var(--tc-bg);
  }

  .tc-workspace__body {
    @apply mx-auto w-full px-4 py-6 sm:px-6 lg:px-8;
    max-width: var(--tc-page-max-width);
  }

  /*
    Two-column record layout:
    left = authoritative story
    right = context / alerts
  */

  .tc-record-layout {
    @apply grid grid-cols-1 gap-5 lg:grid-cols-[minmax(0,1fr)_22rem];
  }

  .tc-record-main {
    @apply min-w-0 space-y-5;
  }

  .tc-record-context {
    @apply min-w-0 space-y-5;
  }

  @media (min-width: 1024px) {
    .tc-record-context--sticky {
      @apply sticky top-5 self-start;
    }
  }

  /*
    Team360-specific aliases.
    These let Team360 markup read clearly without forking the design language.
  */

  .tc-team360 {
    @apply space-y-5;
  }

  .tc-team360__summary-grid {
    @apply grid grid-cols-1 gap-5 md:grid-cols-2;
  }

  .tc-team360__readiness-score {
    @apply flex items-start justify-between gap-4;
  }

  .tc-team360__readiness-label {
    @apply text-sm font-medium;
    color: var(--tc-text-muted);
  }

  .tc-team360__readiness-value {
    @apply mt-1 text-2xl font-semibold tracking-tight;
    color: var(--tc-text);
  }

  .tc-team360__metric-row {
    @apply mt-4 grid grid-cols-3 gap-3;
  }

  .tc-team360__metric {
    @apply rounded-lg border p-3 text-center;
    border-color: var(--tc-border);
    background: var(--tc-neutral-bg);
  }

  .tc-team360__metric-value {
    @apply text-lg font-semibold tabular-nums;
    color: var(--tc-text);
  }

  .tc-team360__metric-label {
    @apply mt-0.5 text-xs;
    color: var(--tc-text-muted);
  }

  /*
    Optional left navigation layout for later.
  */

  .tc-sidebar-layout {
    @apply grid grid-cols-1 gap-5 lg:grid-cols-[16rem_minmax(0,1fr)];
  }

  .tc-side-nav {
    @apply rounded-xl border bg-white p-2 shadow-sm;
    border-color: var(--tc-border);
  }

  .tc-side-nav__link {
    @apply block rounded-md px-3 py-2 text-sm font-medium;
    color: var(--tc-text-muted);
  }

  .tc-side-nav__link:hover {
    color: var(--tc-primary);
    background: var(--tc-neutral-bg);
    text-decoration: none;
  }

  .tc-side-nav__link[aria-current="page"],
  .tc-side-nav__link--active {
    color: var(--tc-secondary);
    background: var(--tc-secondary-soft);
  }
}
```

---

# Example Team360 markup using these classes

```
<div class="tc-workspace">
  <main class="tc-workspace__body">
    <div class="tc-team360">
      <header class="tc-record-header">
        <div class="tc-record-header__top">
          <div>
            <div class="tc-record-header__eyebrow">Team360</div>
            <h1 class="tc-record-header__title">Jane Smith</h1>
            <p class="tc-record-header__subtitle">
              Senior Travel Advisor · Retail Sales · Detroit Office
            </p>

            <div class="tc-record-header__badges">
              <span class="tc-badge tc-badge--active">Active</span>
              <span class="tc-badge tc-badge--primary">Employee</span>
              <span class="tc-badge tc-badge--ready">Ready to Work</span>
            </div>
          </div>

          <div class="tc-record-header__actions">
            <%= link_to "Edit Profile", "#", class: "tc-btn tc-btn--secondary" %>
            <%= link_to "Add Document", "#", class: "tc-btn tc-btn--teal" %>
            <%= link_to "Assign Position", "#", class: "tc-btn tc-btn--primary" %>
          </div>
        </div>
      </header>

      <div class="tc-record-layout">
        <section class="tc-record-main">
          <div class="tc-team360__summary-grid">
            <section class="tc-panel">
              <div class="tc-panel__header">
                <div>
                  <h2 class="tc-panel__title">Readiness</h2>
                  <p class="tc-panel__subtitle">Current activation status</p>
                </div>
                <span class="tc-badge tc-badge--ready">Ready</span>
              </div>

              <div class="tc-panel__body">
                <div class="tc-team360__readiness-score">
                  <div>
                    <div class="tc-team360__readiness-label">Overall Status</div>
                    <div class="tc-team360__readiness-value">Ready to Work</div>
                  </div>
                </div>

                <div class="tc-team360__metric-row">
                  <div class="tc-team360__metric">
                    <div class="tc-team360__metric-value">0</div>
                    <div class="tc-team360__metric-label">Missing</div>
                  </div>
                  <div class="tc-team360__metric">
                    <div class="tc-team360__metric-value">0</div>
                    <div class="tc-team360__metric-label">Pending</div>
                  </div>
                  <div class="tc-team360__metric">
                    <div class="tc-team360__metric-value">1</div>
                    <div class="tc-team360__metric-label">Expiring</div>
                  </div>
                </div>
              </div>
            </section>

            <section class="tc-panel">
              <div class="tc-panel__header">
                <h2 class="tc-panel__title">Current Engagement</h2>
              </div>
              <div class="tc-panel__body">
                <dl class="tc-kv-grid">
                  <div class="tc-kv">
                    <dt class="tc-kv__key">Type</dt>
                    <dd class="tc-kv__value">Employee</dd>
                  </div>
                  <div class="tc-kv">
                    <dt class="tc-kv__key">Start Date</dt>
                    <dd class="tc-kv__value">Jan 1, 2026</dd>
                  </div>
                  <div class="tc-kv">
                    <dt class="tc-kv__key">Operating Unit</dt>
                    <dd class="tc-kv__value">Retail Sales</dd>
                  </div>
                  <div class="tc-kv">
                    <dt class="tc-kv__key">Manager</dt>
                    <dd class="tc-kv__value">Sarah Admin</dd>
                  </div>
                </dl>
              </div>
            </section>
          </div>

          <section class="tc-panel">
            <div class="tc-panel__header">
              <div>
                <h2 class="tc-panel__title">Documents & Requirements</h2>
                <p class="tc-panel__subtitle">Requirement satisfaction and document review status</p>
              </div>
            </div>

            <div class="tc-table-wrap">
              <table class="tc-data-table">
                <thead>
                  <tr>
                    <th>Requirement</th>
                    <th>Status</th>
                    <th>Record</th>
                    <th>Expiration</th>
                    <th>Review</th>
                    <th class="tc-data-table__cell-actions">Action</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="tc-data-table__primary">W-4</td>
                    <td><span class="tc-badge tc-badge--success">Satisfied</span></td>
                    <td>w4.pdf</td>
                    <td class="tc-data-table__cell-muted">—</td>
                    <td><span class="tc-badge tc-badge--verified">Verified</span></td>
                    <td class="tc-data-table__cell-actions">
                      <%= link_to "View", "#", class: "tc-btn tc-btn--quiet" %>
                    </td>
                  </tr>
                  <tr class="tc-row--warning">
                    <td class="tc-data-table__primary">E&O Insurance</td>
                    <td><span class="tc-badge tc-badge--expiring-soon">Expiring Soon</span></td>
                    <td>policy.pdf</td>
                    <td>Jun 15, 2026</td>
                    <td><span class="tc-badge tc-badge--verified">Verified</span></td>
                    <td class="tc-data-table__cell-actions">
                      <%= link_to "Replace", "#", class: "tc-btn tc-btn--secondary" %>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </section>

        <aside class="tc-record-context tc-record-context--sticky">
          <section class="tc-panel">
            <div class="tc-panel__header">
              <h2 class="tc-panel__title">Quick Facts</h2>
            </div>
            <div class="tc-panel__body">
              <dl class="tc-kv-grid tc-kv-grid--single">
                <div class="tc-kv">
                  <dt class="tc-kv__key">Team Member ID</dt>
                  <dd class="tc-kv__value">TM-000123</dd>
                </div>
                <div class="tc-kv">
                  <dt class="tc-kv__key">Primary Contact</dt>
                  <dd class="tc-kv__value">jane@example.com</dd>
                </div>
                <div class="tc-kv">
                  <dt class="tc-kv__key">Status</dt>
                  <dd class="tc-kv__value">Active</dd>
                </div>
              </dl>
            </div>
          </section>

          <section class="tc-alert tc-alert--warning">
            <div class="tc-alert__title">Attention Needed</div>
            <div class="tc-alert__body">
              E&O Insurance expires in 31 days.
            </div>
          </section>

          <section class="tc-panel">
            <div class="tc-panel__header">
              <h2 class="tc-panel__title">Recent Activity</h2>
            </div>
            <div class="tc-panel__body">
              <ol class="tc-timeline">
                <li class="tc-timeline__item tc-timeline__item--warning">
                  <div class="tc-timeline__title">E&O warning generated</div>
                  <div class="tc-timeline__meta">May 15, 2026</div>
                </li>
                <li class="tc-timeline__item tc-timeline__item--success">
                  <div class="tc-timeline__title">Background check verified</div>
                  <div class="tc-timeline__meta">May 10, 2026 · Compliance Admin</div>
                </li>
              </ol>
            </div>
          </section>
        </aside>
      </div>
    </div>
  </main>
</div>
```

---

# Usage guidance

## Button color discipline

Use:

```
Primary workflow action:  tc-btn--primary
Secondary action:         tc-btn--secondary
Document/action link:     tc-btn--teal
Rare warm highlight:      tc-btn--accent
Destructive action:       tc-btn--danger
Low-emphasis action:      tc-btn--quiet
```

I would avoid using the terracotta accent as the default CTA. It should be rare.

## Badge/status discipline

Use semantic classes for meaning:

```
Ready / verified / active:       tc-badge--success or tc-badge--ready
Pending / expiring soon:         tc-badge--warning or tc-badge--expiring-soon
Missing / expired / rejected:    tc-badge--danger or specific aliases
Draft / inactive:                tc-badge--neutral
Employee / contractor type:      tc-badge--primary or tc-badge--secondary
```

## File split recommendation

Start with this split now. It is small enough to manage, but already gives you strong boundaries:

```
01_tokens.css       colors, radii, shadows
02_base.css         global page/body/link/focus behavior
03_components.css   panels, buttons, badges, alerts, key/value grids
04_tables.css       operational tables
05_forms.css        form sections and fields
06_workspaces.css   Team360 and workspace layouts
```

