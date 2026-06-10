# i18n Router Blueprint

> A **client-side i18n routing** pattern for Next.js App Router projects using react-i18next.
> Locale detection, switching, and persistence happen on the client — no middleware, no path prefixes.
> Extracted from Soralia Village (4 languages: en, af, xh, zu).

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAYER                                │
│                                                                  │
│  providers.tsx           (tenant)/layout.tsx                    │
│  (side-effect i18n init)  (I18nextProvider context)              │
│         │                         │                              │
│         └──────────┬──────────────┘                              │
│                    ▼                                              │
│         ┌──────────────────┐                                    │
│         │  i18n instance    │  ← src/shared/lib/i18n.ts         │
│         │  (singleton)      │                                    │
│         └───────┬──────────┘                                    │
│                 │                                                │
│    ┌────────────┼────────────┐                                   │
│    ▼            ▼            ▼                                   │
│  Config      Backend      Detector                               │
│  (langs,     (HTTP        (browser:                              │
│   locales,   JSON         querystring >                          │
│   utils)     files)       cookie > localStorage                  │
│                           > navigator > htmlTag)                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              HOOK LAYER (hydration-safe)              │       │
│  │                                                      │       │
│  │  useTranslation     useSafeTranslation               │       │
│  │  (react-i18next)    (tx(key, fallback) → no         │       │
│  │                      hydration mismatch)             │       │
│  │  usePageLoading     useLanguage                      │       │
│  │  (page skeleton     (language ops only)              │       │
│  │   + breadcrumbs)                                     │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              UI LAYER                                 │       │
│  │                                                      │       │
│  │  LanguageSwitcher   LocaleSelector   LocaleAwareEditor│      │
│  │  (header <select>)  (admin dropdown)  (per-locale    │       │
│  │                                      rich text)      │       │
│  │  LocaleTabs         LocaleBadge     LocaleAwareInput │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

**Key decision**: No path-based routing (`/en/page`, `/af/page`). Locale is a client preference stored in cookie + localStorage, switched reactively without page reload. This avoids SSR complexity and hydration issues, at the cost of no per-locale static generation.

---

## Files to Create

```
src/
├── shared/lib/
│   ├── i18n-config.ts        # Supported langs, namespaces, content locale utils
│   └── i18n.ts               # i18next instance init (client-only)
├── shared/lib/hooks/
│   ├── useSafeTranslation.ts # Hydration-safe useTranslation wrapper
│   └── usePageLoading.tsx    # Page-level loading skeleton + i18n readiness
├── shared/ui/
│   └── LanguageSwitcher.tsx  # Language selector dropdown
├── features/i18n/ui/
│   ├── LocaleSelector.tsx    # Admin locale picker + copy
│   ├── LocaleAwareEditor.tsx # Per-locale rich text + input
├── app/
│   ├── providers.tsx         # Side-effect import of i18n init
│   └── (tenant)/layout.tsx   # I18nextProvider wrapper
└── public/locales/
    ├── {lang}/
    │   └── {namespace}.json  # Translation files
```

---

## Layer by Layer

### 1. Config Layer — `shared/lib/i18n-config.ts`

```typescript
export const supportedLanguages = ['en', 'af', 'xh', 'zu'] as const;
export type SupportedLanguage = (typeof supportedLanguages)[number];

export const languageNames: Record<SupportedLanguage, string> = {
  en: 'English',
  af: 'Afrikaans',
  xh: 'Xhosa',
  zu: 'Zulu',
};

export const defaultLanguage = 'en';

export const namespaces = [
  'common', 'dashboard', 'services', 'messages', 'forms',
  'resources', 'conservation', 'groups', 'interest',
  'maintenance', 'bookings', 'notifications', 'directory',
  'admin', 'platform',
];
```

**Contract**:
- `supportedLanguages` — tuple of language codes. Adopting projects replace with their own.
- `defaultLanguage` — fallback when detected language has no translation.
- `namespaces` — feature-translation boundaries; loaded on demand via HTTP backend.

**Content localization helpers** (for DB-stored JSONB content):

