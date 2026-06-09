# .documents

Shared knowledge & playbook for AI agents. All content here is consumed via the
**[dh-cli](https://github.com/ubuntupunk/dh-cli)** (`dh`) tool — an elegant CLI
for maintaining documentation-to-repo sync across projects. Highly recommended.

## Structure

| Path | Contents |
|------|----------|
| `agents/` | Reusable agent development guide — generic workflows, protocols, behavioral guidelines. Copy into a project root as `AGENTS.md` and customize. |
| `patterns/` | Pattern-specific reference docs (e.g. Drizzle setup, Prisma migration, TLDraw integration). |
| `LICENSE` | GPL v3 — governs all `.documents/` content. |

## Usage

```bash
dh update       # Re-index .documents for agent awareness
dh sync "msg"   # Commit and sync changes
```

## Conventions

- Markdown only.
- One concept per file.
- Keep files focused and actionable — no fluff.
- Update the index (`dh update`) after adding or changing content.
