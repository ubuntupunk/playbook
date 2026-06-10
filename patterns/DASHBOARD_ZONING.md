# Dashboard Zoning System — Blueprint

A pattern for structuring dashboard pages into semantic zones. Zones are vertical sections that each own a specific data domain — urgency, schedule, activity, navigation, or widgets. Two architectures exist: **hardcoded layers** (zones with fixed purpose) and **DnD widget grids** (user-customizable zones).

---

## When to Use

- Your dashboard has distinct information domains (urgency, today, activity, navigation)
- Pages need consistent loading/error/empty states per section
- Some spaces need hardcoded zones (admin tools) while others need customizable widget grids (home, community)
- You want to avoid monolithic page components by separating concerns into named zones

---

## Two Zone Architectures

### Architecture A: Hardcoded Layers (Structured Zones)

Used by: **AdminLayer**, **ServicesLayer**, **MessagesLayer**, **HomeLayer**

Zones are fixed, semantic sections with specific purposes. Each zone has its own data slice, loading state, and empty state.

```
Layer Component
  ├── CommandBar Zone     ← reactive CTAs + urgency chips
  ├── Domain Grid Zone    ← sub-domain cards with urgency badges
  └── Activity Stream     ← lazy-loaded, filterable feed
```

### Architecture B: Widget Grid (Customizable Zones)

Used by: **SpaceLayout** (home, community, custom spaces)

Zones are implicit — created by user widget positions. Widgets can be added, removed, dragged, collapsed.

```
SpaceLayout
  ├── Widget Grid (mobile: stacked cards)
  │   └── WidgetCard per active widget
  ├── Widget Grid (desktop: DnD layout)
  │   └── DraggableWidget per active widget
  │       └── WidgetRenderer
  └── AddWidgetModal
```

---

## Zone Catalog

### 1. Urgency Zone

**Used in:** HomeLayer  
**Purpose:** Items needing immediate attention — urgent announcements, overdue maintenance, unread messages  
**Empty state:** Hidden entirely (returns `null`) when no urgent items

```tsx
<section aria-label="Urgent items">
  <UrgencyCard priority="urgent"   icon={Megaphone} label="..." />
  <UrgencyCard priority="high"     icon={Wrench}    label="..." />
  <UrgencyCard priority="normal"   icon={Bell}      label="..." />
</section>
```

Priority color coding:
| Priority | Border | Pill |
|---|---|---|
| `urgent` | `border-l-red-500` | `bg-red-100 text-red-700` |
| `high` | `border-l-amber-500` | `bg-amber-100 text-amber-700` |
| `normal` | `border-l-indigo-500` | `bg-indigo-100 text-indigo-700` |

### 2. Command Bar Zone

**Used in:** AdminLayer, ServicesLayer, MessagesLayer  
**Purpose:** Reactive CTAs (urgency chips based on counts) + creation shortcuts  
**Data source:** `/api/{space}/urgency` — returns `{ commandBar: {...}, domainBadges: {...} }`

```tsx
<section aria-label="{Space} command bar">
  <SpaceCommandBar urgency={urgency.commandBar} />
</section>
```

### 3. Domain Grid Zone

**Used in:** AdminLayer, ServicesLayer, MessagesLayer  
**Purpose:** Sub-domain navigation cards, each with a red urgency badge  
**Data source:** `domainBadges` from the same urgency API endpoint

```tsx
<section aria-label="Management domains">
  <h2>Domains heading</h2>
  <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
    {DOMAIN_DEFINITIONS.map(domain => (
      <DomainCard key={domain.id} domain={domain} badge={domainBadges[domain.id] ?? 0} />
    ))}
  </div>
</section>
```

Badge capped at `9+` for counts exceeding 9.

### 4. Today Zone

**Used in:** HomeLayer  
**Purpose:** Today's schedule — events and bookings  
**Empty state:** "Nothing scheduled for today" centered card

```tsx
<section aria-label="Today">
  <h2>Today</h2>
  <span>{formattedDate}</span>
  {hasItems ? (
    <TodayCard href="..." icon={...} title="..." subtitle="..." type="Booking" />
  ) : (
    <p>Nothing scheduled for today</p>
  )}
</section>
```

### 5. Activity Zone

**Used in:** HomeLayer  
**Purpose:** Recent activity feed — merged announcements + maintenance activity, sorted by date, top 5  
**Empty state:** "No recent activity" centered card