```typescript
export function getLocalizedValue(
  localeData: Record<string, unknown> | null | undefined,
  userLocale: string,
  fallbackLocale: string = defaultLanguage
): string | null {
  if (!localeData) return null;
  if (localeData[userLocale] && typeof localeData[userLocale] === 'string') {
    return localeData[userLocale] as string;
  }
  if (localeData[fallbackLocale] && typeof localeData[fallbackLocale] === 'string') {
    return localeData[fallbackLocale] as string;
  }
  const keys = Object.keys(localeData);
  if (keys.length > 0 && typeof localeData[keys[0]] === 'string') {
    return localeData[keys[0]] as string;
  }
  return null;
}
```

Fallback chain: `userLocale → fallbackLocale → first available → null`.

---

### 2. Init Layer — `shared/lib/i18n.ts` (client-only)

Creates and initializes the singleton i18next instance. **Must never be imported in server components** — re-exports config symbols directly from `i18n-config.ts` to avoid pulling client dependencies into server bundles.

```typescript
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import HttpBackend from 'i18next-http-backend';
import LanguageDetector from 'i18next-browser-languagedetector';
import { supportedLanguages, defaultLanguage, namespaces } from '@shared/lib';

i18n
  .use(HttpBackend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    backend: {
      loadPath: '/locales/{{lng}}/{{ns}}.json',
      queryStringParams: { v: '1' },
    },
    lng: defaultLanguage,
    fallbackLng: defaultLanguage,
    ns: namespaces,
    defaultNS: 'common',
    preload: [...supportedLanguages],
    detection: {
      order: ['querystring', 'cookie', 'localStorage', 'navigator', 'htmlTag'],
      caches: ['localStorage', 'cookie'],
      lookupQuerystring: 'lang',
      lookupCookie: 'i18next',
      lookupLocalStorage: 'i18nextLng',
    },
    interpolation: { escapeValue: false },
  });

export default i18n;
```

**Key configuration points for adopters**:
- `loadPath` — path to translation JSON files. Adjust for your public directory structure.
- `detection.order` — priority chain. `querystring` first allows easy language linking.
- `caches` — persists preference to both `localStorage` and `cookie`.
- `fallbackLng` — project's default language.

**Barrel export rule** (`shared/lib/index.ts`):

```typescript
// Do NOT export i18n.ts from the barrel. It pulls client-only deps
// (i18next-browser-languagedetector, react-i18next createContext)
// into server bundles. Export config symbols only:
export { supportedLanguages, defaultLanguage, getLocalizedValue, ... } from './i18n-config';
```

---

### 3. Provider Layer — Bootstrap

**`app/providers.tsx`** — side-effect import initializes i18n at module scope before any component mounts:

```typescript
'use client';
import '@shared/lib/i18n';   // <-- triggers i18n.init()

export function Providers({ children }: { children: React.ReactNode }) {
  // ... QueryClient, tRPC, TooltipProvider wrappers
}
```

**`app/(tenant)/layout.tsx`** — wraps tenant routes in I18nextProvider context:

```typescript
'use client';
import { I18nextProvider } from 'react-i18next';
import i18n from '@shared/lib/i18n';

export default function TenantLayout({ children }: { children: React.ReactNode }) {
  return (
    <I18nextProvider i18n={i18n}>
      {children}
    </I18nextProvider>
  );
}
```

**Rule**: Every route group that needs translations must have a wrapping layout with `I18nextProvider`.

---

### 4. Hook Layer — Hydration Safety

#### `useSafeTranslation(ns?)`

Drop-in replacement for react-i18next's `useTranslation`. Adds a `tx(key, fallback)` method that returns the hardcoded `fallback` string during SSR, preventing hydration mismatches.

```typescript
'use client';
import { useTranslation } from 'react-i18next';
import { useEffect, useState } from 'react';

export function useSafeTranslation(ns?: string | string[]) {
  const { t, i18n, ready } = useTranslation(ns);
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); }, []);

  const isReady = mounted && ready;

  const tx = (key: string, fallback: string, options?: Record<string, unknown>): string => {
    if (!mounted || !ready) return fallback;
    return t(key, { ...options, defaultValue: fallback });
  };

  return { t, tx, i18n, ready, mounted, isReady,
    language: i18n.language || defaultLanguage,
    changeLanguage: i18n.changeLanguage.bind(i18n),
  };
}
```

