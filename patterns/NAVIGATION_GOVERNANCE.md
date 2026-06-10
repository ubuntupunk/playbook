# Navigation Governance — Blueprint

A generic navigation governance framework for multi-section applications. Adopt this to prevent navigation inflation, maintain usability as modules grow, and create predictable user experiences.

---

## Core Philosophy

### Navigation Represents User Journeys — Not System Features

A feature existing in the platform does NOT automatically justify placement in:
- sidebar
- bottom bar
- burger menu
- permanent visibility

Navigation must prioritize:
1. frequency
2. importance
3. user intent
4. discoverability
5. simplicity

---

## Navigation Layers

The platform is divided into navigation domains:

### 1. Public Navigation

**Audience:** Visitors, unauthenticated users  
**Characteristics:** Minimal, stable, low churn, brand-focused  
**Max visible items:** 4–6 (including any dropdown triggers)

Typical items: Home, Directory, Services, Resources, {Feature A | Feature B}, More

Rules:
- MUST be globally relevant, serve most visitors, remain stable
- MUST NOT expose operational workflows, internal tooling, or role-specific functionality

### 2. Community Navigation

**Audience:** Authenticated members, participants  
**Placement:** More dropdown, contextual cards, dashboard widgets  
**Examples:** Groups, News, Surveys, Events, Campaigns

Rules:
- SHOULD appear contextually (feeds, cards, widgets)
- SHOULD NOT inflate primary navigation

### 3. Workspace Navigation

**Audience:** Authenticated users  
**Placement:** Dashboard sidebar, mobile bottom bar, avatar dropdown  
**Examples:** Dashboard, Messages, Bookings, Maintenance, Notifications

Rules:
- User-scoped
- MUST NOT appear in public navigation
- MUST NOT duplicate community navigation

### 4. Administrative Navigation

**Audience:** Moderators, admins, staff, operators  
**Placement:** Admin sidebar, protected routes, role-gated menus  
**Examples:** User Management, Content, Settings, Analytics, Moderation

Rules:
- MUST remain isolated from public UX
- MUST be role-protected
- MUST NOT appear in public navigation

### 5. Footer Navigation

**Audience:** Everyone  
**Purpose:** Secondary — legal, utility, reference links  
**Structure:** Two tiers — content columns (upper) + legal/utility (lower)

Rules:
- MUST be accessible from every page
- MUST NOT introduce new feature discovery paths
- Reference layer, not discovery layer

---

## Primary Navigation Standards

### Sidebar Navigation (Desktop)

Max visible items: 5 (for mobile compatibility — see below)

Approved structure:
```
Home
Services
Community
Messages
Admin
```

### Mobile Bottom Bar

Max visible items: 5

Overflow behavior:
- Items beyond 5 are hidden with a console warning
- Future: "More" overflow sheet replaces 5th slot when needed

### Burger Menu (Mobile)

The burger menu MUST NOT duplicate desktop navigation. Organize by category:

```
Explore         ← Public-facing discovery
Community      ← Participation features
My Space       ← User-specific tools
Administration ← Role-gated (visible only to admins)
```

### Feature Discovery Hierarchy

| Feature Type | Preferred Surface |
|---|---|
| Operational tasks | Dashboard widgets |
| Surveys/polls | Notifications, banners |
| Campaigns | Promotion cards |
| News | Feed |
| Messages | Inbox icon / badge |
| Dashboard | Primary workspace |
| Community | Community section |

---

## Navigation Admission Criteria

Before adding ANY new permanent navigation item, answer these questions:

### Qualification Checklist

1. **Frequency** — Will most users access this weekly?
2. **Breadth** — Is this relevant to most users?
3. **Stability** — Will this feature exist long-term?
4. **Discoverability** — Can this feature be discovered contextually instead?
5. **Redundancy** — Does another surface already expose it?
6. **User Intent** — Does this represent a primary user journey?

### Dashboard Tab / Sub-Domain Admission

A new tab or sub-domain MUST:

1. Represent a distinct user journey — not a subset of an existing one
2. Have dedicated widgets or pages that belong exclusively to it
3. Justify separation — cannot logically merge into an existing tab without cognitive overload
4. Serve the appropriate audience (authenticated users for workspace, admin roles for admin)

