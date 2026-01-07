-- =============================================================================
-- migration: create_initial_schema
-- purpose: create the complete database schema for workout tracker application
-- affected tables: users, user_settings, exercises, templates, template_exercises,
--                  workouts, workout_exercises, sets
-- notes:
--   - all tables use uuid primary keys for offline id generation (powersync)
--   - soft deletes (deleted_at) implemented for sync tombstoning
--   - all weights stored in kg as numeric(6,2)
--   - rls enabled on all tables with granular policies per role
-- =============================================================================

-- =============================================================================
-- section 1: helper functions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- function: update_updated_at_column
-- purpose: automatically updates the updated_at column on row modification
-- used by: all tables with updated_at column via before update triggers
-- -----------------------------------------------------------------------------
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- -----------------------------------------------------------------------------
-- function: handle_new_user
-- purpose: automatically creates public.users and public.user_settings records
--          when a new auth.users record is created
-- security: definer to allow access to auth schema
-- -----------------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger as $$
begin
    insert into public.users (id, email, created_at, updated_at)
    values (new.id, new.email, now(), now());
    
    insert into public.user_settings (user_id, created_at, updated_at)
    values (new.id, now(), now());
    
    return new;
end;
$$ language plpgsql security definer;

-- =============================================================================
-- section 2: tables
-- =============================================================================

