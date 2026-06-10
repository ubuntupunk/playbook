# SpaceLauncher (Desktop Sidebar Navigation)

A collapsible vertical sidebar that provides primary navigation across Focus Spaces. Designed for desktop viewports (768px+), hidden on mobile.

## When to Use

- Your app has 3–5 top-level navigation "spaces" (sections)
- You need a sidebar that collapses to icon-only mode to save horizontal space
- You want role-based and feature-flag-gated visibility per nav item
- You're building a multi-section dashboard, admin panel, or hub

## Architecture

```
SpaceChrome (shell)
  └─ SpaceLauncher (desktop sidebar)
       └─ array of SpaceDefinition[]
            └─ Link per space (icon + label)
  └─ main (content area)
  └─ MobileSpaceBar (mobile, separate)
```

The sidebar is a **presentational component** — it receives its space definitions as props from the parent `SpaceChrome`, which owns the visibility/filtering logic.

## Key Interface

```typescript
interface SpaceLauncherProps {
  spaces: SpaceDefinition[];    // Filtered list of visible spaces
  activeSpaceId: string;        // Currently active space ID
  collapsed: boolean;            // w-16 when true, w-56 when false
  onNavigate: (spaceId: string) => void;  // Navigation callback
  onToggleCollapse: () => void;  // Collapse toggle handler
}
```

## SpaceDefinition Model

```typescript
interface SpaceDefinition {
  id: SpaceId;                    // 'home' | 'services' | 'community' | 'messages' | 'admin'
  href: string;                   // Canonical URL for this space
  labelKey: string;               // i18n key (e.g. 'spaces.home')
  icon: LucideIcon;               // Lucide icon component
  isCore: boolean;                // Core spaces always visible
  requiredFlag?: keyof PlatformPageFlags;  // Feature flag gate
  minimumRole?: string;           // 'admin' for admin space
  widgetIds: string[];            // Widgets belonging to this space
}
```

## Implementation Pattern

```tsx
'use client';

import Link from 'next/link';
import { useTranslation } from 'react-i18next';
import type { SpaceDefinition } from '../model/spaces';

export function SpaceLauncher({ spaces, activeSpaceId, collapsed, onNavigate, onToggleCollapse }: SpaceLauncherProps) {
  const { t } = useTranslation();

  return (
    <nav
      className={`hidden md:flex flex-col h-full bg-white border-r border-gray-200 transition-all duration-200 ${
        collapsed ? 'w-16' : 'w-56'
      }`}
      aria-label="Dashboard spaces"
    >
      {/* Space items */}
      <div className="flex-1 py-4 space-y-1">
        {spaces.map(space => {
          const Icon = space.icon;
          const isActive = space.id === activeSpaceId;
          const href = space.href;
          const label = t(space.labelKey);

          return (
            <Link
              key={space.id}
              href={href}
              onClick={() => onNavigate(space.id)}
              className={`flex items-center gap-3 px-3 py-2.5 mx-2 rounded-lg transition-colors ${
                isActive
                  ? 'bg-indigo-50 text-indigo-700 border-l-2 border-indigo-600'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`}
              aria-current={isActive ? 'page' : undefined}
              aria-label={collapsed ? label : undefined}
              title={collapsed ? label : undefined}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              {!collapsed && <span className="text-sm font-medium truncate">{label}</span>}
            </Link>
          );
        })}
      </div>

      {/* Collapse toggle */}
      <div className="border-t border-gray-200 p-2">
        <button
          onClick={onToggleCollapse}
          className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-gray-500 hover:bg-gray-50 hover:text-gray-700 transition-colors"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          <svg className={`w-5 h-5 transition-transform ${collapsed ? 'rotate-180' : ''}`} ...>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
          </svg>
          {!collapsed && <span className="text-sm">Collapse</span>}
        </button>
      </div>
    </nav>
  );
}
```

## Visibility Gating Logic

```typescript
function getVisibleSpaces(role: string, flags: PlatformPageFlags): SpaceDefinition[] {
  const isAdmin = ADMIN_ROLES.includes(role?.toUpperCase());

  return SPACE_SLUGS.filter(spaceId => {
    const space = SPACES[spaceId];
    if (space.minimumRole === 'admin' && !isAdmin) return false;
    if (space.isCore) return true;
    if (space.requiredFlag) return flags[space.requiredFlag] !== false;
    // Complex gating (e.g. community: hide if ALL sub-flags are off)
    if (spaceId === 'community') {
      return [/* sub-flags */].some(flag => flags[flag] !== false);
    }
    return true;
  }).map(spaceId => SPACES[spaceId]);
}
```

## Active Space Resolution

```typescript
function getActiveSpaceId(pathname: string): SpaceId | 'home' {
  if (!pathname) return 'home';
  if (pathname === '/admin' || pathname.startsWith('/admin/')) return 'admin';
  const match = pathname.match(/^\/dashboard\/([^/]+)/);
  if (match) {
    const resolved = resolveSpace(match[1]);
    if (resolved) return resolved.id;
  }
  return 'home';
}
```

## Customization Points

| Aspect | How to customize |
|--------|-----------------|
| Widths | Change `w-16` (collapsed) and `w-56` (expanded) Tailwind classes |
| Icons | Replace `LucideIcon` type and import different icon set |
| Active style | Change `bg-indigo-50 text-indigo-700` classes |
| Visibility rules | Override `getVisibleSpaces()` filters |
| Collapse persistence | Add `localStorage` sync in the parent (SpaceChrome) |
| i18n | Swap `react-i18next` for any translation library |

## Reuse Checklist

- [ ] Define your own `SpaceId` type and `SpaceDefinition` interface
- [ ] Create a SPACES registry object
- [ ] Implement `getVisibleSpaces()` with your role/gating logic
- [ ] Wire up `getActiveSpaceId()` for your URL scheme
- [ ] Mount `SpaceLauncher` inside a shell component (see ChromeLauncher)
- [ ] Add `hidden md:flex` to hide on mobile (pair with MobileLauncher)
