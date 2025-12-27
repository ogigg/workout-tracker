---
description: General React Native, Expo, and TypeScript architecture guidelines
globs: apps/mobile/**/*.ts, apps/mobile/**/*.tsx
---

# React Native & Expo: General Architecture

## Core Principles
- **Architecture**: Use a **Feature-based** folder structure (e.g., `features/authentication`, `features/workouts`).
- **Components**: Prefer Functional Components with Hooks. Use `memo` sparingly, only for performance-heavy components.
- **TypeScript**: Strict type safety. Avoid `any`. Define interfaces/types for all component props and hook returns.
- **Expo**: Leverage Expo Router for file-based navigation. Use `Expo SDK` modules directly for native functionality.

## Folder Structure
```text
apps/mobile/
├── app/                  # Expo Router (Navigation & screens)
├── components/           # Shared UI components (UI primitives)
├── features/             # Business modules (Domain logic + Feature UI)
│   └── feature-name/
│       ├── api/          # Query/Mutation hooks
│       ├── components/   # Feature-specific components
│       ├── store/        # Zustand stores
│       ├── types/        # TypeScript interfaces
│       └── utils/        # Feature helpers
├── hooks/                # Shared custom hooks
├── services/             # External service wrappers (Supabase, etc.)
├── constants/            # Global constants (Theme, Config)
└── utils/                # Global utility functions
```

## Component Guidelines
1.  **One Component Per File**: Export as default or named (be consistent).
2.  **Naming**: `PascalCase` for components, `camelCase` for hooks and variables.
3.  **Hooks First**: Extract complex logic into custom hooks within the feature directory.
4.  **No Logic in Views**: Keep JSX files focused on structure; move calculations and data fetching to specialized hooks.

## TypeScript Best Practices
- Use `type` for simple data structures and `interface` for extendable objects.
- Prefer `Record<K, V>` over `{ [key: string]: any }`.
- Utilize `satisfies` operator for strict configuration objects.
- Leverage Discriminated Unions for complex component states (e.g., Loading/Error/Success).
