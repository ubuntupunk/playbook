# ChromeLauncher (SpaceChrome — Shell Layout)

The top-level application shell that composes the desktop sidebar, mobile bottom bar, and main content area into a single responsive layout. Handles session, feature flags, active space resolution, and sidebar collapse state.

## When to Use

- You need a consistent chrome around all dashboard/admin pages
- Your app has a sidebar (desktop) + bottom bar (mobile) + main content tri-layout
- You want a single mount point in your root layout that manages nav state
- You're wrapping route groups with the same navigation chrome

## Architecture

```
Layout (per route group)
  └── SpaceChrome (stateful shell)
       ├── SpaceLauncher (desktop sidebar — hidden on mobile)
       ├── <main> (flex-1 content area)
       └── MobileSpaceBar (mobile bottom nav — hidden on desktop)

State lives in SpaceChrome so it persists across in-section navigations:
  - collapsed: boolean (sidebar toggle)
  - pathname: string (from usePathname)
  - session: session data (from authClient)
  - flags: feature flags (from usePageFlags)
```

## Implementation

```tsx
'use client';

import { useState } from 'react';
import { usePathname } from 'next/navigation';
import { authClient } from '@shared/api';
import { usePageFlags } from '@/shared/lib/hooks/usePageFlags';
import { ErrorBoundary } from '@shared/ui';
import { SpaceLauncher } from './SpaceLauncher';
import { MobileSpaceBar } from './MobileSpaceBar';
import { getActiveSpaceId, getVisibleSpaces } from '../model/spaces';

interface SpaceChromeProps {
  children: React.ReactNode;
}

export function SpaceChrome({ children }: SpaceChromeProps) {
  const [collapsed, setCollapsed] = useState(true);    // Start collapsed
  const pathname = usePathname();
  const { data: session } = authClient.useSession();
  const { flags } = usePageFlags();

  const role = session?.user?.role || 'RESIDENT';
  const activeSpaceId = getActiveSpaceId(pathname);
  const visibleSpaces = flags ? getVisibleSpaces(role, flags) : [];

  return (
    <ErrorBoundary>
      <div className="flex min-h-screen bg-gray-50">
        {/* Desktop sidebar */}
        <SpaceLauncher
          spaces={visibleSpaces}
          activeSpaceId={activeSpaceId}
          collapsed={collapsed}
          onNavigate={() => {}}
          onToggleCollapse={() => setCollapsed(prev => !prev)}
        />

        {/* Main content — safe-area-aware bottom padding for mobile bar */}
        <main
          className="flex-1 min-w-0 md:pb-0"
          style={{ paddingBottom: 'calc(4rem + env(safe-area-inset-bottom, 0px))' }}
        >
          {children}
        </main>
      </div>

      {/* Mobile bottom bar */}
      <MobileSpaceBar />
    </ErrorBoundary>
  );
}
```

## Mount Point

Mount in your route group layout (keeps chrome scoped to auth-protected routes):

```tsx
// src/app/(tenant)/dashboard/layout.tsx
'use client';
import { SpaceChrome } from '@widgets/dashboard';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return <SpaceChrome>{children}</SpaceChrome>;
}
```

## Design Rules

| Rule | Why |
|------|-----|
| `<main>` is a passthrough (`flex-1 min-w-0`) | Each page owns its own width/max-width wrapper — prevents chrome duplication |
| Safe-area bottom padding on main | Content doesn't hide behind mobile home indicator |
| `<main>` uses inline `style` for calc | Tailwind doesn't support `calc()` in class names |
| Sidebar starts collapsed | Maximizes content area by default |
| State lives in SpaceChrome | Persists across SPA-style navigations within the section |
| Wrapped in ErrorBoundary | Catches rendering crashes in any child without blowing up the entire shell |

## Customization Points

| Aspect | Change |
|--------|--------|
| Background | Replace `bg-gray-50` on the flex container |
| Collapse initial state | Change `useState(true)` to `useState(false)` |
| Collapse persistence | Add `useLocalStorage('sidebar-collapsed', true)` from usehooks-ts |
| Auth hook | Swap `authClient.useSession()` for your auth provider |
| Flags hook | Swap `usePageFlags()` for your feature flag provider |
| Error boundary | Use your own `ErrorBoundary` implementation |

## Reuse Checklist

- [ ] Create a `SpaceChrome`-equivalent shell component
- [ ] Pull session/role from your auth provider
- [ ] Pull feature flags from your flags provider
- [ ] Implement `getActiveSpaceId()` matching your URL scheme
- [ ] Implement `getVisibleSpaces()` with your gating rules
- [ ] Mount SpaceLauncher and MobileSpaceBar inside
- [ ] Wrap with ErrorBoundary
- [ ] Mount in your route group layout
