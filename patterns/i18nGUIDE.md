# i18n Guide for Soralia Village

## Overview

This project uses **react-i18next** for internationalization. The setup supports English (`en`), Afrikaans (`af`), Xhosa (`xh`), and Zulu (`zu`) languages.

## 🚨 Critical: Hydration Mismatches

**NEVER use i18n in server-rendered components that cause hydration mismatches.**

### ❌ Incorrect Usage (Causes Hydration Errors)

```tsx
// DON'T DO THIS - causes hydration mismatch
export default function Component() {
  const { t } = useTranslation('common');

  return (
    <nav>
      <a href="/">{t('nav.home')}</a> // Server: "nav.home", Client: "Home"
    </nav>
  );
}
```

### ✅ Correct Usage

**Option 1: Client-Only Components**

```tsx
'use client';

export default function Component() {
  const { t } = useTranslation('common');

  return (
    <nav>
      <a href="/">{t('nav.home')}</a> // ✅ Works - client component
    </nav>
  );
}
```

**Option 2: Hardcoded Strings for Server Components**

```tsx
// ✅ Server-safe - no i18n
export default function Breadcrumbs({ items }) {
  return (
    <nav>
      {items.map(item => (
        <a key={item.href} href={item.href}>
          {item.label} // ✅ Hardcoded English
        </a>
      ))}
    </nav>
  );
}
```

**Option 3: Client Components with Loading Check**

```tsx
'use client';

export function Header() {
  const { t, ready } = useTranslation('common');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // ✅ Show loading state until translations are ready
  if (!mounted || !ready) {
    return (
      <header>
        <nav>
          <a href="/">Home</a> {/* Hardcoded fallback */}
          <a href="/about">About</a>
        </nav>
      </header>
    );
  }

  // ✅ Safe to use translations now
  return (
    <header>
      <nav>
        <a href="/">{t('nav.home')}</a>
        <a href="/about">{t('nav.about')}</a>
      </nav>
    </header>
  );
}
```

## Component Classification

### 🟢 Server Components (No i18n)

- Layout components that are **server-rendered** (`Breadcrumbs`)
- Navigation elements in server components
- Static content without client wrapper
- Error boundaries
- Loading states

**Rule**: If it's a **pure server component** that renders on initial page load, avoid i18n.

### 🟡 Client Components (i18n OK with Pattern)

- `'use client'` components (`Header`, `Footer`)
- Interactive elements (`buttons`, `forms`, `modals`)
- Dynamic content
- User-generated content
- Real-time updates

**Rule**: Client components can use i18n if they check `mounted && ready` before rendering translations.

### 🔴 Mixed Components (Careful!)

- Dashboard widgets
- Profile pages
- Directory listings

**Rule**: Split into server + client parts, or use client-only rendering.

## Translation File Structure

```
public/locales/
├── en/
│   ├── common.json      # Shared translations
│   ├── dashboard.json   # Dashboard-specific
│   ├── directory.json   # Directory-specific
│   └── ...
├── af/
├── xh/
└── zu/
```

## Usage Patterns

### ✅ Form Labels & Buttons

```tsx
'use client';

export function LoginForm() {
  const { t } = useTranslation('auth');

  return (
    <form>
      <input placeholder={t('email.placeholder')} />
      <button>{t('login.button')}</button>
    </form>
  );
}
```

### ✅ Error Messages

```tsx
'use client';

export function ErrorDisplay({ error }) {
  const { t } = useTranslation('errors');

  return (
    <div className="error">{error.code ? t(`errors.${error.code}`) : t('errors.unknown')}</div>
  );
}
```

### ✅ Dynamic Content

```tsx
'use client';

export function WelcomeMessage({ user }) {
  const { t } = useTranslation('dashboard');

  return (
    <h1>
      {t('welcome.message', {
        name: user?.name || t('welcome.guest'),
      })}
    </h1>
  );
}
```

## Anti-Patterns

### ❌ Navigation in Server Components

