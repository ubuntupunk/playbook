# Agent Development Guide (Generic)

> **IMPORTANT:** This file contains reusable agent workflows, protocols, and best practices.
> Copy into your project root as `AGENTS.md` and customize the project-specific sections
> (tech stack, build commands, issue tracker state, directory structure, etc.).

## 🚀 Build/Lint/Test Commands

### Development

- **Start dev server**: `pnpm dev` (or project-specific command)
- **Build**: `pnpm build` (or project-specific command)
- **Type check**: `pnpm type-check` or `tsc --noEmit`

### Code Quality

- **Lint**: `pnpm lint`
- **Lint fix**: `pnpm lint:fix`

### Testing

- **Run all tests**: `pnpm test` or `vitest run`
- **Watch mode**: `pnpm test:watch` or `vitest`
- **Coverage**: `pnpm test:coverage` or `vitest run --coverage`
- **Run single test**: `vitest run <path/to/test-file>`

### Database (if applicable)

- **Generate types**: `pnpm prisma generate` / `prisma generate`
- **Push schema**: `pnpm db:push` / `prisma db push`
- **Migrate**: `pnpm db:migrate` / `prisma migrate dev`
- **Studio**: `pnpm db:studio` / `drizzle-kit studio`

---

## 📋 Code Style Guidelines

### TypeScript & Type Safety

- Strict mode enabled — no `any`
- Type declarations required for all variables, parameters, return values
- Avoid `any` — create proper types/interfaces
- Zod for runtime type checking and inference

### File Naming

| Entity           | Convention      | Example              |
| ---------------- | --------------- | -------------------- |
| Files            | kebab-case      | `user-profile.tsx`   |
| Components       | PascalCase      | `StartupCard.tsx`    |
| Functions        | camelCase       | `createConnection()` |
| Constants        | SCREAMING_SNAKE | `MAX_RETRY_ATTEMPTS` |
| Types/Interfaces | PascalCase      | `FundingRound`       |

**Exception**: Next.js reserved files (`page.tsx`, `layout.tsx`, `route.ts`)

### Directory Structure (Example — customize per project)

```
src/
├── app/                  # Routing ONLY (Next.js App Router)
├── features/             # Domain vertical slices
│   └── feature/
│       ├── api/
│       ├── components/
│       ├── constants/
│       ├── hooks/
│       └── schemas/
├── shared/               # Cross-feature shared code
│   ├── api/
│   ├── config/
│   ├── hooks/
│   ├── lib/
│   └── ui/
├── server/               # Server-side services
│   ├── db/
│   └── services/
└── lib/                  # Core libraries
```

### Imports & Structure

- Named exports preferred over defaults
- One export per file (mandatory)
- Path aliases for source directory imports
- Group imports: external libs first, then internal
- NO business logic in routing layer

### Layer Rules (Feature-Sliced Design)

1. Routing layer is exclusively for routing (page.tsx, layout.tsx, route.ts only)
   - NO components, utilities, or business logic
2. Only server layer accesses the database
3. Features NEVER import from other features
4. Shared layer NEVER imports from features

### FSD Architecture Enforcement

Enforce Feature-Sliced Design boundaries with two complementary tools:

| Tool        | Scope                                                                 | Where it runs       |
| ----------- | --------------------------------------------------------------------- | ------------------- |
| **ESLint**  | Deep imports that bypass hierarchy                                    | Editor + pre-commit |
| **Steiger** | Layer hierarchy, public API sidestep, slice hygiene, naming typos     | Pre-commit + CI     |

**Commands:**
```bash
pnpm fsd:check              # Run Steiger on ./src
bash scripts/steiger-staged.sh  # Run Steiger only when FSD files are staged
```

**Why two tools?** ESLint gives inline editor feedback on deep imports; Steiger gives architectural feedback that ESLint cannot express. Belt and suspenders.

### Logging

- Use structured logging (JSON in production, pretty in development)
- Use child loggers for component context

### Documentation (MANDATORY)

- **JSDoc required**: ALL public functions, components, classes
- Complete coverage: @param, @returns, @throws, @example
- Examples required for complex functions
- Components must document props and return type

### Error Handling

- Try/catch in all async operations
- User-friendly messages (convert technical errors)
- Client-side validation (Zod) + server-side validation
- Standardized error format:
  ```typescript
  { error: { code: "ERROR_CODE", message: "Human readable message" } }
  ```

