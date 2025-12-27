---
description: Styling guidelines using NativeWind and React Native Paper
globs: apps/mobile/**/*.tsx
---

# Styling & UI Guidelines

## Core Principles
- **Styling Engine**: Use **NativeWind** (Tailwind CSS) for almost all layout and custom styling.
- **Component Kit**: Use **React Native Paper** for standard UI elements (Buttons, Inputs, Modals, Cards).
- **Theme**: Dark Mode by default. Rely on the React Native Paper Theme Provider.
- **Responsiveness**: Use Tailwind's flexbox and spacing utilities. Avoid hardcoded pixel values; use percentages or safe area insets.

## NativeWind Best Practices
- Define styles directly in the `className` prop.
- For complex conditional styles, use the `clsx` or `tailwind-merge` pattern (if available) or template literals.
- Leverage the `dark:` modifier for color overrides.

## React Native Paper Integration
- **Theming**: Access the theme via `useTheme` hook from `react-native-paper`.
- **Customizing**: Wrap React Native Paper components when deep customization is needed, but prefer using their `theme` prop or `style` prop with NativeWind values where possible.
- **Provider**: Ensure `PaperProvider` is at the root of the app, wrapping the `ThemeProvider` from Expo/React Navigation.

## UI Structure
1.  **Layouts**: Use `View` and `SafeAreaView` with NativeWind classes like `flex-1`, `bg-background`, `p-4`.
2.  **Typography**: Use React Native Paper's `Text` component with appropriate variants (`headlineLarge`, `bodyMedium`).
3.  **Spacing**: Use consistent margins/padding from the Tailwind scale (e.g., `m-2`, `p-4`).

## Visual Excellence (WOW Factor)
- **Gradients**: Use `expo-linear-gradient` for premium backgrounds.
- **Animations**: Use `react-native-reanimated` for smooth transitions and micro-animations.
- **Shadows**: Use React Native Paper's `elevation` or NativeWind's shadow utilities.