```tsx
// WRONG - Server component can't use i18n
export function Breadcrumbs({ items }) {
  const { t } = useTranslation('common'); // ❌ t is undefined on server
  return (
    <nav>
      {items.map(item => (
        <a href={item.href}>{t(`nav.${item.key}`)}</a>
      ))}
    </nav>
  );
}

// ✅ Correct - Server component with hardcoded strings
export function Breadcrumbs({ items }) {
  return (
    <nav>
      {items.map(item => (
        <a href={item.href}>{item.label}</a> // ✅ Pass translated labels as props
      ))}
    </nav>
  );
}
```

### ❌ Client Components Without Loading Check

```tsx
'use client';

// WRONG - No loading check
export function Header() {
  const { t } = useTranslation('common');
  return (
    <nav>
      <a href="/">{t('nav.home')}</a> // ❌ May show "nav.home" briefly
    </nav>
  );
}

// ✅ Correct - With loading check
('use client');

export function Header() {
  const { t, ready } = useTranslation('common');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || !ready) {
    return (
      <nav>
        <a href="/">Home</a> {/* ✅ Hardcoded fallback */}
      </nav>
    );
  }

  return (
    <nav>
      <a href="/">{t('nav.home')}</a> {/* ✅ Safe to use translations */}
    </nav>
  );
}
```

### ❌ Translation Keys in Server HTML

```tsx
// WRONG
export default function Page() {
  return (
    <div>
      <h1>{t('page.title')}</h1> // t is undefined on server
    </div>
  );
}
```

### ❌ Conditional Translations

```tsx
// WRONG - creates hydration mismatch
const Component = () => {
  const { t } = useTranslation();
  const [loaded, setLoaded] = useState(false);

  return <div>{loaded ? t('loaded') : t('loading')} // Server: "loading", Client: "Loaded"</div>;
};
```

## Best Practices

### 1. Server Components

- Use hardcoded English strings
- Pass translatable content as props from client components
- Use semantic class names for styling

```tsx
// ✅ Server component
export function Card({ title, children }) {
  return (
    <div className="card">
      <h3 className="card-title">{title}</h3> // title prop from client
      {children}
    </div>
  );
}

// ✅ Client wrapper
('use client');
export function TranslatableCard() {
  const { t } = useTranslation('cards');
  return <Card title={t('stats.title')} />;
}
```

### 2. Client Components

- Import `useTranslation` at component level
- Use namespace-specific translations
- Handle loading states

```tsx
'use client';

export function DashboardWidget() {
  const { t } = useTranslation('dashboard');
  const { t: tCommon } = useTranslation('common');

  return (
    <div>
      <h3>{t('widget.title')}</h3>
      <button>{tCommon('actions.save')}</button>
    </div>
  );
}
```

### 3. Translation Keys

- Use dot notation: `nav.home`, `errors.required`
- Group by feature: `dashboard.stats.title`
- Use interpolation: `welcome.user` with `{name: 'John'}`
- Pluralization: `items.count` with `count` parameter

### 4. Loading States

```tsx
'use client';

export function App() {
  const { ready } = useTranslation();

  if (!ready) {
    return <div>Loading translations...</div>; // Hardcoded - no i18n here
  }

  return <MainApp />;
}
```

## Migration Guide

### Converting Server Components

**Before:**

```tsx
export function Breadcrumbs({ items }) {
  const { t } = useTranslation('common');
  return (
    <nav>
      {items.map(item => (
        <a href={item.href}>{t(`nav.${item.key}`)}</a>
      ))}
    </nav>
  );
}
```

**After:**

```tsx
// Option 1: Hardcoded
export function Breadcrumbs({ items }) {
  return (
    <nav>
      {items.map(item => (
        <a href={item.href}>{item.label}</a> // Pass translated label as prop
      ))}
    </nav>
  );
}

// Option 2: Client-only
('use client');
export function Breadcrumbs({ items }) {
  const { t } = useTranslation('common');
  return (
    <nav>
      {items.map(item => (
        <a href={item.href}>{t(`nav.${item.key}`)}</a>
      ))}
    </nav>
  );
}
```