-- -----------------------------------------------------------------------------
-- table: users
-- purpose: stores user profile data, linked to auth.users
-- note: this table is managed alongside supabase auth
-- -----------------------------------------------------------------------------
create table users (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- enable rls - users can only access their own profile
alter table users enable row level security;

-- -----------------------------------------------------------------------------
-- table: user_settings
-- purpose: stores user preferences (1:1 relationship with users)
-- constraints: 
--   - default_weight_unit must be 'kg' or 'lbs'
--   - rest_timer_duration must be positive
--   - theme must be 'dark', 'light', or 'system'
-- -----------------------------------------------------------------------------
create table user_settings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references users(id) on delete cascade,
    default_weight_unit text not null default 'kg' 
        check (default_weight_unit in ('kg', 'lbs')),
    rest_timer_duration integer not null default 90 
        check (rest_timer_duration > 0),
    theme text not null default 'dark' 
        check (theme in ('dark', 'light', 'system')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- enable rls - users can only access their own settings
alter table user_settings enable row level security;

-- -----------------------------------------------------------------------------
-- table: exercises
-- purpose: centralized table for both system-defined and user-created exercises
-- constraints:
--   - if is_system = true, user_id must be null (system exercises)
--   - if is_system = false, user_id must not be null (user exercises)
-- soft delete: uses deleted_at for sync tombstoning
-- -----------------------------------------------------------------------------
create table exercises (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    target_muscle_group text not null,
    is_system boolean not null default false,
    user_id uuid references users(id) on delete cascade,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null,
    -- ensure system exercises have no user_id, user exercises have user_id
    constraint exercises_system_user_check 
        check ((is_system = true and user_id is null) or (is_system = false and user_id is not null))
);

-- enable rls - system exercises readable by all, user exercises only by owner
alter table exercises enable row level security;

-- -----------------------------------------------------------------------------
-- table: templates
-- purpose: workout templates (blueprints) created by users or provided by system
-- constraints:
--   - if is_system = true, user_id must be null (system templates)
--   - if is_system = false, user_id must not be null (user templates)
-- soft delete: uses deleted_at for sync tombstoning
-- -----------------------------------------------------------------------------
create table templates (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references users(id) on delete cascade,
    name text not null,
    is_system boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null,
    -- ensure system templates have no user_id, user templates have user_id
    constraint templates_system_user_check 
        check ((is_system = true and user_id is null) or (is_system = false and user_id is not null))
);

-- enable rls - system templates readable by all, user templates only by owner
alter table templates enable row level security;

-- -----------------------------------------------------------------------------
-- table: template_exercises
-- purpose: join table linking templates to exercises with ordering
-- note: no soft delete as template deletion cascades to these records
-- -----------------------------------------------------------------------------
create table template_exercises (
    id uuid primary key default gen_random_uuid(),
    template_id uuid not null references templates(id) on delete cascade,
    exercise_id uuid not null references exercises(id) on delete cascade,
    sort_order integer not null default 0,
    sets_count integer not null default 3 check (sets_count > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- enable rls - access controlled via parent template
alter table template_exercises enable row level security;

-- -----------------------------------------------------------------------------
-- table: workouts
-- purpose: represents a completed or in-progress workout session
-- constraints:
--   - status must be 'IN_PROGRESS' or 'COMPLETED'
--   - template_id set to null if template is deleted (preserves workout history)
-- soft delete: uses deleted_at for sync tombstoning
-- -----------------------------------------------------------------------------
create table workouts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    template_id uuid references templates(id) on delete set null,
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

-- enable rls - users can only access their own workouts
alter table workouts enable row level security;

-- -----------------------------------------------------------------------------
-- table: workout_exercises
-- purpose: join table linking workouts to exercises with ordering
-- soft delete: uses deleted_at for sync tombstoning
-- -----------------------------------------------------------------------------
create table workout_exercises (
    id uuid primary key default gen_random_uuid(),
    workout_id uuid not null references workouts(id) on delete cascade,
    exercise_id uuid not null references exercises(id) on delete cascade,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null
);

-- enable rls - access controlled via parent workout
alter table workout_exercises enable row level security;

-- -----------------------------------------------------------------------------
-- table: sets
-- purpose: individual set records within a workout exercise
-- constraints:
--   - weight must be >= 0 (stored in kg as numeric(6,2))
--   - reps must be >= 0
--   - set_type must be one of: 'WARMUP', 'WORKING', 'DROPSET', 'FAILURE'
-- soft delete: uses deleted_at for sync tombstoning
-- -----------------------------------------------------------------------------
create table sets (
    id uuid primary key default gen_random_uuid(),
    workout_exercise_id uuid not null references workout_exercises(id) on delete cascade,
    weight numeric(6,2) not null default 0 check (weight >= 0),
    reps integer not null default 0 check (reps >= 0),
    set_type text not null default 'WORKING' 
        check (set_type in ('WARMUP', 'WORKING', 'DROPSET', 'FAILURE')),
    is_completed boolean not null default false,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz null
);

-- enable rls - access controlled via parent workout
alter table sets enable row level security;

-- =============================================================================
-- section 3: indexes
-- =============================================================================

-- -----------------------------------------------------------------------------
-- foreign key indexes (for join performance)
-- -----------------------------------------------------------------------------
create index idx_user_settings_user_id on user_settings(user_id);
create index idx_exercises_user_id on exercises(user_id) where user_id is not null;
create index idx_templates_user_id on templates(user_id) where user_id is not null;
create index idx_workouts_user_id on workouts(user_id);
create index idx_workouts_template_id on workouts(template_id) where template_id is not null;
create index idx_template_exercises_template_id on template_exercises(template_id);
create index idx_template_exercises_exercise_id on template_exercises(exercise_id);
create index idx_workout_exercises_workout_id on workout_exercises(workout_id);
create index idx_workout_exercises_exercise_id on workout_exercises(exercise_id);
create index idx_sets_workout_exercise_id on sets(workout_exercise_id);

-- -----------------------------------------------------------------------------
-- performance indexes
-- -----------------------------------------------------------------------------

-- composite index for "previous best" lookups (critical for <15ms retrieval)
create index idx_workout_exercises_exercise_created 
    on workout_exercises(exercise_id, created_at desc);

-- index for exercise search by name (case-insensitive)
create index idx_exercises_name_lower on exercises(lower(name));

-- index for filtering exercises by muscle group
create index idx_exercises_muscle_group on exercises(target_muscle_group);

-- index for workout history queries (completed workouts, most recent first)
create index idx_workouts_user_completed on workouts(user_id, completed_at desc) 
    where deleted_at is null and status = 'COMPLETED';

-- indexes for syncing (powersync uses updated_at for incremental sync)
create index idx_workouts_updated on workouts(updated_at);
create index idx_workout_exercises_updated on workout_exercises(updated_at);
create index idx_sets_updated on sets(updated_at);

-- -----------------------------------------------------------------------------
-- unique indexes
-- -----------------------------------------------------------------------------

-- unique user exercise names (case-insensitive, excluding soft-deleted)
-- ensures users cannot create duplicate exercise names
create unique index idx_exercises_user_name_unique 
    on exercises(lower(name), user_id) 
    where user_id is not null and deleted_at is null;

-- unique system exercise names (case-insensitive, excluding soft-deleted)
-- ensures system exercises have unique names
create unique index idx_exercises_system_name_unique 
    on exercises(lower(name)) 
    where is_system = true and deleted_at is null;

-- =============================================================================
-- section 4: row level security (rls) policies
-- =============================================================================

-- -----------------------------------------------------------------------------
-- users table policies
-- purpose: users can only view and update their own profile
-- note: insert is handled by handle_new_user trigger, delete cascades from auth
-- -----------------------------------------------------------------------------

-- authenticated users can view their own profile
create policy "authenticated_users_select_own_profile"
    on users for select
    to authenticated
    using (auth.uid() = id);

-- authenticated users can update their own profile
create policy "authenticated_users_update_own_profile"
    on users for update
    to authenticated
    using (auth.uid() = id);

-- anon users cannot access users table (no policies for anon role)

-- -----------------------------------------------------------------------------
-- user_settings table policies
-- purpose: users can only access their own settings
-- -----------------------------------------------------------------------------

-- authenticated users can view their own settings
create policy "authenticated_users_select_own_settings"
    on user_settings for select
    to authenticated
    using (auth.uid() = user_id);

-- authenticated users can insert their own settings (backup if trigger fails)
create policy "authenticated_users_insert_own_settings"
    on user_settings for insert
    to authenticated
    with check (auth.uid() = user_id);

-- authenticated users can update their own settings
create policy "authenticated_users_update_own_settings"
    on user_settings for update
    to authenticated
    using (auth.uid() = user_id);

-- anon users cannot access user_settings table (no policies for anon role)

-- -----------------------------------------------------------------------------
-- exercises table policies
-- purpose: system exercises are readable by all authenticated users,
--          user exercises are only accessible by their owner
-- -----------------------------------------------------------------------------

-- authenticated users can view system exercises (available to everyone)
create policy "authenticated_users_select_system_exercises"
    on exercises for select
    to authenticated
    using (is_system = true);

-- authenticated users can view their own custom exercises
create policy "authenticated_users_select_own_exercises"
    on exercises for select
    to authenticated
    using (auth.uid() = user_id);

-- authenticated users can insert their own exercises (must be non-system)
create policy "authenticated_users_insert_own_exercises"
    on exercises for insert
    to authenticated
    with check (auth.uid() = user_id and is_system = false);

-- authenticated users can update their own exercises (cannot modify system)
create policy "authenticated_users_update_own_exercises"
    on exercises for update
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- authenticated users can delete (soft-delete) their own exercises
create policy "authenticated_users_delete_own_exercises"
    on exercises for delete
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- anon users can view system exercises (for preview/marketing purposes)
create policy "anon_users_select_system_exercises"
    on exercises for select
    to anon
    using (is_system = true);

-- -----------------------------------------------------------------------------
-- templates table policies
-- purpose: system templates are readable by all authenticated users,
--          user templates are only accessible by their owner
-- -----------------------------------------------------------------------------

-- authenticated users can view system templates
create policy "authenticated_users_select_system_templates"
    on templates for select
    to authenticated
    using (is_system = true);

-- authenticated users can view their own templates
create policy "authenticated_users_select_own_templates"
    on templates for select
    to authenticated
    using (auth.uid() = user_id);

-- authenticated users can insert their own templates (must be non-system)
create policy "authenticated_users_insert_own_templates"
    on templates for insert
    to authenticated
    with check (auth.uid() = user_id and is_system = false);

-- authenticated users can update their own templates
create policy "authenticated_users_update_own_templates"
    on templates for update
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- authenticated users can delete (soft-delete) their own templates
create policy "authenticated_users_delete_own_templates"
    on templates for delete
    to authenticated
    using (auth.uid() = user_id and is_system = false);

-- anon users can view system templates (for preview/marketing purposes)
create policy "anon_users_select_system_templates"
    on templates for select
    to anon
    using (is_system = true);

-- -----------------------------------------------------------------------------
-- template_exercises table policies
-- purpose: access controlled via parent template ownership
-- -----------------------------------------------------------------------------

-- authenticated users can view template_exercises for accessible templates
-- (either system templates or own templates)
create policy "authenticated_users_select_template_exercises"
    on template_exercises for select
    to authenticated
    using (
        exists (
            select 1 from templates 
            where templates.id = template_exercises.template_id 
            and (templates.is_system = true or templates.user_id = auth.uid())
        )
    );

-- authenticated users can insert template_exercises for their own templates
create policy "authenticated_users_insert_template_exercises"
    on template_exercises for insert
    to authenticated
    with check (
        exists (
            select 1 from templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- authenticated users can update template_exercises for their own templates
create policy "authenticated_users_update_template_exercises"
    on template_exercises for update
    to authenticated
    using (
        exists (
            select 1 from templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- authenticated users can delete template_exercises for their own templates
create policy "authenticated_users_delete_template_exercises"
    on template_exercises for delete
    to authenticated
    using (
        exists (
            select 1 from templates 
            where templates.id = template_exercises.template_id 
            and templates.user_id = auth.uid()
        )
    );

-- anon users can view template_exercises for system templates
create policy "anon_users_select_template_exercises"
    on template_exercises for select
    to anon
    using (
        exists (
            select 1 from templates 
            where templates.id = template_exercises.template_id 
            and templates.is_system = true
        )
    );

-- -----------------------------------------------------------------------------
-- workouts table policies
-- purpose: users can only access their own workouts
-- -----------------------------------------------------------------------------

-- authenticated users can view their own workouts
create policy "authenticated_users_select_own_workouts"
    on workouts for select
    to authenticated
    using (auth.uid() = user_id);

-- authenticated users can insert their own workouts
create policy "authenticated_users_insert_own_workouts"
    on workouts for insert
    to authenticated
    with check (auth.uid() = user_id);

-- authenticated users can update their own workouts
create policy "authenticated_users_update_own_workouts"
    on workouts for update
    to authenticated
    using (auth.uid() = user_id);

-- authenticated users can delete (soft-delete) their own workouts
create policy "authenticated_users_delete_own_workouts"
    on workouts for delete
    to authenticated
    using (auth.uid() = user_id);

-- anon users cannot access workouts table (no policies for anon role)

-- -----------------------------------------------------------------------------
-- workout_exercises table policies
-- purpose: access controlled via parent workout ownership
-- -----------------------------------------------------------------------------

-- authenticated users can view workout_exercises for their own workouts
create policy "authenticated_users_select_workout_exercises"
    on workout_exercises for select
    to authenticated
    using (
        exists (
            select 1 from workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can insert workout_exercises for their own workouts
create policy "authenticated_users_insert_workout_exercises"
    on workout_exercises for insert
    to authenticated
    with check (
        exists (
            select 1 from workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can update workout_exercises for their own workouts
create policy "authenticated_users_update_workout_exercises"
    on workout_exercises for update
    to authenticated
    using (
        exists (
            select 1 from workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can delete workout_exercises for their own workouts
create policy "authenticated_users_delete_workout_exercises"
    on workout_exercises for delete
    to authenticated
    using (
        exists (
            select 1 from workouts 
            where workouts.id = workout_exercises.workout_id 
            and workouts.user_id = auth.uid()
        )
    );

-- anon users cannot access workout_exercises table (no policies for anon role)

-- -----------------------------------------------------------------------------
-- sets table policies
-- purpose: access controlled via parent workout ownership (through workout_exercises)
-- -----------------------------------------------------------------------------

-- authenticated users can view sets for their own workouts
create policy "authenticated_users_select_sets"
    on sets for select
    to authenticated
    using (
        exists (
            select 1 from workout_exercises
            join workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can insert sets for their own workouts
create policy "authenticated_users_insert_sets"
    on sets for insert
    to authenticated
    with check (
        exists (
            select 1 from workout_exercises
            join workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can update sets for their own workouts
create policy "authenticated_users_update_sets"
    on sets for update
    to authenticated
    using (
        exists (
            select 1 from workout_exercises
            join workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- authenticated users can delete sets for their own workouts
create policy "authenticated_users_delete_sets"
    on sets for delete
    to authenticated
    using (
        exists (
            select 1 from workout_exercises
            join workouts on workouts.id = workout_exercises.workout_id
            where workout_exercises.id = sets.workout_exercise_id 
            and workouts.user_id = auth.uid()
        )
    );

-- anon users cannot access sets table (no policies for anon role)

-- =============================================================================
-- section 5: triggers
-- =============================================================================

-- -----------------------------------------------------------------------------
-- updated_at triggers
-- purpose: automatically update updated_at column on row modification
-- -----------------------------------------------------------------------------

create trigger update_users_updated_at
    before update on users
    for each row execute function update_updated_at_column();

create trigger update_user_settings_updated_at
    before update on user_settings
    for each row execute function update_updated_at_column();

create trigger update_exercises_updated_at
    before update on exercises
    for each row execute function update_updated_at_column();

create trigger update_templates_updated_at
    before update on templates
    for each row execute function update_updated_at_column();

create trigger update_template_exercises_updated_at
    before update on template_exercises
    for each row execute function update_updated_at_column();

create trigger update_workouts_updated_at
    before update on workouts
    for each row execute function update_updated_at_column();

create trigger update_workout_exercises_updated_at
    before update on workout_exercises
    for each row execute function update_updated_at_column();

create trigger update_sets_updated_at
    before update on sets
    for each row execute function update_updated_at_column();

-- -----------------------------------------------------------------------------
-- user creation trigger
-- purpose: auto-create public.users and public.user_settings when auth user created
-- -----------------------------------------------------------------------------

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

-- =============================================================================
-- end of migration
-- =============================================================================