### Best Practices

- No hardcoded values — use constants/config files
- Security: input sanitization, auth, authorization
- Performance: lazy loading, image optimization, query optimization
- Accessibility: ARIA attributes, keyboard navigation, WCAG compliance

---

## Migration Status & Ad-Hoc SQL

**Formal migrations are tracked by tooling — never rename files.**

Both Prisma and Drizzle maintain their own state and will break if filenames
are changed after a migration is applied. If using a different migration tool,
the same principle applies.

**Ad-hoc SQL scripts** (one-off `.sql` files not under formal migration
directories) MAY use a `.DONE` marker once manually run:

```bash
# After running a one-off SQL against the dev DB:
mv scripts/sql/20260605-fix-stale-index.sql scripts/sql/20260605-fix-stale-index.DONE.sql
git add -A
git commit -m "chore(sql): mark 20260605-fix-stale-index as run (DONE)"
```

The `.DONE` suffix is a local convention for visibility; it is **not** understood
by any migration tool. Do not apply it to formal migrations.

---

## Testing Requirements

- **Coverage thresholds**: 70% minimum (statements, branches, functions, lines)
- **Test structure**: Arrange-Act-Assert pattern
- **Mock strategy**: Comprehensive mocking for external dependencies
- **Test types**: Unit, integration, and E2E tests required

---

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Drop session-end stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing — that leaves work stranded locally
- NEVER say "ready to push when you are" — YOU must push
- If push fails, resolve and retry until it succeeds

---

## Documentation Practices

### Architectural Decisions

**When making architectural decisions, ALWAYS update ADR.md:**

- **Major technology choices** (frameworks, libraries, patterns)
- **Significant refactoring** that changes system structure
- **Performance or scalability decisions**
- **Security architecture changes**
- **Breaking API changes**
- **Migration decisions**

**ADR Requirements:**

- Use the established ADR template
- Include context, decision, alternatives considered, and consequences
- Document both positive and negative impacts
- Number ADRs sequentially (ADR-001, ADR-002, etc.)
- Commit ADR updates with code changes

**When to skip ADR:**

- Routine implementation details
- Minor configuration changes
- Bug fixes without architectural impact
- Documentation updates
- Code style or formatting changes

---

## 📋 Issue Tracking: BD vs GSD

This project uses TWO tracking systems for different purposes. Do NOT confuse them.

### BD Issues (Non-Linear Work)

Use `bd` for:

- Bug fixes
- Quick patches
- Small feature additions
- Research tasks
- Exploratory work
- Anything that doesn't fit a phase structure

```bash
bd list           # Show all issues
bd create "Title" # Create new issue
bd get <id>       # Get issue details
bd close <id>     # Close completed issue
bd sync           # Sync with git
```

**Limitations:** BD lacks validation, dependency tracking, and phase structure.

### GSD Phase Plans (Major Overhaul)

Use GSD workflow for:

- Large architectural changes
- Multi-step migrations
- Phase-based work with dependencies
- Work requiring validation and checkpoints

```bash
/gsd-plan-phase     # Plan a phase
/gsd-discuss-phase  # Discuss phase context
/gsd-execute-phase  # Execute phase plans
/gsd-health         # Validate .planning/ directory
```

**Structure:** `.planning/` directory with ROADMAP.md, phases/, PLAN.md files.

### When to Use Which

| Work Type                            | Use |
| ------------------------------------ | --- |
| Fix a bug                            | BD  |
| Add a small feature                  | BD  |
| Research a library                   | BD  |
| Major migration                      | GSD |
| Multi-phase refactor                 | GSD |
| Architecture changes                 | GSD |

### Setting Up Per Project

1. Run `bd init` in the project root
2. Create `.planning/` directory with ROADMAP.md
3. Set up issue tracking for current milestone
4. Configure `~/.config/worktrunk/config.toml` for worktrees (see below)

**IMPORTANT:** When working on a GSD phase, close the related BD issue when the phase completes.
When opening a bd issue, update .planning/BD.md so GSD is aware of the issue.

### Git Worktree Isolation (MANDATORY)

All GSD phase execution MUST happen inside a dedicated **git worktree** to prevent
collisions with the working tree. Never execute a GSD phase directly in the main
working directory.

