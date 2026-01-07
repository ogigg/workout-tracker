# REST API Plan

## 1. Resources

| Resource | Database Table | Description |
|----------|----------------|-------------|
| Users | `users` | User accounts (managed by Supabase Auth) |
| User Settings | `user_settings` | User preferences (weight unit, theme, rest timer) |
| Exercises | `exercises` | System and user-defined exercises |
| Templates | `templates` | Workout templates (system and user-created) |
| Template Exercises | `template_exercises` | Exercises within templates |
| Workouts | `workouts` | Completed or in-progress workout sessions |
| Workout Exercises | `workout_exercises` | Exercises performed in a workout |
| Sets | `sets` | Individual set records |

---

## 2. Endpoints

### 2.1 Authentication

> [!NOTE]
> Authentication is handled by Supabase Auth. The endpoints below are provided by Supabase SDK and do not require custom implementation.

#### POST `/auth/v1/signup`
- **Description**: Register a new user account
- **Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response** `201 Created`:
```json
{
  "user": {
    "id": "uuid",
    "email": "string",
    "created_at": "timestamp"
  },
  "session": {
    "access_token": "string",
    "refresh_token": "string",
    "expires_in": 3600
  }
}
```
- **Errors**:
  - `400 Bad Request`: Invalid email format or weak password
  - `422 Unprocessable Entity`: Email already registered

#### POST `/auth/v1/token?grant_type=password`
- **Description**: Log in with email and password
- **Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response** `200 OK`:
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "string"
  }
}
```
- **Errors**:
  - `400 Bad Request`: Invalid credentials

#### POST `/auth/v1/logout`
- **Description**: Log out current user
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.2 User Settings

#### GET `/rest/v1/user_settings`
- **Description**: Get current user's settings
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `200 OK`:
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "default_weight_unit": "kg" | "lbs",
  "rest_timer_duration": 90,
  "theme": "dark" | "light" | "system",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```
- **Note**: RLS ensures user sees only their own settings

#### PATCH `/rest/v1/user_settings?user_id=eq.<user_id>`
- **Description**: Update user settings
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "default_weight_unit": "kg" | "lbs",
  "rest_timer_duration": 90,
  "theme": "dark" | "light" | "system"
}
```
- **Response** `200 OK`: Updated settings object
- **Errors**:
  - `400 Bad Request`: Invalid weight unit, theme, or rest_timer_duration ≤ 0
  - `401 Unauthorized`: Missing or invalid token
  - `403 Forbidden`: Attempting to modify another user's settings

---

### 2.3 Exercises

#### GET `/rest/v1/exercises`
- **Description**: List all accessible exercises (system + user's own)
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `name=ilike.*<query>*`: Search by name (case-insensitive)
  - `target_muscle_group=eq.<group>`: Filter by muscle group
  - `is_system=eq.<true|false>`: Filter by type
  - `deleted_at=is.null`: Exclude soft-deleted (default)
  - `order=name.asc`: Sort order
  - `limit=<n>`: Pagination limit (default: 50)
  - `offset=<n>`: Pagination offset
- **Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "name": "Bench Press",
    "target_muscle_group": "chest",
    "is_system": true,
    "user_id": null,
    "created_at": "timestamp",
    "updated_at": "timestamp"
  }
]
```
- **Response Headers**:
  - `Content-Range`: Total count for pagination

#### GET `/rest/v1/exercises?id=eq.<id>`
- **Description**: Get a single exercise by ID
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `200 OK`: Single exercise object
- **Errors**:
  - `404 Not Found`: Exercise not found or not accessible

#### POST `/rest/v1/exercises`
- **Description**: Create a custom exercise
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "name": "string",
  "target_muscle_group": "chest",
  "is_system": false,
  "user_id": "uuid"
}
```
- **Response** `201 Created`: Created exercise object
- **Errors**:
  - `400 Bad Request`: Missing required fields or invalid muscle group
  - `409 Conflict`: Exercise name already exists for this user

#### PATCH `/rest/v1/exercises?id=eq.<id>`
- **Description**: Update a custom exercise
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "name": "string",
  "target_muscle_group": "chest"
}
```
- **Response** `200 OK`: Updated exercise object
- **Errors**:
  - `403 Forbidden`: Cannot modify system exercises
  - `409 Conflict`: Name conflicts with another exercise

