# SubLauncher — Domain Sub-Navigation Pattern

A data-driven pattern for defining and rendering sub-domain navigation within a Focus Space. Separates **domain definitions** (types + constants) from **UI rendering** (Layer components) so both route pages and overview layers consume the same source of truth.

## When to Use

- A Space has multiple sub-sections (e.g. Admin: Users, Content, Events…)
- You need consistent navigation grids in overview layers and individual pages
- You want a single source of truth for domain IDs, icons, labels, and descriptions
- You need urgency badges (unread counts) on sub-domain cards

## Files in the Pattern

```
widgets/dashboard/
├── ui/
│   ├── AdminSubLauncher.tsx      # Data definitions + rendered grid
│   ├── ServicesSubLauncher.tsx    # Data definitions only
│   ├── MessagesSubLauncher.tsx    # Data definitions only
│   ├── AdminLayer.tsx             # Overview page (fetches urgency, renders grid)
│   ├── ServicesLayer.tsx          # Overview page
│   └── MessagesLayer.tsx          # Overview page
├── model/
│   └── spaces.ts                 # Shared domain constants + widget maps
└── index.ts                      # Barrel exports
```

## Pattern: Two-Tier Separation

### Tier 1: Domain Definition File (SubLauncher)

Pure data — types, constants, and (optionally) a rendered grid component:

```typescript
// Types
export interface ServicesDomainDef {
  id: string;
  labelKey: string;        // i18n key
  descriptionKey: string;  // i18n key for description
  icon: LucideIcon;        // Lucide icon component
  description: string;     // Fallback English text
}

// Registry — single source of truth
export const SERVICES_DOMAIN_DEFINITIONS: ServicesDomainDef[] = [
  {
    id: 'maintenance',
    labelKey: 'domains.maintenance',
    descriptionKey: 'domains.descriptions.maintenance',
    icon: Wrench,
    description: 'Submit and track maintenance requests',
  },
  // ... more domains
];
```

### Tier 2: Layer Component

Handles data fetching (urgency counts), loading/error/empty states, and renders the grid:

```typescript
// Pattern for a Layer component
export function ServicesLayer() {
  const { t } = useTranslation();
  const { data: urgency, isLoading } = useQuery({
    queryKey: ['services-urgency'],
    queryFn: () => fetch('/api/services/urgency').then(r => r.json()),
  });

  if (isLoading) return <SkeletonGrid count={5} />;
  if (!urgency) return <ErrorState />;

  return (
    <div className="p-6 space-y-6">
      <CommandBar />
      <DomainGrid
        domains={SERVICES_DOMAIN_DEFINITIONS}
        urgency={urgency}
        basePath="/dashboard/services"
      />
    </div>
  );
}
```

## SubLauncher Variants

### Data-Only (ServicesSubLauncher, MessagesSubLauncher)

Export interfaces + constants. Consumed by Layer components and route pages.

```
widgets/dashboard/
  ├── ui/ServicesSubLauncher.tsx      → exports ServicesDomainDef + SERVICES_DOMAIN_DEFINITIONS
  └── ui/ServicesLayer.tsx            → imports and renders them
app/(tenant)/dashboard/services/[domain]/page.tsx  → imports for breadcrumbs/icons
```

### Data + Render (AdminSubLauncher)

Exports interfaces + constants **and** a rendered grid component because the admin sub-launcher has special behavior (e.g. Users domain button scrolls to inline section instead of navigating):

```tsx
export function AdminSubLauncher() {
  // ...
  // Special case: Users domain scrolls to inline section
  if (domain.id === 'users') {
    return <button onClick={handleUsersClick}>...</button>;
  }
  // Other domains link to /admin/[domain]
  return <Link href={`/admin/${domain.id}`}>...</Link>;
}
```

## Domain Card Rendering

```tsx
function DomainCard({ domain, basePath, urgency }: DomainCardProps) {
  const DomainIcon = domain.icon;
  const count = urgency?.[domain.id];
  const hasUrgency = count && count > 0;

  return (
    <Link
      href={`${basePath}/${domain.id}`}
      className="group flex items-start gap-4 p-4 bg-white rounded-lg shadow-sm hover:bg-gray-50 hover:shadow-md transition-all border border-gray-100"
    >
      <div className="flex-shrink-0 p-2 bg-indigo-50 rounded-lg group-hover:bg-indigo-100 transition">
        <DomainIcon className="w-6 h-6 text-indigo-600" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-semibold text-gray-900 group-hover:text-indigo-600 transition">
            {t(domain.labelKey)}
          </h3>
          {hasUrgency && (
            <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
              {count}
            </span>
          )}
        </div>
        <p className="text-xs text-gray-500 mt-1 line-clamp-2">
          {t(domain.descriptionKey)}
        </p>
      </div>
    </Link>
  );
}
```

## Urgency Badge Data Flow

```
Browser
  └→ Layer component mounts
      └→ fetches GET /api/{space}/urgency
          └→ returns { [domainId]: number }
              └→ rendered as red badge on domain card
```

```typescript
// API response shape
type UrgencyMap = Record<string, number>;
// Example: { maintenance: 3, bookings: 0, amenities: 1, ... }
```

## Route Structure

Each sub-launcher maps to a route pattern:

| Launcher | Route Pattern | Example |
|----------|--------------|---------|
| Services | `/dashboard/services/[domain]` | `/dashboard/services/maintenance` |
| Messages | `/dashboard/messages/[domain]` | `/dashboard/messages/announcements` |
| Admin | `/admin/[domain]` | `/admin/users` |

```tsx
// app/(tenant)/dashboard/services/[domain]/page.tsx
export default async function ServicesDomainPage({ params }: { params: { domain: string } }) {
  const domain = SERVICES_DOMAIN_DEFINITIONS.find(d => d.id === params.domain);
  if (!domain) notFound();
  // Render domain-specific content...
}
```

## Design Rules

| Rule | Reason |
|------|--------|
| SubLauncher files export interfaces + constants | Separates concerns — model from rendering |
| Layer components fetch urgency data | Keeps data dependencies out of definition files |
| AdminSubLauncher renders directly | Special UI behavior (section scroll vs link) breaks the data-only abstraction |
| Domain IDs match URL slugs | Simplifies route matching and urgency API keys |
| i18n keys follow `domains.{id}` and `domains.descriptions.{id}` | Consistent naming convention |
| Icon grid: 1-col mobile → 3-col desktop | `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` |

## Reuse Checklist

- [ ] Define `{Space}DomainDef` interface (id, labelKey, descriptionKey, icon, description)
- [ ] Create `{SPACE}_DOMAIN_DEFINITIONS` constant array
- [ ] Decide: data-only or data+render export pattern
- [ ] Create `{Space}Layer` component with urgency fetching + grid rendering
- [ ] Add routes: `app/(tenant)/dashboard/{space}/[domain]/page.tsx`
- [ ] Add domain constants to the shared spaces model for widget mappings
