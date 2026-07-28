---
name: librarian
description: This skill should be used when the user asks to "audit docs", "check documentation health", "find stale docs", "sync INDEX.md", "update front matter", "run doc lint", "clean up documentation", "organize the docs", "find orphaned docs", or asks for doc housekeeping in general.
---

# Librarian Skill

Maintains `docs/` health: front matter compliance, INDEX.md accuracy, stale detection, and cross-reference integrity.

## Conventions Reference

All doc conventions (front matter schema, status lifecycle, marker standards) are in `docs/CONVENTIONS.md`. Refer to it for authoritative definitions.

## Core Workflows

### 1. Run a Full Documentation Audit

Run the audit script for a comprehensive check:

```bash
.opencode/skills/librarian/scripts/lint-docs.sh
```

This checks:
- Front matter presence and required fields
- Stale docs (`reviewed` > 12 months or `status: stale`)
- INDEX.md entries pointing to missing files
- Files in `docs/` not listed in INDEX.md
- Marker consistency (⏳ 🟡 ✅ ⏭️ ❌)
- BD issue cross-reference integrity

### 2. Fix Front Matter on a Single File

Add or update front matter on a file. Required: `title`, `status`, `reviewed`.

```yaml
---
title: Descriptive Title
status: current
reviewed: 2026-07-28
---
```

### 3. Sync INDEX.md

When docs are added, moved, or renamed:

1. Read the current `docs/INDEX.md`.
2. Scan `docs/` with `find docs/ -name '*.md'` to discover all files.
3. Cross-reference against INDEX.md sections.
4. Add missing entries, remove entries for missing files.
5. Read front matter from each doc to determine the title and an annotation (e.g. status badge).

An INDEX.md entry follows this pattern:

```markdown
- **[filename.md](./path/to/filename.md)**: Brief description or front matter title
```

### 4. Resolve a Stale Doc

When a doc is `status: stale`:

1. Read the doc and compare claims against the codebase.
2. Mark confirmed items with ✅.
3. Remove claims that no longer apply.
4. Update `reviewed` date and set `status: current` (or `archived` if no longer relevant).
5. If the doc is fully superseded, set `superseded_by` and `status: archived`.

### 5. Move a Doc

When a doc needs to move directories:

1. `git mv <source> <dest>`
2. Update its front matter if the move changes context.
3. Update `docs/INDEX.md` with the new path.
4. Search the codebase for internal links to the old path and update them.
5. Commit the move and link updates together.

### 6. Check BD Issue Cross-References

Scan for documents that reference BD issues (via tables or `bd_issues` in front matter) and verify those issues still exist:

```bash
find docs/ -name "*.md" -exec grep -l "soralia-village-" {} \;
```

## Reference Files

- **`docs/CONVENTIONS.md`** — front matter schema, status lifecycle, marker standards, INDEX.md rules
- **`references/patterns.md`** — before/after examples of front matter conversion

## Scripts

- **`scripts/lint-docs.sh`** — automated doc health audit. Run this as the primary entry point for any doc health check.
