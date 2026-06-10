# MobileLauncher (MobileSpaceBar — Bottom Navigation)

A fixed bottom navigation bar for mobile viewports. Renders up to 5 space icons with short labels, safe-area-aware for modern devices (notch, Dynamic Island, home indicator).

## When to Use

- Your app needs mobile navigation for 3–5 top-level sections
- You want a native-feeling tab bar pattern (like iOS/Android bottom nav)
- You're pairing it with a desktop sidebar under a shared shell component
- You need overflow handling when more items exist than fit the bar

## Architecture

```
SpaceChrome (shell)
  └─ MobileSpaceBar (mobile bottom nav — md:hidden)
       └─ array of SpaceDefinition[] (sliced to 5)
            └─ Link per space (icon + short label)
            └─ UnreadBadge (optional, per-space)
```

The `MobileSpaceBar` is rendered **outside** the `flex` container but **inside** `ErrorBoundary` so it sits at the bottom of the viewport independently.

## Implementation

```tsx
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import { authClient } from '@api/auth-client';
import { usePageFlags } from '@/shared/lib/hooks/usePageFlags';
import { getVisibleSpaces, SPACES, type SpaceId } from '../model/spaces';

export function MobileSpaceBar() {
  const pathname = usePathname();
  const { t } = useTranslation();
  const { data: session } = authClient.useSession();
  const { flags } = usePageFlags();
  const role = session?.user?.role || 'RESIDENT';

  const visibleSpaces = flags ? getVisibleSpaces(role, flags) : [];
  const mobileSpaces = visibleSpaces.slice(0, 5);

  // Overflow guard — log warning when >5 spaces
  if (visibleSpaces.length > 5) {
    console.warn(`[MobileSpaceBar] ${visibleSpaces.length} spaces but only 5 slots`);
  }

  const isActive = (spaceId: SpaceId): boolean => {
    const base = SPACES[spaceId].href;
    return pathname === base || pathname.startsWith(base + '/');
  };

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 h-16 pb-[env(safe-area-inset-bottom,0px)] md:hidden bg-white border-t border-gray-200 z-40"
      aria-label="Space navigation"
    >
      <div className="flex items-center justify-around h-16 px-2">
        {mobileSpaces.map(space => {
          const Icon = space.icon;
          const active = isActive(space.id);
          const label = t(space.labelKey);

          return (
            <Link
              key={space.id}
              href={space.href}
              className={`flex flex-col items-center justify-center gap-0.5 flex-1 py-1 transition-colors ${
                active ? 'text-indigo-600' : 'text-gray-500 hover:text-gray-700'
              }`}
              aria-current={active ? 'page' : undefined}
            >
              <div className="relative">
                <Icon className="w-5 h-5" />
                {space.id === 'messages' && <UnreadBadge />}
              </div>
              <span className="text-[10px] font-medium leading-tight truncate max-w-[64px]">
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
```

## Safe-Area Handling

```css
/* CSS custom properties approach (alternative to inline style) */
:root {
  --safe-area-bottom: env(safe-area-inset-bottom, 0px);
}

/* Mobile bar height includes safe area padding */
pb-[env(safe-area-inset-bottom,0px)]
```

**Prerequisites for iOS safe areas:**

```tsx
// Root layout must include viewport-fit=cover
export const viewport: Viewport = {
  viewportFit: 'cover',  // Required for env(safe-area-*) to work on iOS
};
```

## Overflow Pattern

The mobile bar enforces a 5-item limit. For apps with >5 sections:

1. **Slice to 5** — `visibleSpaces.slice(0, 5)` with console warning
2. **Last slot becomes "More"** — opens a bottom sheet with remaining items (TBD)
3. **Priority ordering** — core spaces (home, messages) first in the SPACES registry

```typescript
// Overflow guard pattern
const MAX_MOBILE_SLOTS = 5;
const mobileSpaces = visibleSpaces.slice(0, MAX_MOBILE_SLOTS);

if (visibleSpaces.length > MAX_MOBILE_SLOTS) {
  console.warn(
    `[MobileSpaceBar] ${visibleSpaces.length} spaces visible but only ${MAX_MOBILE_SLOTS} mobile slots.`
  );
  // TODO: render "More" overflow sheet as 5th item
}
```

## Active State Detection

```typescript
// Matches both exact path and sub-paths
const isActive = (spaceId: SpaceId): boolean => {
  const base = SPACES[spaceId].href;
  return pathname === base || pathname.startsWith(base + '/');
};
```

This ensures sub-pages (e.g. `/admin/users`) still highlight the parent space (`admin`).

## Unread Badge (Placeholder)

A small indicator dot on specific spaces. Currently a no-op placeholder:

```typescript
function UnreadBadge() {
  // TODO: connect to real unread count from store
  return null;  // Replace with <span className="absolute -top-1 -right-1 w-2 h-2 bg-red-500 rounded-full" />
}
```

## Design Rules

| Rule | Why |
|------|-----|
| Fixed to bottom | Always accessible, native tab-bar pattern |
| `z-40` | Below modals (z-50) but above content |
| 5-item max | Human thumb reach — 5 taps on bottom bar is comfortable |
| `text-[10px]` labels | Compact enough for 5 items without wrapping |
| `truncate max-w-[64px]` | Long space names don't break layout |
| `md:hidden` | Desktop uses sidebar instead |
| Gap `gap-0.5` | Tight spacing for icon-label pairs |
| Each item `flex-1` | Equal-width distribution across the bar |

## Customization Points

| Aspect | Change |
|--------|--------|
| Max slots | Change `5` constant (re-evaluate overflow if >5) |
| Active color | Replace `text-indigo-600` |
| Icon size | Change `w-5 h-5` |
| Label size | Change `text-[10px]` |
| Bar height | Change `h-16` |
| Overflow behavior | Implement "More" sheet as 5th item |
| Badge condition | Change `space.id === 'messages'` to your logic |

## Reuse Checklist

- [ ] Import session and flags from your auth/flags providers
- [ ] Implement `getVisibleSpaces()` matching your space model
- [ ] Implement `isActive()` for your URL scheme
- [ ] Set `viewportFit: 'cover'` in root layout for iOS safe areas
- [ ] Always render outside the flex container but inside ErrorBoundary
- [ ] Test on iPhone notch, Dynamic Island, and Android status bar
