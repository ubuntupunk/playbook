# Navigation Architecture Reference

How the NAVIGATION_GOVERNANCE.md principles are realized in code. Maps governance layers to implementation, explains the URL hierarchy, component relationships, and provides a developer's guide for navigation changes.

---

## Governance → Implementation Map

| Governance Layer | Audience | Component(s) | Location |
|---|---|---|---|
| **Public** | Visitors, unauthenticated | `PublicHeader`, `PublicFooter` | Widgets under `src/widgets/public/` |
| **Community** | Authenticated residents | `SpaceLayout`, community widgets | `/dashboard/community` route |
| **Workspace** | Authenticated users | `SpaceChrome`, `SpaceLauncher`, `MobileSpaceBar` | `/dashboard/*` routes |
| **Administrative** | Admins, staff | `SpaceChrome`, `AdminSubLauncher`, `AdminLayer` | `/admin/*` routes |
| **Footer** | Everyone | `PublicFooter` (upper + lower tiers) | Widgets under `src/widgets/public/` |

The **Workspace** and **Administrative** layers share the `SpaceChrome` shell — the admin space uses the same sidebar + bottom bar as resident spaces, with role gating controlling its visibility.

---

## URL Hierarchy

```
/(tenant)                              ← TenantLayout (i18n, Toaster, Suspense)
  ├── /                                ← Public pages (PublicHeader + PublicFooter)
  │   ├── /directory
  │   ├── /services
  │   ├── /resources
  │   └── /conservation | /campaigns
  │
  ├── /dashboard                       ← SpaceChrome (sidebar + mobile bar)
  │   ├── /                            → HomeLayer + MyHomeSpace
  │   ├── /services                    → ServicesLayer (domain grid, urgency)
  │   │   ├── /services/maintenance    → Maintenance widgets
  │   │   ├── /services/bookings
  │   │   ├── /services/amenities
  │   │   ├── /services/my-services
  │   │   └── /services/events
  │   ├── /community                   → SpaceLayout (DnD widget grid)
  │   ├── /messages                    → MessagesLayer (domain grid, urgency)
  │   │   ├── /messages/conversations
  │   │   ├── /messages/announcements
  │   │   └── /messages/notifications
  │   └── /dashboard/admin             ← legacy redirect to /admin (back-compat)
  │
  └── /admin                           ← Canonical admin route (Phase 37)
      ├── /                            → AdminLayer (command bar + domain grid + activity)
      ├── /users                       → Users management widgets
      ├── /maintenance                 → Maintenance management widgets
      ├── /content                     → Content management widgets
      ├── /events                      → Event management widgets
      ├── /competitions                → Competition management widgets
      ├── /resources                   → Resource management widgets
      ├── /surveys                     → Survey management widgets
      ├── /announcements               → Announcement management widgets
      └── /system                      → System configuration widgets
```

**Canonical admin route:** Phase 37 moved admin from `/dashboard/admin` to `/admin`. The legacy route redirects. `getActiveSpaceId()` in spaces.ts handles both patterns.

---

## Component Hierarchy

```
TenantLayout (i18n, Toaster)
  └── PublicHeader (public pages only)
  │
  └── SpaceChrome (dashboard + admin pages)
  │    ├── SpaceLauncher               ← Desktop sidebar (md:flex, hidden on mobile)
  │    │    └── Link[] per visible space
  │    ├── <main>
  │    │    └── [space]/page.tsx dispatcher
  │    │         ├── AdminLayer → AdminSubLauncher (domain grid)
  │    │         ├── ServicesLayer → ServicesSubLauncher (domain grid + urgency)
  │    │         ├── MessagesLayer → MessagesSubLauncher (domain grid + urgency)
  │    │         └── SpaceLayout (DnD widgets for home, community)
  │    └── MobileSpaceBar              ← Mobile bottom nav (md:hidden)
  │         └── Link[] max 5 items
  │
  └── PublicFooter (public pages only)
```

---

## Key Files

| File | Role | Governance Relevance |
|---|---|---|
| `widgets/dashboard/ui/SpaceChrome.tsx` | Shell — sidebar + content + mobile bar | Mounts workspace navigation chrome |
| `widgets/dashboard/ui/SpaceLauncher.tsx` | Desktop sidebar | Renders the 5 Focus Spaces |
| `widgets/dashboard/ui/MobileSpaceBar.tsx` | Mobile bottom nav | Mobile workspace nav (max 5) |
| `widgets/dashboard/model/spaces.ts` | Space registry + visibility logic | Implements admission criteria (role gating, flag gating) |
| `widgets/dashboard/ui/AdminSubLauncher.tsx` | 9-domain admin grid | Administrative navigation placement |
| `widgets/dashboard/ui/ServicesSubLauncher.tsx` | 5 service domains | Workspace sub-navigation |
| `widgets/dashboard/ui/MessagesSubLauncher.tsx` | 3 message domains | Workspace sub-navigation |
| `widgets/dashboard/ui/AdminLayer.tsx` | Admin overview page | Dashboard governance tab |
| `widgets/dashboard/ui/ServicesLayer.tsx` | Services overview page | Dashboard governance tab |
| `widgets/dashboard/ui/MessagesLayer.tsx` | Messages overview page | Dashboard governance tab |
| `widgets/dashboard/ui/HomeLayer.tsx` | Home dashboard | Dashboard governance tab |
| `docs/architecture/NAVIGATION_GOVERNANCE.md` | Governance rules | Source of truth for admission criteria |
| `.documents/patterns/SPACE_LAUNCHER.md` | Blueprint | Reusable desktop sidebar pattern |
| `.documents/patterns/CHROME_LAUNCHER.md` | Blueprint | Reusable shell layout pattern |
| `.documents/patterns/MOBILE_LAUNCHER.md` | Blueprint | Reusable mobile bottom nav pattern |
| `.documents/patterns/SUB_LAUNCHER.md` | Blueprint | Reusable domain navigation pattern |