This project uses **[Worktrunk](https://worktrunk.dev/)** (`wt`) to manage worktrees,
configured via `~/.config/worktrunk/config.toml`:

```toml
worktree-path = "../worktrees/{{ branch | sanitize }}"
```

**Worktree lifecycle per phase:**

```bash
# 1. Create and switch to a worktree for the phase
GSD_PHASE="phase-N-name"
wt switch --create ${GSD_PHASE}

# 2. Copy .env and local config into the worktree
cp .env ../worktrees/${GSD_PHASE}/.env

# 3. Run all GSD commands inside the worktree directory

# 4. After phase completes and is merged/pushed, clean up
wt remove ${GSD_PHASE}

# 5. Delete the merged phase branch (local + remote) once on dev
git branch -d ${GSD_PHASE}
git push origin --delete ${GSD_PHASE}

# 6. Confirm no stale markers remain
wt list
```

**Rules:**
- **NEVER use `git stash` in a worktree** — stash is global and shared across all worktrees. Use WIP commits instead: `git commit -m "wip: ..."` to checkpoint, `git reset HEAD~1` to undo.
- **One worktree per phase** — never reuse across phases
- **Branch name must match the worktree directory name**
- **Copy `.env` immediately** after creating the worktree
- **Run quality gates inside the worktree** before merging back
- **NEVER delete `dev`, `main`, or any non-phase branch**
- **Never delete a worktree directory manually** — always use `wt remove`
- **List active worktrees:** `wt list`

### Stash Ownership Protocol (Required)

`git stash` is global and has no scope. **Every stash MUST carry an `owner=`
field in its message** so a human (or another agent) can resolve it later.

```bash
git stash push -m "owner=<id>:<intent>:<expiry>"
```

| Field      | Required | Meaning                                                                                   |
| ---------- | -------- | ----------------------------------------------------------------------------------------- |
| `owner=`   | yes      | Agent id (e.g., `claude`, `claude/abc123`), human name, or `human:<name>`                 |
| `<intent>` | yes      | One-line description — what work is parked and why                                        |
| `<expiry>` | yes      | `session-end` (drop before next session), `manual` (keep until reviewed), or `YYYY-MM-DD` |

**Examples:**
```bash
git stash push -m "owner=claude:phase-48-preflight stash:session-end"
git stash push -m "owner=claude:hotfix-WIP for BD-1234:manual"
git stash push -m "owner=human:marcus:experiment on tailwind plugin:2026-07-01"
```

**Rules:**
- A stash message without `owner=` is a protocol violation. Drop or rewrite it.
- Stashes with `expiry=session-end` MUST be dropped (or promoted to a WIP commit on a phase branch) before ending the session.
- Stashes with `expiry=manual` MUST be reviewed at the next milestone boundary.
- `git stash drop` requires the owner to have signed off (or be the same agent).

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## ISR & Caching (Next.js Example)

### Core Principles

- **Maximize static content**: Prefer ISR over SSR to reduce serverless invocations
- **Aggressive caching**: Use `unstable_cache` with tags for intelligent cache invalidation
- **On-demand revalidation**: Immediately update caches when data changes
- **Streaming responses**: Use Suspense for progressive loading

### ISR Implementation

- Use `unstable_cache` for data fetching with cache tags:

  ```typescript
  import { unstable_cache } from 'next/cache';

  export const getData = unstable_cache(
    async () => fetch('/api/data'),
    ['data-key'],
    { revalidate: 300, tags: ['data-tag'] },
  );
  ```

- **Set appropriate revalidation times**:
  - Static data (rarely changes): 10 minutes (600s)
  - User-specific data: 2-5 minutes (120-300s)
  - Real-time data: 30-60 seconds (30-60s)

- **On-demand revalidation** after mutations:
  ```typescript
  import { revalidatePath, revalidateTag } from 'next/cache';
  revalidatePath('/dashboard');
  revalidateTag('data-tag');
  ```

### API Route Optimization

- Add `maxDuration` to prevent runaway functions: `export const maxDuration = 8;`
- Use Cache-Control headers for additional caching:

  ```typescript
  headers: {
    'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600'
  }
  ```

### Component Patterns

- Use Suspense for streaming: `<Suspense fallback={<Skeleton />}>`
- Wrap major page components with `ErrorBoundary`
- Implement proper loading states

---

# DocHub

Use `dh update` or `dh sync "message"`.
All shared knowledge & playbook lives in `./.documents/`.