#### DELETE `/rest/v1/exercises?id=eq.<id>`
- **Description**: Soft-delete a custom exercise (sets `deleted_at`)
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`
- **Errors**:
  - `403 Forbidden`: Cannot delete system exercises

---

### 2.4 Templates

#### GET `/rest/v1/templates`
- **Description**: List all accessible templates (system + user's own)
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `is_system=eq.<true|false>`: Filter by type
  - `deleted_at=is.null`: Exclude soft-deleted
  - `select=*,template_exercises(*)`: Include exercises
  - `order=name.asc`: Sort order
- **Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "user_id": null,
    "name": "Push Day",
    "is_system": true,
    "created_at": "timestamp",
    "template_exercises": [
      {
        "id": "uuid",
        "exercise_id": "uuid",
        "sort_order": 0,
        "sets_count": 3
      }
    ]
  }
]
```

#### GET `/rest/v1/templates?id=eq.<id>&select=*,template_exercises(*,exercises(*))`
- **Description**: Get a single template with exercises details
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `200 OK`: Template object with nested exercises

#### POST `/rest/v1/templates`
- **Description**: Create a user template
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "name": "My Push Day",
  "is_system": false,
  "user_id": "uuid"
}
```
- **Response** `201 Created`: Created template object

#### PATCH `/rest/v1/templates?id=eq.<id>`
- **Description**: Update a user template
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "name": "Updated Push Day"
}
```
- **Response** `200 OK`: Updated template object
- **Errors**:
  - `403 Forbidden`: Cannot modify system templates

#### DELETE `/rest/v1/templates?id=eq.<id>`
- **Description**: Soft-delete a user template
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.5 Template Exercises

#### POST `/rest/v1/template_exercises`
- **Description**: Add exercise to a template
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "template_id": "uuid",
  "exercise_id": "uuid",
  "sort_order": 0,
  "sets_count": 3
}
```
- **Response** `201 Created`
- **Errors**:
  - `400 Bad Request`: sets_count ≤ 0
  - `403 Forbidden`: Template is not owned by user

#### PATCH `/rest/v1/template_exercises?id=eq.<id>`
- **Description**: Update exercise in template (order, sets count)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "sort_order": 1,
  "sets_count": 4
}
```
- **Response** `200 OK`

#### DELETE `/rest/v1/template_exercises?id=eq.<id>`
- **Description**: Remove exercise from template
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.6 Workouts

#### GET `/rest/v1/workouts`
- **Description**: List user's workout history
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `status=eq.COMPLETED`: Filter by status
  - `deleted_at=is.null`: Exclude soft-deleted
  - `order=completed_at.desc`: Sort by date
  - `limit=<n>&offset=<n>`: Pagination
  - `select=*,template:templates(name)`: Include template name
- **Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "template_id": "uuid",
    "template": { "name": "Push Day" },
    "name": "Morning Workout",
    "status": "COMPLETED",
    "started_at": "timestamp",
    "completed_at": "timestamp",
    "notes": "Felt strong today"
  }
]
```

#### GET `/rest/v1/workouts?id=eq.<id>&select=*,workout_exercises(*,exercise:exercises(*),sets(*))`
- **Description**: Get single workout with full details
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `200 OK`: Full workout object with exercises and sets

#### POST `/rest/v1/workouts`
- **Description**: Start a new workout session
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "user_id": "uuid",
  "template_id": "uuid | null",
  "name": "string | null",
  "status": "IN_PROGRESS",
  "started_at": "timestamp"
}
```
- **Response** `201 Created`: Created workout object

#### PATCH `/rest/v1/workouts?id=eq.<id>`
- **Description**: Update workout (complete, add notes, edit)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "status": "COMPLETED",
  "completed_at": "timestamp",
  "notes": "Great session!"
}
```
- **Response** `200 OK`: Updated workout object

#### DELETE `/rest/v1/workouts?id=eq.<id>`
- **Description**: Soft-delete a workout
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.7 Workout Exercises

#### POST `/rest/v1/workout_exercises`
- **Description**: Add exercise to active workout
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "workout_id": "uuid",
  "exercise_id": "uuid",
  "sort_order": 0
}
```
- **Response** `201 Created`