**Usage contract**:
- Replace `const { t } = useTranslation('ns')` with `const { tx } = useSafeTranslation('ns')`
- Replace `t('nav.home')` with `tx('nav.home', 'Home')`
- The second argument is the English fallback shown during SSR → guarantees identical server and first-client render output.

#### `usePageLoading(breadcrumbs, options?)`

Page-level hook combining hydration safety with a loading skeleton:

```typescript
export function usePageLoading(breadcrumbs: BreadcrumbItem[], options?) {
  const { isReady, tx } = useSafeTranslation();

  const LoadingComponent = !isReady ? (
    <PageLoadingSkeleton breadcrumbs={breadcrumbs} title={options.title} />
  ) : null;

  return { isReady, LoadingComponent, tx };
}
```

Usage in pages:

```typescript
'use client';
function Page() {
  const { isReady, LoadingComponent, tx } = usePageLoading([
    { label: tx('nav.home', 'Home'), href: '/' },
    { label: 'Page Title', href: '/page' },
  ]);
  if (!isReady) return LoadingComponent;
  return <div>{tx('page.content', 'Welcome')}</div>;
}
```

---

### 5. UI Layer — Components

#### `LanguageSwitcher` — Header language selector

Hydration-safe `<select>` that shows a hardcoded `en` label during SSR (via `useIsMounted()`), then renders the dropdown with `i18n.changeLanguage()` on change.

```typescript
export function LanguageSwitcher({ variant = 'dark' }: { variant?: 'light' | 'dark' }) {
  const { i18n, ready } = useTranslation();
  const isMounted = useIsMounted();

  if (!isMounted || !ready) {
    return <div>en</div>;  // Hardcoded SSR fallback
  }

  const currentLang = i18n.language || 'en';
  return (
    <select value={currentLang} onChange={e => i18n.changeLanguage(e.target.value)}>
      {supportedLanguages.map(lang => (
        <option key={lang} value={lang}>{lang.toUpperCase()}</option>
      ))}
    </select>
  );
}
```

#### `LocaleAwareEditor` / `LocaleSelector` — Admin content localization

For database content stored per-locale (JSONB `{ en: "...", af: "..." }`). Tabbed interface for editing each locale's version with a "copy to locale" feature.

---

### 6. Translation File Structure

```
public/locales/
├── en/
│   ├── common.json      # Shared UI strings (nav, footer, actions)
│   ├── dashboard.json   # Dashboard-specific
│   ├── forms.json       # Form labels, validation
│   └── ...              # One file per namespace
├── af/                  # Afrikaans
├── xh/                  # Xhosa
└── zu/                  # Zulu
```

Translation JSON uses dot-notation keys:

```json
{
  "nav": { "home": "Home", "dashboard": "Dashboard" },
  "footer": { "description": "Soralia Village", "quickLinks": "Quick Links" },
  "actions": { "save": "Save", "cancel": "Cancel", "delete": "Delete" },
  "welcome": { "message": "Welcome, {{name}}!", "guest": "Guest" }
}
```

**Missing keys**: Automatically fall back to `defaultLanguage` (configured in `i18n.ts`).

---

## Hydration Mismatch Protocol

| Scenario | Rule |
|---|---|
| Server component | ❌ No i18n. Use hardcoded English strings or pass translated content as props. |
| Client component | ✅ Use `tx(key, fallback)` from `useSafeTranslation`. |
| Layout/Nav (client) | ✅ `useSafeTranslation` with `mounted` guard. |
| Form labels/buttons | ✅ Direct `t(key)` in client components. |
| Dynamic content | ✅ Client-side only, `isReady` guard. |
| Loading skeleton | ✅ Hardcoded strings in `PageLoadingSkeleton`. |