---

## How the 5-Space Model Maps to Governance

| Space (SpaceId) | Governance Layer | Role Gate | Flag Gate | Admission Rationale |
|---|---|---|---|---|
| `home` | Workspace | None (always) | None | Dashboard overview — highest frequency |
| `services` | Workspace | None | `services` flag | Maintenance, bookings, amenities |
| `community` | Community | None | Auto-hide when ALL of events/groups/surveys/competitions/news are off | Secondary engagement |
| `messages` | Workspace | None (always) | None | Core communication — always visible |
| `admin` | Administrative | `admin` or `board` | None | Operations isolated from public UX |

The visibility logic in `getVisibleSpaces()` enforces these rules:

```typescript
// From spaces.ts — simplified
function getVisibleSpaces(role, flags) {
  return SPACE_SLUGS.filter(id => {
    // Admin: role-gated
    if (space.minimumRole === 'admin' && !isAdmin) return false;
    // Core spaces (home, messages): always shown
    if (space.isCore) return true;
    // Optional: flag-gated
    if (space.requiredFlag) return flags[space.requiredFlag] !== false;
    // Community: complex auto-hide
    if (id === 'community') return anyCommunityFeatureEnabled(flags);
  });
}
```

---

## Developer's Guide: Adding Navigation

### Add a New Space (top-level section)

1. **Admission check** — apply the governance checklist (NAVIGATION_GOVERNANCE.md §Navigation Admission Criteria):
   - [ ] Will most users access this weekly? (Frequency)
   - [ ] Relevant to most tenants? (Breadth)
   - [ ] Long-term feature? (Stability)
   - [ ] Could it be discovered contextually instead? (Discoverability)
   - [ ] Does another surface already expose it? (Redundancy)
   - [ ] Does it represent a primary user journey? (User Intent)

2. **If rejected** — surface the feature through dashboard widgets, notifications, or contextual cards instead.

3. **If admitted** — implement in this order:
   ```
   1. Add SpaceId to SpaceId type            → spaces.ts
   2. Add entry to SPACES registry            → spaces.ts
   3. Add route handler in [space]/page.tsx   → dashboard routing
   4. Create Layer component (or SpaceLayout) → widgets/dashboard/ui/
   5. Export from barrel                      → widgets/dashboard/index.ts
   ```

### Add a Sub-Domain to an Existing Space

1. **Admission check** — apply tab admission criteria (NAVIGATION_GOVERNANCE.md §Dashboard Tab Admission Criteria):
   - [ ] Distinct user journey?
   - [ ] 2+ dedicated widgets?
   - [ ] Cannot merge into existing tab?
   - [ ] Serves authenticated users (or admin role for admin tabs)?

2. **Implementation:**
   ```
   1. Add to {SPACE}_DOMAIN_DEFINITIONS     → SubLauncher file
   2. Add to shared domain constants         → spaces.ts
   3. Add widget mapping                     → spaces.ts
   4. Add route page                         → app/(tenant)/dashboard/{space}/[domain]/page.tsx
   5. Create domain-specific widgets         → widgets/{domain}/
   ```

---

## Forbidden Patterns (Anti-Patterns Checklist)

From NAVIGATION_GOVERNANCE.md §Anti-Patterns — verify before merging any navigation change:

| Anti-Pattern | How to Spot | Enforcement |
|---|---|---|
| **Navigation Inflation** | Adding every module to sidebar/header | Governance review during planning |
| **Mirror Navigation** | Mobile and desktop identical nav | Mobile bar slices to 5; burger menu has different structure |
| **Feature Registry Menus** | Menu items matching internal module list | SubLauncher model keeps domains intentional |
| **Operational Leakage** | Admin tools visible to residents | `minimumRole: 'admin'` + `getVisibleSpaces` filters |
| **Duplicate Access Paths** | Same feature in sidebar + header + footer + burger | Space model ensures one canonical entry |

---

## Related Blueprints

For reusable implementation patterns (useful when porting this nav system to another project):

- [SPACE_LAUNCHER.md](./SPACE_LAUNCHER.md) — Desktop sidebar component
- [CHROME_LAUNCHER.md](./CHROME_LAUNCHER.md) — Shell layout (sidebar + content + mobile bar)
- [MOBILE_LAUNCHER.md](./MOBILE_LAUNCHER.md) — Mobile bottom navigation bar
- [SUB_LAUNCHER.md](./SUB_LAUNCHER.md) — Domain definition + sub-navigation grid pattern
