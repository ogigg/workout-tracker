/**
 * DTO and Command Model Types for Workout Tracker API
 *
 * These types are derived from database entity definitions in db.ts
 * and align with the REST API plan specifications.
 */

import type { Database } from './db';

// =============================================================================
// Base Table Types - derived from Database schema
// =============================================================================

/** Row types from database tables */
type ExerciseRow = Database['public']['Tables']['exercises']['Row'];
type SetRow = Database['public']['Tables']['sets']['Row'];
type TemplateRow = Database['public']['Tables']['templates']['Row'];
type TemplateExerciseRow = Database['public']['Tables']['template_exercises']['Row'];
type UserSettingsRow = Database['public']['Tables']['user_settings']['Row'];
type WorkoutRow = Database['public']['Tables']['workouts']['Row'];
type WorkoutExerciseRow = Database['public']['Tables']['workout_exercises']['Row'];

/** Insert types from database tables */
type ExerciseInsert = Database['public']['Tables']['exercises']['Insert'];
type SetInsert = Database['public']['Tables']['sets']['Insert'];
type TemplateInsert = Database['public']['Tables']['templates']['Insert'];
type TemplateExerciseInsert = Database['public']['Tables']['template_exercises']['Insert'];
type UserSettingsInsert = Database['public']['Tables']['user_settings']['Insert'];
type WorkoutInsert = Database['public']['Tables']['workouts']['Insert'];
type WorkoutExerciseInsert = Database['public']['Tables']['workout_exercises']['Insert'];

/** Update types from database tables */
type ExerciseUpdate = Database['public']['Tables']['exercises']['Update'];
type SetUpdate = Database['public']['Tables']['sets']['Update'];
type TemplateUpdate = Database['public']['Tables']['templates']['Update'];
type TemplateExerciseUpdate = Database['public']['Tables']['template_exercises']['Update'];
type UserSettingsUpdate = Database['public']['Tables']['user_settings']['Update'];
type WorkoutUpdate = Database['public']['Tables']['workouts']['Update'];
type WorkoutExerciseUpdate = Database['public']['Tables']['workout_exercises']['Update'];

// =============================================================================
// Enums and Literal Types
// =============================================================================

/** Valid weight units for user settings */
export type WeightUnit = 'kg' | 'lbs';

/** Valid theme options for user settings */
export type Theme = 'dark' | 'light' | 'system';

/** Valid target muscle groups for exercises */
export type TargetMuscleGroup =
  | 'chest'
  | 'back'
  | 'shoulders'
  | 'biceps'
  | 'triceps'
  | 'forearms'
  | 'core'
  | 'quadriceps'
  | 'hamstrings'
  | 'glutes'
  | 'calves'
  | 'full_body';

/** Valid workout statuses */
export type WorkoutStatus = 'IN_PROGRESS' | 'COMPLETED';

/** Valid set types */
export type SetType = 'WARMUP' | 'WORKING' | 'DROPSET' | 'FAILURE';

// =============================================================================
// DTOs (Data Transfer Objects) - Response Types
// =============================================================================

// -----------------------------------------------------------------------------
// User Settings DTOs
// -----------------------------------------------------------------------------

/**
 * User settings DTO - returned from GET /rest/v1/user_settings
 * Directly maps to user_settings table Row type
 */
export type UserSettingsDTO = UserSettingsRow;

// -----------------------------------------------------------------------------
// Exercise DTOs
// -----------------------------------------------------------------------------

/**
 * Exercise DTO - returned from GET /rest/v1/exercises
 * Omits deleted_at as soft-deleted exercises are filtered by default
 */
export type ExerciseDTO = Omit<ExerciseRow, 'deleted_at'>;

/**
 * Exercise list item DTO - simplified version for lists
 */
export type ExerciseListItemDTO = Pick<
  ExerciseRow,
  'id' | 'name' | 'target_muscle_group' | 'is_system'
>;

// -----------------------------------------------------------------------------
// Template DTOs
// -----------------------------------------------------------------------------

/**
 * Template exercise DTO - used within template responses
 * Represents an exercise within a template
 */
export type TemplateExerciseDTO = Pick<
  TemplateExerciseRow,
  'id' | 'exercise_id' | 'sort_order' | 'sets_count'