#### PATCH `/rest/v1/workout_exercises?id=eq.<id>`
- **Description**: Update exercise order in workout
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "sort_order": 2
}
```
- **Response** `200 OK`

#### DELETE `/rest/v1/workout_exercises?id=eq.<id>`
- **Description**: Soft-delete exercise from workout
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.8 Sets

#### GET `/rest/v1/sets?workout_exercise_id=eq.<id>`
- **Description**: Get sets for a workout exercise
- **Headers**: `Authorization: Bearer <access_token>`
- **Query Parameters**:
  - `deleted_at=is.null`: Exclude soft-deleted
  - `order=sort_order.asc`: Sort by order
- **Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "workout_exercise_id": "uuid",
    "weight": 80.00,
    "reps": 10,
    "set_type": "WORKING",
    "is_completed": true,
    "sort_order": 0
  }
]
```

#### POST `/rest/v1/sets`
- **Description**: Add a new set
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "workout_exercise_id": "uuid",
  "weight": 80.00,
  "reps": 10,
  "set_type": "WORKING",
  "is_completed": false,
  "sort_order": 0
}
```
- **Response** `201 Created`
- **Errors**:
  - `400 Bad Request`: weight < 0, reps < 0, invalid set_type

#### PATCH `/rest/v1/sets?id=eq.<id>`
- **Description**: Update a set (weight, reps, completion status)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "weight": 85.00,
  "reps": 8,
  "is_completed": true
}
```
- **Response** `200 OK`

#### DELETE `/rest/v1/sets?id=eq.<id>`
- **Description**: Soft-delete a set
- **Headers**: `Authorization: Bearer <access_token>`
- **Response** `204 No Content`

---

### 2.9 Business Logic Endpoints

#### GET `/rest/v1/rpc/get_previous_best`
- **Description**: Get the previous best set data for an exercise (for progressive overload context)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "p_exercise_id": "uuid",
  "p_user_id": "uuid"
}
```
- **Response** `200 OK`:
```json
{
  "weight": 82.50,
  "reps": 10,
  "workout_date": "timestamp"
}
```
- **Note**: Returns `null` if no previous data exists

#### GET `/rest/v1/rpc/get_workout_summary`
- **Description**: Calculate workout summary (total volume, new records)
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "p_workout_id": "uuid"
}
```
- **Response** `200 OK`:
```json
{
  "total_volume": 12500.00,
  "total_sets": 24,
  "total_reps": 180,
  "exercises_count": 6,
  "new_records": [
    {
      "exercise_name": "Bench Press",
      "weight": 100.00,
      "reps": 8
    }
  ]
}
```

#### GET `/rest/v1/rpc/get_workout_heatmap`
- **Description**: Get workout heatmap data for dashboard
- **Headers**: `Authorization: Bearer <access_token>`
- **Request Body**:
```json
{
  "p_user_id": "uuid",
  "p_start_date": "2025-01-01",
  "p_end_date": "2025-12-31"
}
```
- **Response** `200 OK`:
```json
{
  "dates": [
    { "date": "2025-01-07", "workout_count": 1, "total_volume": 8500 },
    { "date": "2025-01-05", "workout_count": 1, "total_volume": 7200 }
  ],
  "current_streak": 3,
  "longest_streak": 14
}
```

---

## 3. Authentication and Authorization

### 3.1 Authentication Mechanism
- **Provider**: Supabase Auth
- **Method**: JWT (JSON Web Tokens)
- **Flow**:
  1. User registers/logs in via Supabase Auth endpoints
  2. Supabase returns `access_token` and `refresh_token`
  3. Client includes `Authorization: Bearer <access_token>` header in all API requests
  4. Token expiry: 1 hour (configurable)
  5. Refresh tokens used to obtain new access tokens

### 3.2 Authorization (Row Level Security)
All data access is controlled by PostgreSQL RLS policies:

