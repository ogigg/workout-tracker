---
description: State management rules (Zustand and TanStack Query)
globs: apps/mobile/**/*.ts, apps/mobile/**/*.tsx
---

# State Management Guidelines

## Core Principles
- **Global UI State**: Use **Zustand**. Keep stores small and focused on specific features.
- **Server/Remote State**: Use **TanStack Query**. Handle all data fetching, caching, and synchronization through queries and mutations.
- **Component State**: Use `useState` for isolated, component-specific logic that doesn't need to persist or be shared.

## TanStack Query Best Practices
- **Custom Hooks**: Wrap every query and mutation in a custom hook (e.g., `useExercises`, `useSaveWorkout`).
- **Query Keys**: Centralize query keys in a `queryKeys` object or function to avoid typos.
- **Stale Time**: Configure `staleTime` appropriately. For a workout tracker, the DB is the source of truth, so aggressive caching is fine.
- **Mutations**: Always implement `onMutate` for optimistic updates to provide a "lightning-fast" UI experience.

## Zustand Best Practices
- **Selectors**: Always use selectors to extract state (e.g., `const user = useUserStore(s => s.user)`) to prevent unnecessary re-renders.
- **Actions**: Define actions within the store to keep logic encapsulated.
- **Immer**: Use the `immer` middleware if managing complex nested state objects.
- **Persistance**: Use the `persist` middleware for state that should survive app restarts (e.g., user settings).

## Local-First Strategy
- Since the app uses **PowerSync**, TanStack Query should primarily interact with the **local SQLite DB via Drizzle**.
- The "Server State" in this project is effectively the "Synchronized Local State".