### Rejection Criteria

A feature MUST NOT become a permanent nav item if:
- it is role-specific (use role gating instead of removal)
- it is seasonal or temporary
- it is campaign-based
- it duplicates dashboard functionality
- it has low engagement
- it is operational/internal
- it is tenant/customer-specific only

---

## Role-Based Navigation

Navigation MUST be role-aware.

| Role | Visible Areas |
|---|---|
| Visitor | Public Navigation only |
| Authenticated User | Public + Community + Workspace |
| Moderator | Authenticated User + Moderation tools |
| Administrator | Full access |

Implementation pattern:

```typescript
// Role check function
function getVisibleSpaces(role: string, flags: FeatureFlags): SpaceDefinition[] {
  const isAdmin = ADMIN_ROLES.includes(normalizeRole(role));

  return ALL_SPACES.filter(space => {
    // Admin-only spaces
    if (space.minimumRole === 'admin' && !isAdmin) return false;
    // Core spaces always visible
    if (space.isCore) return true;
    // Flag-gated spaces
    if (space.requiredFlag) return flags[space.requiredFlag] !== false;
    // Complex gating (e.g. hide when ALL sub-features are off)
    if (space.complexGate) return evaluateComplexGate(space, flags);
    return true;
  });
}
```

---

## Space Definition Model

The canonical space model used by the ChromeLauncher, SpaceLauncher, and MobileLauncher blueprints:

```typescript
interface SpaceDefinition {
  id: string;                    // URL slug and registry key
  href: string;                  // Canonical URL
  labelKey: string;              // i18n key for display name
  icon: LucideIcon;              // Icon component
  isCore: boolean;               // Always visible when true
  requiredFlag?: string;         // Feature flag key for gating
  minimumRole?: string;          // 'admin' for admin-only spaces
  complexGate?: {                // Optional complex visibility logic
    type: 'any-of' | 'all-of';
    flags: string[];
  };
  widgetIds: string[];           // Widget/page IDs belonging to this space
}
```

---

## Anti-Patterns Checklist

Verify before merging any navigation change:

| Anti-Pattern | Description |
|---|---|
| **Navigation Inflation** | Adding every module to sidebar/header |
| **Mirror Navigation** | Mobile and desktop menus being identical |
| **Feature Registry Menus** | Menus acting as technical module lists |
| **Operational Leakage** | Admin tools visible in public UX |
| **Duplicate Access Paths** | Same functionality repeated across menus |

---

## Governance Process

Every navigation change MUST include:
- UX justification
- Frequency analysis
- Role analysis
- Mobile impact analysis (safe area, overflow, burger menu)

### Required Reviewers
- Product
- UX / Design
- Architecture

---

## Guiding Principle

### Navigation should expose intention, not implementation.

Users should experience: communities, services, participation, workflows — not platform internals.

### Verb vs Discovery Rule

| Verb-based features | Belong in Workspace |
|---|---|
| Book, Report, Message, Schedule, Manage | Dashboard / user tools |

| Discovery-based features | Belong in Public / Community |
|---|---|
| Directory, Services, Resources, Events | Navigation or contextual |

---

## Adopting This Blueprint

To implement this governance framework in your project:

1. **Map your layers** — identify your Public, Community, Workspace, and Administrative domains
2. **Define spaces** — create your `SpaceDefinition` registry (3–5 spaces recommended)
3. **Implement chrome** — use the ChromeLauncher, SpaceLauncher, and MobileLauncher blueprints
4. **Wire role gating** — connect your auth provider's role to `getVisibleSpaces()`
5. **Wire flag gating** — connect your feature flag provider for optional spaces
6. **Establish admission process** — adopt the qualification checklist in your planning workflow
7. **Review against anti-patterns** — before every navigation merge

### Related Blueprints

- [CHROME_LAUNCHER.md](./CHROME_LAUNCHER.md) — Shell layout (sidebar + content + mobile bar)
- [SPACE_LAUNCHER.md](./SPACE_LAUNCHER.md) — Desktop sidebar component
- [MOBILE_LAUNCHER.md](./MOBILE_LAUNCHER.md) — Mobile bottom navigation bar
- [SUB_LAUNCHER.md](./SUB_LAUNCHER.md) — Domain sub-navigation grid pattern
