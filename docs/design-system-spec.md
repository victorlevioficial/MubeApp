# Design System Spec (Current)

Updated from code on 2026-02-09.
Primary reference remains `design-system.md`.

## 1. Architecture

Design system location:
- `lib/src/design_system/foundations/**`
- `lib/src/design_system/components/**`
- `lib/src/design_system/showcase/**`

App integration points:
- `lib/src/app.dart` (global theme + scroll behavior)
- `lib/src/routing/app_router.dart` (`MainScaffold` shell)

## 2. Foundation Tokens

### 2.1 Colors (`AppColors`)
Path: `lib/src/design_system/foundations/tokens/app_colors.dart`

- Primary: `#E8466C`
- Primary pressed: `#D13F61`
- Background: `#0A0A0A`
- Surface: `#141414`
- Surface 2: `#1F1F1F`
- Surface highlight: `#292929`
- Border: `#383838`
- Text primary/secondary/tertiary: `#FFFFFF`, `#B3B3B3`, `#8A8A8A`
- Feedback: error `#EF4444`, success `#22C55E`, info `#3B82F6`, warning `#F59E0B`

### 2.2 Typography (`AppTypography`)
Path: `lib/src/design_system/foundations/tokens/app_typography.dart`

- Families: `Poppins` (display), `Inter` (body)
- Scales: headline, title, body, label
- Semantic styles: buttons, chip label, settings title, profile label, matchpoint hero text

### 2.3 Spacing (`AppSpacing`)
Path: `lib/src/design_system/foundations/tokens/app_spacing.dart`

Scale: `2, 4, 8, 12, 16, 24, 32, 40, 48`

### 2.4 Radius (`AppRadius`)
Path: `lib/src/design_system/foundations/tokens/app_radius.dart`

Scale: `4, 8, 12, 16, 24, pill`

### 2.5 Motion/Effects
Paths:
- `lib/src/design_system/foundations/tokens/app_motion.dart`
- `lib/src/design_system/foundations/tokens/app_effects.dart`

Includes duration, curves, shadow stacks, glass tokens.

## 3. Theme Contract

Path: `lib/src/design_system/foundations/theme/app_theme.dart`

- Material 3 dark theme
- Themed elements: app bar, text, input decoration, buttons, snackbar, bottom sheet, checkbox, date/time pickers
- Scroll behavior override at `lib/src/design_system/foundations/theme/app_scroll_behavior.dart`

## 4. Component Inventory

### 4.1 Category inventory

| Category | Dart files |
| --- | --- |
| badges | 1 |
| buttons | 4 |
| chips | 3 |
| data_display | 2 |
| feedback | 5 |
| inputs | 7 |
| interactions | 1 |
| loading | 4 |
| navigation | 5 |
| patterns | 5 |

### 4.2 Canonical APIs for new screens

- `AppAppBar`
- `AppButton`
- `AppTextField`
- `AppFilterChip` (or `AppChip.filter`)
- `AppSnackBar`
- `AppLoadingIndicator`
- `UserAvatar`
- `MainScaffold`

### 4.3 Transitional APIs

- Deprecated alias: `MubeAppBar`
- Transitional wrappers: `AppLoading`
- Duplicate shell: `AppScaffold` (router uses `MainScaffold`)

## 5. Adoption and Drift Summary

Snapshot outside design_system folder:
- Files with design-system imports: `83`
- Token refs: `AppColors=800`, `AppSpacing=858`, `AppTypography=388`, `AppRadius=159`
- Native exceptions in app code: button primitives and direct colors in `15` files

Main exception examples:
- Native app bar: resolved (migrated to `AppAppBar`)
- Native text field: resolved (migrated to `AppTextField`)

## 6. Next Document

Migration backlog and priority list:
- `docs/design-system-audit-2026-02-09.md`