| Resource | Policy |
|----------|--------|
| Users | Users can only view/update their own profile |
| User Settings | Users can only access their own settings |
| Exercises | System exercises visible to all; user exercises only visible to owner |
| Templates | System templates visible to all; user templates only visible to owner |
| Template Exercises | Access based on parent template ownership |
| Workouts | Users can only access their own workouts |
| Workout Exercises | Access based on parent workout ownership |
| Sets | Access based on parent workout ownership (via workout_exercises → workouts) |

### 3.3 Security Headers
All requests should include:
- `apikey`: Supabase project API key
- `Authorization`: Bearer token for authenticated routes
- `Content-Type`: `application/json`
- `Prefer`: `return=representation` (to return created/updated objects)

---

## 4. Validation and Business Logic

### 4.1 Validation Rules by Resource

#### User Settings
| Field | Validation |
|-------|------------|
| `default_weight_unit` | Must be `kg` or `lbs` |
| `rest_timer_duration` | Must be > 0 |
| `theme` | Must be `dark`, `light`, or `system` |

#### Exercises
| Field | Validation |
|-------|------------|
| `name` | Required, non-empty |
| `target_muscle_group` | Must be one of: `chest`, `back`, `shoulders`, `biceps`, `triceps`, `forearms`, `core`, `quadriceps`, `hamstrings`, `glutes`, `calves`, `full_body` |
| `is_system` / `user_id` | If `is_system=true`, `user_id` must be null; otherwise `user_id` required |
| `name` (uniqueness) | Unique per user (case-insensitive), excluding soft-deleted |

#### Templates
| Field | Validation |
|-------|------------|
| `name` | Required, non-empty |
| `is_system` / `user_id` | Same logic as exercises |

#### Template Exercises
| Field | Validation |
|-------|------------|
| `sets_count` | Must be > 0 |
| `sort_order` | Must be ≥ 0 |

#### Workouts
| Field | Validation |
|-------|------------|
| `status` | Must be `IN_PROGRESS` or `COMPLETED` |
| `completed_at` | Required when status = `COMPLETED` |

#### Sets
| Field | Validation |
|-------|------------|
| `weight` | Must be ≥ 0 (stored as NUMERIC(6,2)) |
| `reps` | Must be ≥ 0 |
| `set_type` | Must be `WARMUP`, `WORKING`, `DROPSET`, or `FAILURE` |
| `sort_order` | Must be ≥ 0 |

### 4.2 Business Logic Implementation

#### Progressive Overload Context (US-004)
- **Implementation**: `get_previous_best` RPC function
- **Logic**: Query `sets` table joined with `workout_exercises` and `workouts` to find the highest weight × reps combination for a given exercise and user, from completed workouts
- **Performance Requirement**: < 15ms retrieval (supported by `idx_workout_exercises_exercise_created` index)

#### Workout Summary Calculation (US-003)
- **Implementation**: `get_workout_summary` RPC function
- **Logic**:
  - Total Volume = SUM(weight × reps) for all completed sets
  - New Records = Compare each exercise's best set against historical data

#### Activity Heatmap (US-008)
- **Implementation**: `get_workout_heatmap` RPC function
- **Logic**: Group completed workouts by date, calculate daily volume, compute current and longest streak

#### Soft Delete Pattern
- All user-modifiable tables implement soft delete via `deleted_at` column
- API filters exclude soft-deleted records by default (`deleted_at=is.null`)
- Required for PowerSync tombstoning mechanism

#### Conflict Resolution
- **Strategy**: Last Write Wins (LWW)
- **Implementation**: `updated_at` timestamp on all tables; PowerSync uses this for sync conflict resolution

### 4.3 PowerSync Integration

> [!IMPORTANT]
> The API is designed to work with PowerSync for offline-first synchronization. All changes are first written to local SQLite and then synced to Supabase PostgreSQL via PowerSync.

**Sync Flow**:
1. Client writes to local SQLite
2. PowerSync detects changes and queues them
3. When online, PowerSync sends changes to Supabase via REST API
4. PowerSync pulls latest changes from Supabase
5. Conflicts resolved using Last Write Wins (based on `updated_at`)

**Required for Sync**:
- All tables have `updated_at` column with auto-update trigger
- All tables have `deleted_at` for soft deletes (tombstoning)
- All IDs are UUIDs (client-generated for offline support)
