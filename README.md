# Workout Tracker

A cross-platform mobile application (iOS & Android) built with "Local First" architecture, designed to remove friction from the gym environment. It ensures rapid performance and reliability regardless of internet connectivity, allowing users to log sets, reps, and weights efficiently while providing visual motivation.

## Project Description

The Workout Tracker solves common gym problems like note-taking friction, connectivity issues, and lack of immediate historical context. 

**Key Features:**
*   **Local First & Offline Capable:** Full functionality without internet. Syncs automatically when back online.
*   **Lightning Fast:** Optimized for speed (start logging in < 15s).
*   **Activity Heatmap:** GitHub-style visualization to gamify consistency.
*   **Smart Logging:** Immediate access to previous stats for progressive overload.
*   **Templates & History:** Built-in and custom templates, with full history editing.

## Tech Stack

### Mobile (Frontend)
*   **Framework:** [React Native](https://reactnative.dev/) with [Expo SDK](https://expo.dev/) (Managed Workflow)
*   **Language:** [TypeScript](https://www.typescriptlang.org/)
*   **UI Library:** [React Native Paper](https://callstack.github.io/react-native-paper/)
*   **Styling:** [NativeWind](https://www.nativewind.dev/) (Tailwind CSS for React Native)
*   **State Management:** 
    *   [Zustand](https://github.com/pmndrs/zustand) (Local UI state)
    *   [TanStack Query](https://tanstack.com/query/latest) (Server state)

### Data Layer (Offline-First)
*   **Local DB:** [Expo SQLite](https://docs.expo.dev/versions/latest/sdk/sqlite/)
*   **ORM:** [Drizzle ORM](https://orm.drizzle.team/)
*   **Sync Engine:** [PowerSync](https://www.powersync.com/)

### Backend (BaaS)
*   **Platform:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, RLS)

### Architecture
*   **Monorepo:** Managed with [Turborepo](https://turbo.build/)

## Getting Started Locally

### Prerequisites
*   Node.js (v18 or newer)
*   npm (v11.4.0 or newer)
*   iOS Simulator (for Mac) or Android Emulator

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd workout-tracker
    ```

2.  **Install dependencies:**
    This project uses Turborepo. Install dependencies at the root.
    ```bash
    npm install
    ```

3.  **Start the Mobile App:**
    You can start the mobile app from the root or inside `apps/mobile`.
    
    From root:
    ```bash
    npm run dev
    ```
    
    Or specifically for iOS/Android:
    ```bash
    # For iOS
    cd apps/mobile && npm run ios
    
    # For Android
    cd apps/mobile && npm run android
    ```

## Available Scripts

This project relies on **Turborepo** to manage scripts across the workspace.

### Root Scripts
*   `npm run dev`: Starts the development server for all apps (turbo).
*   `npm run build`: Builds the project (turbo).
*   `npm run lint`: Runs linting across the workspace.
*   `npm run check-types`: Runs TypeScript type checking.
*   `npm run clean`: Cleans build artifacts.
*   `npm run format`: Formats code using Prettier.

### Mobile App Scripts (`apps/mobile`)
*   `npm run start`: Start Expo development server.
*   `npm run android`: Run on Android emulator/device.
*   `npm run ios`: Run on iOS simulator/device.
*   `npm run web`: Run in web browser (if supported).

## Project Scope

### In Scope (MVP)
*   Core weightlifting logic (Sets, Reps, Weight)
*   Volume metrics
*   Offline-first architecture with background sync
*   120+ Exercise Database with categorization
*   System & User Templates
*   Dark Mode
*   Authentication (Login/Register) & Profile
*   Dashboard with Activity Heatmap

### Out of Scope (Post-MVP)
*   RPE logging
*   Supersets
*   Social features
*   Advanced analytics
*   Subscription models
*   Custom exercise creation

## Project Status

**Current Status:** Active Development (MVP Phase)

*   **Architecture:** Defined (Local-First with PowerSync)
*   **Tech Stack:** Selected (Expo, Drizzle, Supabase)
*   **Development:** In progress (Setting up core features and offline sync)

## License

This project is currently private.
`"private": true`