```tsx
<section aria-label="Recent activity">
  <h2>Recent Activity</h2>
  <ActivityCard href="..." icon={...} title="..." date={createdAt} type="Announcement" />
</section>
```

### 6. Admin Activity Stream Zone

**Used in:** AdminLayer  
**Purpose:** Filterable admin activity feed with domain tabs and cursor-based pagination  
**Pattern:** Lazy-loaded (`React.lazy` + `Suspense`), wrapped in its own `ErrorBoundary`

```tsx
<section aria-label="Recent admin activity">
  <ErrorBoundary fallback={...}>
    <Suspense fallback={<Skeleton />}>
      <AdminActivityStream />
    </Suspense>
  </ErrorBoundary>
</section>
```

### 7. Widget Grid Zone (DnD)

**Used in:** SpaceLayout  
**Purpose:** User-customizable widget grid — add, remove, drag, collapse, reset  
**Responsive behavior:**
- Mobile (`< md`): Simple stacked `WidgetCard` components (no grid)
- Desktop (`>= md`): `DraggableWidget` in `min-h-[1200px]` relative container

```tsx
<section aria-label="Widgets">
  {/* Mobile: stacked cards */}
  <div className="block md:hidden">
    {currentWidgets.map(id => <WidgetCard key={id} id={id} spaceId={spaceId} />)}
  </div>
  {/* Desktop: DnD grid */}
  <div className="hidden md:block min-h-[1200px] relative">
    {currentWidgets.map(id => (
      <DraggableWidget key={id} id={id} spaceId={spaceId} isEditMode={isEditMode}>
        <WidgetRenderer widgetId={id} />
      </DraggableWidget>
    ))}
  </div>
</section>
```

Widget data flow:

```
SpaceDefinition.widgetIds      → which widgets CAN be added to this space
useWidgetStore.userWidgets     → which widgets ARE active (per user, persisted to DB)
getDefaultLayout(role)         → role-based default widget selection
registry.list().filter(spaces) → available widgets for AddWidgetModal filtering
```

---

## Zone Data Fetching Patterns

### Pattern A: Batch Fetch (HomeLayer)

Zones with independent data sources use a single `Promise.all`:

```typescript
const fetchData = useCallback(() => {
  Promise.all([
    fetchJson<Announcement>('/api/announcements?priority=urgent'),       // Urgency Zone
    fetchJson<MaintenanceItem>('/api/maintenance?overdue=true'),          // Urgency Zone
    fetch('/api/messages/unread').then(r => r.json()),                   // Urgency Zone
    fetchJson<EventItem>('/api/events?upcoming=true&limit=5'),           // Today Zone
    fetchJson<BookingItem>('/api/bookings?date=today'),                  // Today Zone
    fetchJson<Announcement>('/api/announcements?limit=5'),               // Activity Zone
    fetchJson<MaintenanceActivityRow>('/api/maintenance?limit=5&scope=mine'), // Activity Zone
  ]).then(([urgentAnnouncements, overdueMaintenance, unreadCount, ...]) => {
    // Transform and merge as needed
    setData({ urgentAnnouncements, overdueMaintenance, ... });
  });
}, [userId, role]);
```

### Pattern B: Urgency API (Admin/Services/Messages)

Spaces with command bars use a single urgency endpoint that powers both the command bar chips and domain badges:

```typescript
const fetchUrgency = useCallback(async () => {
  const res = await fetch('/api/{space}/urgency');
  const body = await res.json();
  const data = body.success ? body.data : body;
  // data = { commandBar: {...}, domainBadges: {...} }
  setUrgency(data);
}, []);
```

### Pattern C: Widget Store (SpaceLayout)

Widget grid zones hydrate from a Zustand store with localStorage persistence + DB sync:

```typescript
const { userWidgets, addWidgetToSpace, removeWidgetFromSpace } = useWidgetStore();
// Hydrated from DB on mount via hydrateFromServer(userId)
// Auto-saves to DB with 500ms debounce via subscribeWidgetAutoSave(userId)
```

---

## Zone State Pattern

Every zone follows a consistent state pattern:

```typescript
function SomeZone({ data }: { data: SomeData | null }) {
  if (!data || data.items.length === 0) return null;     // Empty: hidden
  return (
    <section aria-label="Zone name">
      <h2>Zone Title</h2>
      {data.items.map(item => <ZoneCard key={item.id} {...item} />)}
    </section>
  );
}
```

### Skeleton (Loading)

