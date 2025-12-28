-- ============================================================================
-- Migration: Create Initial Schema for Workout Tracker
-- Purpose: Creates all tables, indexes, RLS policies, and triggers for the
--          Workout Tracker application.
-- 
-- Tables affected:
--   - users (extends auth.users)
--   - user_settings
--   - exercises
--   - templates
--   - template_exercises
--   - workouts
--   - workout_exercises
--   - sets
--
-- Notes:
--   - All tables use UUID primary keys for offline ID generation (PowerSync)
--   - Soft deletes (deleted_at) implemented for sync tombstoning
--   - Timestamps (created_at, updated_at) for conflict resolution
--   - Row Level Security (RLS) enabled on all tables
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users
-- Purpose: Extends Supabase auth.users with application-specific profile data.
--          Links to auth.users via foreign key for automatic cleanup.
-- ----------------------------------------------------------------------------
create table if not exists public.users (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Add table comment for documentation
comment on table public.users is 'Application user profiles extending auth.users';

-- ----------------------------------------------------------------------------
-- Table: user_settings
-- Purpose: Stores user preferences with 1:1 relationship to users.
--          Includes weight unit, rest timer duration, and theme preferences.
-- ----------------------------------------------------------------------------
create table if not exists public.user_settings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references public.users(id) on delete cascade,
    default_weight_unit text not null default 'kg'
        check (default_weight_unit in ('kg', 'lbs')),
    rest_timer_duration integer not null default 90
        check (rest_timer_duration > 0),
    theme text not null default 'dark'
        check (theme in ('dark', 'light', 'system')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.user_settings is 'User preferences and settings (1:1 with users)';

-- ----------------------------------------------------------------------------
-- Table: exercises
-- Purpose: Centralized table for both system-defined and user-created exercises.
--          System exercises (is_system=true) have user_id=null.
--          User exercises (is_system=false) must have user_id set.
-- ----------------------------------------------------------------------------
create table if not exists public.exercises (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    target_muscle_group text not null
        check (target_muscle_group in (
            'chest', 'back', 'shoulders', 'biceps', 'triceps', 
            'forearms', 'core', 'quadriceps', 'hamstrings', 
            'glutes', 'calves', 'full_body'
        )),
    is_system boolean not null default false,
    user_id uuid references public.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null,
    -- Constraint: system exercises must have null user_id, user exercises must have user_id set
    constraint exercises_system_user_check 
        check ((is_system = true and user_id is null) or (is_system = false and user_id is not null))
);

comment on table public.exercises is 'System and user-created exercises with muscle group classification';

-- ----------------------------------------------------------------------------
-- Table: templates
-- Purpose: Workout templates (blueprints) created by users or provided by system.
--          Templates define exercise order and default set counts.
-- ----------------------------------------------------------------------------
create table if not exists public.templates (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.users(id) on delete cascade,
    name text not null,
    is_system boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null,
    -- Constraint: system templates must have null user_id, user templates must have user_id set
    constraint templates_system_user_check 
        check ((is_system = true and user_id is null) or (is_system = false and user_id is not null))
);

comment on table public.templates is 'Workout templates/blueprints for reusable workout structures';

-- ----------------------------------------------------------------------------
-- Table: template_exercises
-- Purpose: Join table linking templates to exercises with ordering.
--          Defines which exercises are in a template and their default set count.
-- ----------------------------------------------------------------------------
create table if not exists public.template_exercises (
    id uuid primary key default gen_random_uuid(),
    template_id uuid not null references public.templates(id) on delete cascade,
    exercise_id uuid not null references public.exercises(id) on delete cascade,
    sort_order integer not null default 0,
    sets_count integer not null default 3
        check (sets_count > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.template_exercises is 'Join table linking templates to exercises with ordering';

-- ----------------------------------------------------------------------------
-- Table: workouts
-- Purpose: Represents a completed or in-progress workout session.
--          Optionally linked to a template for reference.
-- ----------------------------------------------------------------------------
create table if not exists public.workouts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    template_id uuid references public.templates(id) on delete set null,
    name text null,
    status text not null default 'IN_PROGRESS'
        check (status in ('IN_PROGRESS', 'COMPLETED')),
    started_at timestamptz not null default now(),
    completed_at timestamptz null,
    notes text null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null
);

comment on table public.workouts is 'Workout sessions (in-progress or completed)';

-- ----------------------------------------------------------------------------
-- Table: workout_exercises
-- Purpose: Join table linking workouts to exercises with ordering.
--          Represents the actual exercises performed during a workout.
-- ----------------------------------------------------------------------------
create table if not exists public.workout_exercises (
    id uuid primary key default gen_random_uuid(),
    workout_id uuid not null references public.workouts(id) on delete cascade,
    exercise_id uuid not null references public.exercises(id) on delete cascade,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null
);

comment on table public.workout_exercises is 'Join table linking workouts to exercises performed';

-- ----------------------------------------------------------------------------
-- Table: sets
-- Purpose: Individual set records within a workout exercise.
--          Tracks weight, reps, set type, and completion status.
-- ----------------------------------------------------------------------------
create table if not exists public.sets (
    id uuid primary key default gen_random_uuid(),
    workout_exercise_id uuid not null references public.workout_exercises(id) on delete cascade,
    weight numeric(6,2) not null default 0
        check (weight >= 0),
    reps integer not null default 0
        check (reps >= 0),
    set_type text not null default 'WORKING'
        check (set_type in ('WARMUP', 'WORKING', 'DROPSET', 'FAILURE')),
    is_completed boolean not null default false,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null
);

comment on table public.sets is 'Individual set records with weight, reps, and type';

-- ============================================================================
-- SECTION 2: Create Indexes
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Foreign Key Indexes (for join performance)
-- ----------------------------------------------------------------------------
create index idx_user_settings_user_id on public.user_settings(user_id);

-- Partial index for user exercises only (system exercises have null user_id)
create index idx_exercises_user_id on public.exercises(user_id) 
    where user_id is not null;

-- Partial index for user templates only
create index idx_templates_user_id on public.templates(user_id) 
    where user_id is not null;

create index idx_workouts_user_id on public.workouts(user_id);

-- Partial index for workouts with templates
create index idx_workouts_template_id on public.workouts(template_id) 
    where template_id is not null;

create index idx_template_exercises_template_id on public.template_exercises(template_id);
create index idx_template_exercises_exercise_id on public.template_exercises(exercise_id);
create index idx_workout_exercises_workout_id on public.workout_exercises(workout_id);
create index idx_workout_exercises_exercise_id on public.workout_exercises(exercise_id);
create index idx_sets_workout_exercise_id on public.sets(workout_exercise_id);

-- ----------------------------------------------------------------------------
-- Performance Indexes
-- ----------------------------------------------------------------------------

-- Composite index for "previous best" lookups (critical for <15ms retrieval requirement)
-- Used when showing last workout data for an exercise
create index idx_workout_exercises_exercise_created 
    on public.workout_exercises(exercise_id, created_at desc);

-- Index for exercise search by name (case-insensitive)
create index idx_exercises_name_lower on public.exercises(lower(name));

-- Index for filtering exercises by muscle group
create index idx_exercises_muscle_group on public.exercises(target_muscle_group);

-- Index for workout history queries (completed workouts for a user, most recent first)
create index idx_workouts_user_completed on public.workouts(user_id, completed_at desc) 
    where deleted_at is null and status = 'COMPLETED';

-- Indexes for syncing (PowerSync uses updated_at for incremental sync)
create index idx_workouts_updated on public.workouts(updated_at);
create index idx_workout_exercises_updated on public.workout_exercises(updated_at);
create index idx_sets_updated on public.sets(updated_at);

-- ----------------------------------------------------------------------------
-- Unique Indexes
-- ----------------------------------------------------------------------------

-- Unique user exercise names (case-insensitive, excluding soft-deleted)
-- Prevents duplicate exercise names per user
create unique index idx_exercises_user_name_unique 
    on public.exercises(lower(name), user_id) 
    where user_id is not null and deleted_at is null;

-- Unique system exercise names (case-insensitive, excluding soft-deleted)
create unique index idx_exercises_system_name_unique 
    on public.exercises(lower(name)) 
    where is_system = true and deleted_at is null;

-- ============================================================================
-- SECTION 3: Enable Row Level Security (RLS)
-- Purpose: Ensure data isolation between users and control access to resources.
-- ============================================================================

alter table public.users enable row level security;
alter table public.user_settings enable row level security;
alter table public.exercises enable row level security;
alter table public.templates enable row level security;
alter table public.template_exercises enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.sets enable row level security;

-- ============================================================================
-- SECTION 4: RLS Policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users - RLS Policies
-- Users can only view and update their own profile.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view their own profile
create policy "users_select_own_authenticated"
    on public.users for select
    to authenticated
    using (auth.uid() = id);

-- Policy: Allow authenticated users to update their own profile
create policy "users_update_own_authenticated"
    on public.users for update
    to authenticated
    using (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- Table: user_settings - RLS Policies
-- Users can only access and modify their own settings.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view their own settings
create policy "user_settings_select_own_authenticated"
    on public.user_settings for select
    to authenticated
    using (auth.uid() = user_id);

-- Policy: Allow authenticated users to insert their own settings
create policy "user_settings_insert_own_authenticated"
    on public.user_settings for insert
    to authenticated
    with check (auth.uid() = user_id);

-- Policy: Allow authenticated users to update their own settings
create policy "user_settings_update_own_authenticated"
    on public.user_settings for update
    to authenticated
    using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- Table: exercises - RLS Policies
-- System exercises are readable by all authenticated users.
-- User exercises are only accessible by their owner.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view system exercises
create policy "exercises_select_system_authenticated"
    on public.exercises for select
    to authenticated
    using (is_system = true);

-- Policy: Allow anon users to view system exercises (for public exercise library)
create policy "exercises_select_system_anon"
    on public.exercises for select
    to anon
    using (is_system = true);

-- Policy: Allow authenticated users to view their own exercises
create policy "exercises_select_own_authenticated"
    on public.exercises for select
    to authenticated
    using (auth.uid() = user_id);

-- Policy: Allow authenticated users to insert their own exercises (non-system only)
create policy "exercises_insert_own_authenticated"
    on public.exercises for insert
    to authenticated
    with check (auth.uid() = user_id and is_system = false);

-- Policy: Allow authenticated users to update their own exercises (non-system only)
create policy "exercises_update_own_authenticated"
    on public.exercises for update
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- Policy: Allow authenticated users to delete their own exercises (non-system only)
create policy "exercises_delete_own_authenticated"
    on public.exercises for delete
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- ----------------------------------------------------------------------------
-- Table: templates - RLS Policies
-- System templates are readable by all authenticated users.
-- User templates are only accessible by their owner.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view system templates
create policy "templates_select_system_authenticated"
    on public.templates for select
    to authenticated
    using (is_system = true);

-- Policy: Allow anon users to view system templates
create policy "templates_select_system_anon"
    on public.templates for select
    to anon
    using (is_system = true);

-- Policy: Allow authenticated users to view their own templates
create policy "templates_select_own_authenticated"
    on public.templates for select
    to authenticated
    using (auth.uid() = user_id);

-- Policy: Allow authenticated users to insert their own templates (non-system only)
create policy "templates_insert_own_authenticated"
    on public.templates for insert
    to authenticated
    with check (auth.uid() = user_id and is_system = false);

-- Policy: Allow authenticated users to update their own templates (non-system only)
create policy "templates_update_own_authenticated"
    on public.templates for update
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- Policy: Allow authenticated users to delete their own templates (non-system only)
create policy "templates_delete_own_authenticated"
    on public.templates for delete
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- ----------------------------------------------------------------------------
-- Table: template_exercises - RLS Policies
-- Users can view template exercises for templates they have access to.
-- Users can only modify template exercises for their own templates.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view template exercises for accessible templates
create policy "template_exercises_select_authenticated"
    on public.template_exercises for select
    to authenticated
    using (
        exists (
            select 1 from public.templates 
            where templates.id = template_exercises.template_id 
            and (templates.is_system = true or templates.user_id = auth.uid())
        )
    );

-- Policy: Allow anon users to view template exercises for system templates
create policy "template_exercises_select_anon"
    on public.template_exercises for select
    to anon
    using (
        exists (
            select 1 from public.templates 
            where templates.id = template_exercises.template_id 
            and templates.is_system = true
        )
    );

-- Policy: Allow authenticated users to insert template exercises for their own templates
create policy "template_exercises_insert_authenticated"
    on public.template_exercises for insert
    to authenticated
    with check (
        exists (
            select 1 from public.templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to update template exercises for their own templates
create policy "template_exercises_update_authenticated"
    on public.template_exercises for update
    to authenticated
    using (
        exists (
            select 1 from public.templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to delete template exercises for their own templates
create policy "template_exercises_delete_authenticated"
    on public.template_exercises for delete
    to authenticated
    using (
        exists (
            select 1 from public.templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- Table: workouts - RLS Policies
-- Users can only access their own workouts.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view their own workouts
create policy "workouts_select_own_authenticated"
    on public.workouts for select
    to authenticated
    using (auth.uid() = user_id);

-- Policy: Allow authenticated users to insert their own workouts
create policy "workouts_insert_own_authenticated"
    on public.workouts for insert
    to authenticated
    with check (auth.uid() = user_id);

-- Policy: Allow authenticated users to update their own workouts
create policy "workouts_update_own_authenticated"
    on public.workouts for update
    to authenticated
    using (auth.uid() = user_id);

-- Policy: Allow authenticated users to delete their own workouts
create policy "workouts_delete_own_authenticated"
    on public.workouts for delete
    to authenticated
    using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- Table: workout_exercises - RLS Policies
-- Users can only access workout exercises belonging to their workouts.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view their own workout exercises
create policy "workout_exercises_select_authenticated"
    on public.workout_exercises for select
    to authenticated
    using (
        exists (
            select 1 from public.workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to insert workout exercises for their own workouts
create policy "workout_exercises_insert_authenticated"
    on public.workout_exercises for insert
    to authenticated
    with check (
        exists (
            select 1 from public.workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to update their own workout exercises
create policy "workout_exercises_update_authenticated"
    on public.workout_exercises for update
    to authenticated
    using (
        exists (
            select 1 from public.workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to delete their own workout exercises
create policy "workout_exercises_delete_authenticated"
    on public.workout_exercises for delete
    to authenticated
    using (
        exists (
            select 1 from public.workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- Table: sets - RLS Policies
-- Users can only access sets belonging to their workout exercises.
-- ----------------------------------------------------------------------------

-- Policy: Allow authenticated users to view their own sets
create policy "sets_select_authenticated"
    on public.sets for select
    to authenticated
    using (
        exists (
            select 1 from public.workout_exercises
            join public.workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to insert sets for their own workout exercises
create policy "sets_insert_authenticated"
    on public.sets for insert
    to authenticated
    with check (
        exists (
            select 1 from public.workout_exercises
            join public.workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to update their own sets
create policy "sets_update_authenticated"
    on public.sets for update
    to authenticated
    using (
        exists (
            select 1 from public.workout_exercises
            join public.workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- Policy: Allow authenticated users to delete their own sets
create policy "sets_delete_authenticated"
    on public.sets for delete
    to authenticated
    using (
        exists (
            select 1 from public.workout_exercises
            join public.workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- ============================================================================
-- SECTION 5: Triggers
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function: update_updated_at_column
-- Purpose: Automatically updates the updated_at column on row modification.
--          Used by all tables with updated_at column for sync conflict resolution.
-- ----------------------------------------------------------------------------
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Apply updated_at trigger to all tables
create trigger update_users_updated_at
    before update on public.users
    for each row execute function update_updated_at_column();

create trigger update_user_settings_updated_at
    before update on public.user_settings
    for each row execute function update_updated_at_column();

create trigger update_exercises_updated_at
    before update on public.exercises
    for each row execute function update_updated_at_column();

create trigger update_templates_updated_at
    before update on public.templates
    for each row execute function update_updated_at_column();

create trigger update_template_exercises_updated_at
    before update on public.template_exercises
    for each row execute function update_updated_at_column();

create trigger update_workouts_updated_at
    before update on public.workouts
    for each row execute function update_updated_at_column();

create trigger update_workout_exercises_updated_at
    before update on public.workout_exercises
    for each row execute function update_updated_at_column();

create trigger update_sets_updated_at
    before update on public.sets
    for each row execute function update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Function: handle_new_user
-- Purpose: Automatically creates a user profile and default settings when a
--          new user registers via Supabase Auth.
-- Security: Uses SECURITY DEFINER to bypass RLS for this specific operation.
-- ----------------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger as $$
begin
    -- Insert user profile
    insert into public.users (id, email, created_at, updated_at)
    values (new.id, new.email, now(), now());
    
    -- Insert default user settings
    insert into public.user_settings (user_id, created_at, updated_at)
    values (new.id, now(), now());
    
    return new;
end;
$$ language plpgsql security definer;

-- Trigger: Create user profile when new auth user is created
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