## Testing i18n

### Unit Tests

```tsx
import { render } from '@testing-library/react';
import { I18nextProvider } from 'react-i18next';
import i18n from '@/lib/i18n';

const renderWithI18n = component => {
  return render(<I18nextProvider i18n={i18n}>{component}</I18nextProvider>);
};
```

### E2E Tests

- Test language switching
- Verify translations load correctly
- Check for missing translation keys

## Performance Considerations

1. **Bundle Splitting**: Load language files on-demand
2. **Preloading**: Preload common translations
3. **Caching**: Cache translations in service worker
4. **Lazy Loading**: Load translations for current page only

## Current Implementation Status

### Breadcrumb i18n Across Pages

| Page              | Status   | Implementation                              |
| ----------------- | -------- | ------------------------------------------- |
| Header/Footer     | ✅ Safe  | Client components with mounted/ready checks |
| directory         | ✅ Fixed | Using `usePageLoading` hook                 |
| conservation      | ✅ Fixed | Using `usePageLoading` hook                 |
| settings          | ✅ Fixed | Using `usePageLoading` hook                 |
| services          | ✅ Fixed | Using `usePageLoading` hook                 |
| home (page.tsx)   | ✅ Safe  | Has `!mounted \|\| !ready` check            |
| **bookings**      | ✅ Fixed | Using `usePageLoading` hook                 |
| **messages**      | ✅ Fixed | Using `usePageLoading` hook                 |
| **maintenance**   | ✅ Fixed | Using `usePageLoading` hook                 |
| **groups**        | ✅ Fixed | Using `usePageLoading` hook                 |
| **resources**     | ✅ Fixed | Using `usePageLoading` hook                 |
| **notifications** | ✅ Fixed | Using `usePageLoading` hook                 |
| **interest**      | ✅ Fixed | Using `usePageLoading` hook                 |
| dashboard         | ✅ Fixed | Using `usePageLoading` hook                 |
| member            | ✅ Fixed | Hardcoded after hydration issues            |

## Common Issues

### 1. Hydration Mismatch

**Symptoms**: Console errors, flickering content
**Fix**: Remove i18n from server components

### 2. Missing Translations

**Symptoms**: Shows translation keys like `auth.login.button`
**Fix**: Add missing keys to translation files

### 3. Language Not Switching

**Symptoms**: Language selector doesn't work
**Fix**: Check i18n configuration and cookie settings

### 4. SSR Issues

**Symptoms**: Translations not working on initial load
**Fix**: Ensure translations are loaded server-side

### 5. Hydration Mismatches in Breadcrumbs

**Symptoms**: Console hydration errors, flickering breadcrumb text
**Status**: ✅ **FULLY RESOLVED** - All pages now use `usePageLoading` hook
**Root Cause**: Client components using `t('nav.home')` without loading checks
**Fix**: Standardized `usePageLoading` hook provides consistent loading patterns
**Coverage**: Found and fixed additional instances in directory, conservation, settings, and services pages

## Quick Reference

| Component Type             | i18n Allowed | Solution                            |
| -------------------------- | ------------ | ----------------------------------- |
| Server Components          | ❌           | Hardcoded strings                   |
| Client Components          | ✅           | `useTranslation` with loading check |
| Layout/Navigation (Server) | ❌           | Props from client or hardcoded      |
| Layout/Navigation (Client) | ✅           | Loading check pattern               |
| Forms/Buttons              | ✅           | Direct translation                  |
| Static Content             | ❌           | Hardcoded or props                  |
| Dynamic Content            | ✅           | Client-side only                    |

**Remember**: When in doubt, avoid i18n in server-rendered components. It's easier to add i18n later than fix hydration bugs.</content>
<parameter name="filePath">/home/ubuntupunk/Projects/soralia-village/docs/i18nGUIDE.md