**The `useSafeTranslation` hook is the single source of truth** — it guarantees identical SSR and first-client-render output by returning the English fallback until `mounted && ready`.

---

## Language Detection & Persistence

```
User visits site
    │
    ▼
i18next-browser-languagedetector checks (in order):
    1. URL query param ?lang=af
    2. Cookie "i18next"
    3. localStorage "i18nextLng"
    4. navigator.language (browser preference)
    5. <html lang="..."> attribute
    │
    ▼
Language set → i18n.changeLanguage(lng)
    │
    ▼
HTTP backend loads /locales/{lng}/{ns}.json for each namespace
    │
    ▼
Persisted to: localStorage + cookie (for next visit)
```

**Language switching flow** (no page reload):

```
User selects "Afrikaans" in LanguageSwitcher
    │
    ▼
i18n.changeLanguage('af')
    │
    ▼
i18next-http-backend fetches /locales/af/{ns}.json?v=1
    │
    ▼
React re-renders all components using useTranslation / useSafeTranslation
    │
    ▼
Cookie "i18next" = "af"    ← persists across sessions
localStorage "i18nextLng" = "af"
<html lang="af">            ← htmlTag detector sets this
```

---

## Adopting in a New Project

**Required dependencies**:

```json
{
  "i18next": "^25",
  "react-i18next": "^17",
  "i18next-http-backend": "^3",
  "i18next-browser-languagedetector": "^8"
}
```

**Migration steps**:

1. Copy `src/shared/lib/i18n-config.ts` — update `supportedLanguages`, `languageNames`, `defaultLanguage`, `namespaces`.
2. Copy `src/shared/lib/i18n.ts` — adjust `loadPath` and `detection` settings if needed.
3. Copy `src/shared/lib/hooks/useSafeTranslation.ts` — zero-config.
4. Copy `src/shared/lib/hooks/usePageLoading.tsx` — zero-config (adjust UI imports as needed).
5. Copy `src/shared/ui/LanguageSwitcher.tsx` — update styling for your design system.
6. Add `I18nextProvider` wrapper in your root layout.
7. Add `import '@shared/lib/i18n'` in your top-level providers.tsx (or equivalent).
8. Create translation JSON files under `public/locales/{lng}/{ns}.json`.
9. Audit all components: server components get hardcoded English or props; client components use `useSafeTranslation`.

**What to change**:

| File | Change required |
|---|---|
| `i18n-config.ts` | Languages, names, namespaces |
| `i18n.ts` | `loadPath` if public directory differs |
| `LanguageSwitcher.tsx` | Styling, theme classes |
| `translations/*.json` | All content |
| `useSafeTranslation.ts` | Nothing (generic) |
| `usePageLoading.tsx` | Loading skeleton styles |
| `providers.tsx` / `layout.tsx` | Import path for `i18n.ts` |

---

## Trade-offs

**Chosen (client-side routing)**:
- ✅ Simple setup — no middleware, no path rewriting, no i18n config in `next.config`
- ✅ Reactive language switching — no page reload
- ✅ Single set of URLs — `/dashboard` works for all languages
- ✅ Easy to adopt — copy files, change config, add translations
- ❌ No per-language static generation (ISR still works, but cached page is in one language)
- ❌ SEO — search engines see content in the detected/browser language
- ❌ SSR + hydration complexity requires careful use of `useSafeTranslation`

**Alternative (path-based, e.g., `/en/page`, `/af/page`)**:
- ✅ Per-language static generation for SEO
- ✅ Content-language hinting in URL
- ❌ Requires middleware for locale detection/redirect
- ❌ More complex routing in Next.js App Router (requires `[lng]` catch-all route group)
- ❌ Language switch requires navigation (page reload)
- ❌ More CI build time (N pages × L languages)

**When to choose client-side routing**:
- Authenticated apps where SEO is secondary
- Apps with dynamic content (user dashboards, admin panels)
- Single-page-app-like experiences
- When rapid adoption matters over SEO optimization

**When to choose path-based routing**:
- Public-facing marketing/content sites
- SEO-critical pages (landing pages, blogs, docs)
- When each language needs its own cache/CDN URL