```tsx
function ZoneSkeleton() {
  return (
    <div className="space-y-2 mb-6 animate-pulse">
      <div className="h-6 w-40 bg-gray-200 rounded" />     {/* Title */}
      <div className="h-16 bg-gray-100 rounded-lg" />      {/* Card 1 */}
      <div className="h-16 bg-gray-100 rounded-lg" />      {/* Card 2 */}
    </div>
  );
}
```

### Error State

```tsx
function ZoneError({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4">
      <p className="text-sm text-red-700 mb-2">Failed to load zone data</p>
      <button onClick={onRetry} className="text-sm text-red-600 underline hover:text-red-800">
        Retry
      </button>
    </div>
  );
}
```

### Empty State

```tsx
// Zone-level empty
<div className="bg-white rounded-lg shadow-sm p-6 text-center">
  <p className="text-gray-500 text-sm">Nothing scheduled for today</p>
</div>

// Or: zone hidden entirely for urgency (return null when nothing urgent)
```

---

## Zone Card Pattern

Cards within zones follow a consistent structure:

```tsx
function ZoneCard({ href, icon, title, subtitle, type }: ZoneCardProps) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 p-3 bg-white rounded-lg shadow-sm hover:bg-gray-50 transition-colors"
    >
      {icon}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900 truncate">{title}</p>
        <p className="text-xs text-gray-500">{subtitle}</p>
      </div>
      <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">{type}</span>
    </Link>
  );
}
```

---

## Zone Composition in a Layer

```tsx
export function ExampleLayer() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [data, setData] = useState<LayerData | null>(null);

  const fetchData = useCallback(async () => { /* fetch zone data */ }, []);
  useEffect(() => { fetchData(); }, [fetchData]);

  // Error state (whole layer)
  if (error) return <LayerError onRetry={fetchData} />;
  // Loading state (whole layer)
  if (loading) return <LayerSkeleton />;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Zone 1: Command Bar */}
      <section aria-label="Command bar">
        <CommandBar urgency={data.commandBar} />
      </section>

      {/* Zone 2: Domain Grid */}
      <section aria-label="Domains">
        <DomainGrid domains={DOMAIN_DEFINITIONS} badges={data.domainBadges} />
      </section>

      {/* Zone 3: Lazy-loaded Activity */}
      <section aria-label="Activity">
        <ErrorBoundary>
          <Suspense fallback={<ActivitySkeleton />}>
            <ActivityStream />
          </Suspense>
        </ErrorBoundary>
      </section>
    </div>
  );
}
```

---

## Zone Dispatch (Space Routing)

The zone architecture for a space is selected in the route page:

```tsx
// app/(tenant)/dashboard/[space]/page.tsx
export default function SpacePage({ params }) {
  const { space } = use(params);
  const spaceId = space as SpaceId;

  if (spaceId === 'admin')     return <AdminLayer />;      // Hardcoded zones
  if (spaceId === 'services')  return <ServicesLayer />;    // Hardcoded zones
  if (spaceId === 'messages')  return <MessagesLayer />;    // Hardcoded zones
  return <SpaceLayoutWithErrorBoundary spaceId={spaceId} />; // DnD widget grid
}
```

---

## Decision Matrix: Hardcoded vs Widget Grid

| Factor | Hardcoded Layer | Widget Grid (SpaceLayout) |
|---|---|---|
| Content structure | Fixed, known at build time | User-customizable |
| Data dependencies | Multiple API calls per zone | Widgets fetch own data |
| Layout control | Developer-controlled | User-controlled (DnD) |
| Empty state per zone | Yes, per zone | "No widgets" message |
| Edit mode | N/A | Add/remove/drag widgets |
| Persistence | N/A | Zustand store → localStorage → DB |
| When to use | Admin tools, structured dashboards | Home, community, flexible spaces |

---

## Reuse Checklist

- [ ] Identify zones for your space (urgency, today, activity, command bar, domain grid, widget grid)
- [ ] Choose architecture: hardcoded layer or DnD widget grid per space
- [ ] For hardcoded layers: implement batch fetch (Promise.all) or urgency API
- [ ] Implement zone skeleton (loading), error (retry), and empty states per zone
- [ ] Wrap cards in `<Link>` for navigation, use consistent card pattern
- [ ] Use `<section aria-label>` for each zone for accessibility
- [ ] For widget grids: wire up Zustand store + DB persistence + role-based defaults
- [ ] Set `max-w-5xl mx-auto space-y-6` on the layer container for consistent spacing
- [ ] Implement space routing dispatch in `[space]/page.tsx`