>;

/**
 * Template exercise with full exercise details
 * Used when fetching template with nested exercise information
 */
export interface TemplateExerciseWithExerciseDTO extends TemplateExerciseDTO {
  exercises: ExerciseDTO;
}

/**
 * Basic template DTO - returned from GET /rest/v1/templates
 * Omits deleted_at as soft-deleted templates are filtered by default
 */
export type TemplateDTO = Omit<TemplateRow, 'deleted_at'>;

/**
 * Template with exercises DTO - returned when using select=*,template_exercises(*)
 */
export interface TemplateWithExercisesDTO extends TemplateDTO {
  template_exercises: TemplateExerciseDTO[];
}

/**
 * Template with full exercise details DTO
 * Returned when using select=*,template_exercises(*,exercises(*))
 */
export interface TemplateWithFullExercisesDTO extends TemplateDTO {
  template_exercises: TemplateExerciseWithExerciseDTO[];
}

// -----------------------------------------------------------------------------
// Workout DTOs
// -----------------------------------------------------------------------------

/**
 * Set DTO - returned from GET /rest/v1/sets
 * Omits deleted_at as soft-deleted sets are filtered by default
 */
export type SetDTO = Omit<SetRow, 'deleted_at'>;

/**
 * Workout exercise DTO - basic version
 * Omits deleted_at as soft-deleted workout exercises are filtered by default
 */
export type WorkoutExerciseDTO = Omit<WorkoutExerciseRow, 'deleted_at'>;

/**
 * Workout exercise with full details
 * Used when fetching workout with nested exercise and sets information
 */
export interface WorkoutExerciseWithDetailsDTO extends WorkoutExerciseDTO {
  exercise: ExerciseDTO;
  sets: SetDTO[];
}

/**
 * Template reference for workout - minimal template info
 */
export interface TemplateReferenceDTO {
  name: string;
}

/**
 * Basic workout DTO - returned from GET /rest/v1/workouts (list)
 * Omits deleted_at as soft-deleted workouts are filtered by default
 */
export type WorkoutDTO = Omit<WorkoutRow, 'deleted_at'>;

/**
 * Workout list item DTO - with optional template name
 */
export interface WorkoutListItemDTO extends WorkoutDTO {
  template?: TemplateReferenceDTO | null;
}

/**
 * Full workout detail DTO - returned when fetching single workout with all nested data
 * select=*,workout_exercises(*,exercise:exercises(*),sets(*))
 */
export interface WorkoutDetailDTO extends WorkoutDTO {
  workout_exercises: WorkoutExerciseWithDetailsDTO[];
}

// -----------------------------------------------------------------------------
// RPC Response DTOs
// -----------------------------------------------------------------------------

/**
 * Previous best data for an exercise - returned from get_previous_best RPC
 * Used for progressive overload context display
 */
export interface PreviousBestDTO {
  weight: number;
  reps: number;
  workout_date: string;
}

/**
 * New record item within workout summary
 */
export interface NewRecordDTO {
  exercise_name: string;
  weight: number;
  reps: number;
}

/**
 * Workout summary - returned from get_workout_summary RPC
 * Contains calculated metrics and new records
 */
export interface WorkoutSummaryDTO {
  total_volume: number;
  total_sets: number;
  total_reps: number;
  exercises_count: number;
  new_records: NewRecordDTO[];
}

/**
 * Single day entry in workout heatmap
 */
export interface HeatmapDayDTO {
  date: string;
  workout_count: number;
  total_volume: number;
}

/**
 * Workout heatmap data - returned from get_workout_heatmap RPC
 * Used for dashboard activity visualization
 */
export interface WorkoutHeatmapDTO {
  dates: HeatmapDayDTO[];
  current_streak: number;
  longest_streak: number;
}

// =============================================================================
// Command Models - Request Types for Create/Update Operations
// =============================================================================

// -----------------------------------------------------------------------------
// User Settings Commands
// -----------------------------------------------------------------------------

/**
 * Command to update user settings
 * All fields are optional since it's a PATCH operation
 */
export type UpdateUserSettingsCommand = Pick<
  UserSettingsUpdate,
  'default_weight_unit' | 'rest_timer_duration' | 'theme'
>;

