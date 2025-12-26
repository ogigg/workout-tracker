# Product Requirements Document (PRD) - Workout Tracker

## 1. Product Overview
The Workout Tracker is a cross-platform mobile application (iOS & Android) built with React Native and Expo. It represents a "Local First" approach to workout logging, ensuring rapid performance and reliability regardless of internet connectivity. The application is designed to remove friction from the gym environment, allowing users to log sets, reps, and weights efficiently while providing visual motivation through activity heatmaps and progress tracking.

The technical foundation relies on Expo Router for navigation, TanStack Query for server state management, and Zustand for local state, with a local SQLite database acting as a robust cache to support full offline functionality with background synchronization.

## 2. User Problem
Gym-goers often face specific challenges that hinder their progress and consistency:
- Note-taking friction: Using paper notebooks or generic note apps is slow and unstructured.
- Connectivity issues: Gyms and basements often have poor or no cellular reception, rendering online-only apps useless.
- Lack of immediate context: Users often forget what weight they lifted last time, making progressive overload difficult to track.
- Motivation dips: Without a visual representation of consistency, it is easy to skip workouts and lose momentum.

This product solves these problems by providing a lightning-fast interface (MVP metric: < 15s to start), offline reliability, immediate access to historical performance data during logging, and a GitHub-style heatmap to gamify consistency.

## 3. Functional Requirements

### 3.1 Authentication & User Profile
- Backend-based user account system.
- Login and Registration screens.
- Minimalist Profile section (Email display, App Version, Logout).
- No in-app account editing for MVP.

### 3.2 Dashboard (Home Screen)
- Central "Start Workout" Copy-To-Action (CTA).
- Visual activity tracker: GitHub-style Heatmap or Streak counter.
- Quick summary of recent activity.

### 3.3 Active Workout Module
- Workout Session Initialization:
  - Select from 10 pre-defined system templates.
  - Select from user-created "My Templates".
  - Start an empty "ad-hoc" workout.
- Exercise Database:
  - Access to ~120 pre-defined exercises.
  - Categorization by muscle groups (displayed with emoji icons).
  - Search and filter functionality.
- Set Logging:
  - Fields: Weight (kg), Reps, Status (Completed/Failed).
  - Display of previous workout results for the specific exercise (for progressive overload context).
  - Input validation (prompt to remove empty sets before saving).
- Rest Timer:
  - Non-blocking timer bar at the bottom of the screen.
- Workout Completion:
  - Summary screen displaying Total Volume and New Records.
  - Save to local DB and queue for sync.

### 3.4 History & Progress
- Scrollable list of completed workouts.
- Detailed view of specific workout sessions.
- Editing capabilities for past workouts (simple overwrite logic).
- "Last Write Wins" conflict resolution strategy for data synchronization.

### 3.5 Offline Capability
- Full functionality without internet access.
- Local SQLite database caches all necessary data (exercises, history, templates).
- Background synchronization when connection is restored.

## 4. Product Boundaries (MVP Scope)

### In Scope
- Core weightlifting logic (Sets, Reps, Weight).
- Basic Metric: Volume.
- Offline-first architecture.
- 120 Exercise Database.
- System & User Templates.
- Dark Mode by default.

### Out of Scope (Post-MVP)
- RPE (Rate of Perceived Exertion) logging.
- Per-set specific notes (text memos).
- Superset support.
- Social features (friends, leaderboards).
- Advanced analytics or graphs beyond basic summary.
- Subscription models or Ads.
- Onboarding tutorials (the app must be intuitive enough to skip this).
- Creation of completely custom exercises (users rely on the 120 DB for MVP).

## 5. User Stories

### Authentication
#### US-001: Secure Account Creation
- Description: As a new user, I want to create an account so that my data is backed up to the cloud.
- Acceptance Criteria:
  1. User can enter email and password.
  2. Successful registration logs the user in immediately.
  3. Failures (e.g., email already in use) display a clear error message.

#### US-002: User Login
- Description: As a returning user, I want to log in to access my workout history on a new device.
- Acceptance Criteria:
  1. User can input credentials.
  2. System retrieves user's history and settings from the cloud upon successful login.
  3. App supports persistent login state across app restarts.

### Workout Execution
#### US-003: Quick Start Workout
- Description: As a user, I want to start a workout immediately from the home screen to avoid wasting time.
- Acceptance Criteria:
  1. Home screen has a prominent "Start Workout" button.
  2. Tapping leads to a selection screen (Template vs. Empty).
  3. Time from app open to logging screen is under 15 seconds.

#### US-004: Log Exercise Sets with Context
- Description: As a user, I want to see how much I lifted last time while entering my current set, so I can progress.
- Acceptance Criteria:
  1. When entering a set, the Previous Best or Last Session data for that exercise is visible.
  2. User can enter Weight and Reps.
  3. User can mark a set as "Done".

#### US-005: Rest Timer
- Description: As a user, I want a timer to track my rest periods without blocking the interface.
- Acceptance Criteria:
  1. User can start a timer after a set.
  2. Timer appears as a non-intrusive bar (e.g., bottom of screen).
  3. User can continue navigating or logging while the timer runs.

#### US-006: Offline Workout
- Description: As a user with no internet connection, I want to complete and save my workout seamlessly.
- Acceptance Criteria:
  1. App functions normally in Airplane mode.
  2. Completed workout is saved to local storage.
  3. Workout is synced to the backend automatically when connection is restored.

### Data Management
#### US-007: Edit History
- Description: As a user, I want to fix a mistake in a past workout log.
- Acceptance Criteria:
  1. User can navigate to the History tab.
  2. User can open a past workout and modify sets/reps.
  3. Changes are saved and synced (Last Write Wins).

#### US-008: Visual Motivation
- Description: As a user, I want to see my workout streak on the dashboard to stay motivated.
- Acceptance Criteria:
  1. Dashboard displays a heatmap or streak counter.
  2. Completing a workout updates the visual indicator immediately (Optimistic UI).

## 6. Success Metrics

### Efficiency
- Time-to-Start: Average time from launching the app to the first set input is < 15 seconds.
- Sync Speed: 95% of offline sessions sync within 30 seconds of regaining connectivity.

### Reliability
- Data Integrity: 0% data loss during Offline-to-Online transitions.
- Crash Free Rate: > 99.5% for MVP launch.

### User Engagement
- Retention: Percentage of users who log a workout at least 3 times a week (Consistency metric).
- Streak Maintenance: Average length of user streaks on the heatmap.
