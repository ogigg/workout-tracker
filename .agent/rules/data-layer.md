---
description: Data layer, Drizzle ORM, and PowerSync (Offline-First) guidelines
globs: apps/mobile/**/*.ts
---

# Data Layer & Offline-First Guidelines

## Core Principles
- **Source of Truth**: The local **SQLite** database is the primary source of truth for the UI.
- **ORM**: Use **Drizzle ORM** for all database interactions.
- **Sync**: Use **PowerSync** for background synchronization between SQLite and Supabase.
- **Migrations**: Maintain a `schema.ts` and use Drizzle-kit to manage migrations.

## Drizzle Best Practices
- **Schema**: Define strict TypeScript schemas in `features/[feature]/schema.ts` or a central `db/schema.ts`.
- **Typing**: Use `InferSelectModel` and `InferInsertModel` to generate types from schemas.
- **Queries**: Use the relational query API (`db.query.findMany`) for complex joins and the core SQL-like API for simple CRUD.

## PowerSync & Offline Patterns
- **Sync Rules**: PowerSync handles the data movement. Ensure Supabase RLS policies are correctly mirrored in PowerSync sync rules.
- **Optimistic UI**: Perform writes to the local SQLite DB immediately. The UI should update before the sync to Supabase is confirmed.
- **Conflict Resolution**: Follow the "Last Write Wins" strategy as per PRD. Ensure every record has an `updated_at` timestamp.
- **Connectivity**: Use `NetInfo` or TanStack Query's internal state to show sync status indicators to the user.

## Security
- Never bypass Supabase RLS.
- Use Supabase Auth for all authenticated DB requests through the PowerSync connector.