// -----------------------------------------------------------------------------
// Exercise Commands
// -----------------------------------------------------------------------------

/**
 * Command to create a new custom exercise
 * Requires name, target_muscle_group, and user_id
 * is_system should always be false for user-created exercises
 */
export type CreateExerciseCommand = Pick<
  ExerciseInsert,
  'name' | 'target_muscle_group' | 'user_id'
> & {
  is_system: false;
};

/**
 * Command to update an existing custom exercise
 * Only name and target_muscle_group can be updated
 */
export type UpdateExerciseCommand = Pick<
  ExerciseUpdate,
  'name' | 'target_muscle_group'
>;

// -----------------------------------------------------------------------------
// Template Commands
// -----------------------------------------------------------------------------

/**
 * Command to create a new user template
 * Requires name and user_id
 * is_system should always be false for user-created templates
 */
export type CreateTemplateCommand = Pick<TemplateInsert, 'name' | 'user_id'> & {
  is_system: false;
};

/**
 * Command to update an existing user template
 * Only name can be updated
 */
export type UpdateTemplateCommand = Pick<TemplateUpdate, 'name'>;

// -----------------------------------------------------------------------------
// Template Exercise Commands
// -----------------------------------------------------------------------------

/**
 * Command to add an exercise to a template
 * Requires all relationship and ordering information
 */
export type CreateTemplateExerciseCommand = Pick<
  TemplateExerciseInsert,
  'template_id' | 'exercise_id' | 'sort_order' | 'sets_count'
>;

/**
 * Command to update an exercise in a template
 * Can update sort_order and sets_count
 */
export type UpdateTemplateExerciseCommand = Pick<
  TemplateExerciseUpdate,
  'sort_order' | 'sets_count'
>;

// -----------------------------------------------------------------------------
// Workout Commands
// -----------------------------------------------------------------------------

/**
 * Command to start a new workout
 * Requires user_id and started_at
 * template_id and name are optional
 * Status should be IN_PROGRESS when starting
 */
export type CreateWorkoutCommand = Pick<
  WorkoutInsert,
  'user_id' | 'template_id' | 'name' | 'started_at'
> & {
  status: 'IN_PROGRESS';
};

/**
 * Command to update a workout
 * Used to complete workout, add notes, or edit details
 */
export type UpdateWorkoutCommand = Pick<
  WorkoutUpdate,
  'status' | 'completed_at' | 'notes' | 'name'
>;

// -----------------------------------------------------------------------------
// Workout Exercise Commands
// -----------------------------------------------------------------------------

/**
 * Command to add an exercise to an active workout
 * Requires workout_id, exercise_id, and sort_order
 */
export type CreateWorkoutExerciseCommand = Pick<
  WorkoutExerciseInsert,
  'workout_id' | 'exercise_id' | 'sort_order'
>;

/**
 * Command to update an exercise in a workout
 * Only sort_order can be updated
 */
export type UpdateWorkoutExerciseCommand = Pick<
  WorkoutExerciseUpdate,
  'sort_order'
>;

// -----------------------------------------------------------------------------
// Set Commands
// -----------------------------------------------------------------------------

/**
 * Command to add a new set to a workout exercise
 * All fields required for creating a set record
 */
export type CreateSetCommand = Pick<
  SetInsert,
  | 'workout_exercise_id'
  | 'weight'
  | 'reps'
  | 'set_type'
  | 'is_completed'
  | 'sort_order'
>;

/**
 * Command to update a set
 * Commonly used to update weight, reps, and completion status
 */
export type UpdateSetCommand = Pick<
  SetUpdate,
  'weight' | 'reps' | 'is_completed' | 'set_type' | 'sort_order'
>;

// =============================================================================
// RPC Request Types
// =============================================================================

/**
 * Parameters for get_previous_best RPC call
 */
export interface GetPreviousBestParams {
  p_exercise_id: string;
  p_user_id: string;
}

/**
 * Parameters for get_workout_summary RPC call
 */
export interface GetWorkoutSummaryParams {
  p_workout_id: string;
}

/**
 * Parameters for get_workout_heatmap RPC call
 */
export interface GetWorkoutHeatmapParams {
  p_user_id: string;
  p_start_date: string;
  p_end_date: string;
}
