# Front Matter Conversion Patterns

## Before / After

### Minimal (report-like doc)

```yaml
# Before — no front matter
# After:
---
title: Events System Review
status: current
reviewed: 2026-07-22
tags: [events, audit, report]
audience: developer
bd_issues: [tepl, e4fy, f1k7]
---
```

### Pending-work index

```yaml
---
title: Pending Work Items — Priority Assessment
status: current
reviewed: 2026-07-28
tags: [tracking, priorities, todos]
audience: all
---
```

### Ad-hoc findings document

```yaml
---
title: CMS Implementation Audit
status: current
reviewed: 2026-07-20
tags: [cms, audit, content, media]
audience: developer
---
```

### Stale / superseded doc

```yaml
---
title: Onboarding Refactor (Early Draft)
status: archived
reviewed: 2026-06-01
tags: [onboarding, legacy]
superseded_by: docs/advisories/ADVISORY-031.md
---
```

### Draft / work in progress

```yaml
---
title: Mobile Architecture Proposal
status: draft
reviewed: 2026-07-15
tags: [mobile, architecture]
audience: developer
---
```

## INDEX.md Entry Patterns

### Single file with description

```markdown
- **[EVENT_REPORT.md](./reports/EVENT_REPORT.md)**: Events system review — 17 issues, 13/17 resolved
```

### Subsection header

```markdown
---
## 📊 [Reports](./reports/)
---
```

### Grouped entries

```markdown
- **[BOOKINGS_AUDIT.md](./audits/BOOKINGS_AUDIT.md)**: Bookings subsystem audit
- **[SETTINGS_AUDIT.md](./audits/SETTINGS_AUDIT.md)**: Settings infrastructure audit
```

## BD Issue Cross-Reference Patterns

### In front matter

```yaml
bd_issues: [tepl, e4fy, f1k7]
```

### In markdown tables

```markdown
| # | Issue | BD |
| --- | --- | --- |
| 11 | Recurring events support | `soralia-village-tepl` |
```
