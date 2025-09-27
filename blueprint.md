# Application Blueprint

## Overview

This document outlines the structure, design, and features of the Flutter application. It serves as a single source of truth for the project's architecture and implementation details.

## Style, Design, and Features

### Initial Version
- Standard Flutter Counter Application.
- Basic Material Design theme.
- Integrated Firebase with `firebase_core`.

## Current Plan: Optimize and Refactor

**Goal:** Refactor the application for better structure, maintainability, and to follow the best practices outlined in the project's development guidelines (`GEMINI.md`).

**Steps:**

1.  **Add Dependencies:** Introduce `provider` for state management and `google_fonts` for improved typography.
2.  **Theming:**
    *   Implement a `ThemeProvider` using `ChangeNotifier` to manage light/dark modes.
    *   Define a comprehensive `ThemeData` for both light and dark themes using `ColorScheme.fromSeed` and `google_fonts`.
    *   Add a theme toggle UI to the `AppBar`.
3.  **State Management:**
    *   Replace the `StatefulWidget` (`MyHomePage`) with a `StatelessWidget` that uses `Provider` to access application state (e.g., the theme).
4.  **Code Structure:**
    *   Separate the main `MyApp` widget from the home screen.
    *   Move the `MyHomePage` widget into its own file (`lib/home_screen.dart`).
    *   Clean up `lib/main.dart` to act as the application's composition root, responsible for initializing services (like Firebase) and providers.
5.  **Code Quality:**
    *   Remove unused imports.
    *   Ensure all new code uses `const` constructors where possible for performance optimization.
    *   Format the code using `dart format`.

This refactoring will establish a scalable architecture, making it easier to add new features in the future.
