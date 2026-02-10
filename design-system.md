# Mube Design System

> Version: 2.1.0
> Last Updated: 2026-02-09
> Status: current implementation snapshot from codebase

This document reflects the real pattern currently implemented in code.
Primary sources analyzed:
- `lib/src/design_system/**`
- `lib/src/app.dart`
- `lib/src/routing/app_router.dart`
- `lib/src/features/**` (usage and exceptions)

## 1. Foundations

### 1.1 Colors (`AppColors`)
Path: `lib/src/design_system/foundations/tokens/app_colors.dart`

| Token | Hex | Notes |
| --- | --- | --- |
| `primary` | `#E8466C` | Main brand/action color |
| `primaryPressed` | `#D13F61` | Pressed state |
| `background` | `#0A0A0A` | Global dark background |
| `surface` | `#141414` | Card/container base |
| `surface2` | `#1F1F1F` | Elevated surface |
| `surfaceHighlight` | `#292929` | Borders/dividers/highlight |
| `border` | `#383838` | Default border token |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#B3B3B3` | Secondary text |
| `textTertiary` | `#8A8A8A` | Tertiary/placeholder |
| `error` | `#EF4444` | Error |
| `success` | `#22C55E` | Success |
| `info` | `#3B82F6` | Informational |
| `warning` | `#F59E0B` | Warning |

Extra semantic groups:
- `primaryGradient`
- `avatarColors` palette
- `badgeMusician`, `badgeBand`, `badgeStudio`
- `skeletonBase`, `skeletonHighlight`

### 1.2 Typography (`AppTypography`)
Path: `lib/src/design_system/foundations/tokens/app_typography.dart`

Font families:
- Display: `Poppins`
- Body: `Inter`

Core scales:
- Headlines: `headlineLarge` (28), `headlineCompact` (24), `headlineMedium` (20), `headlineSmall` (18)
- Titles: `titleLarge` (18), `titleMedium` (16), `titleSmall` (14)
- Body: `bodyLarge` (16), `bodyMedium` (14), `bodySmall` (12)
- Labels: `labelLarge` (14), `labelMedium` (13), `labelSmall` (11)

Semantic text styles in use:
- `buttonPrimary`, `buttonSecondary`
- `chipLabel`, `cardTitle`, `settingsGroupTitle`, `profileTypeLabel`
- MatchPoint specific: `matchSuccessTitle`, `matchSuccessKicker`

### 1.3 Spacing (`AppSpacing`)
Path: `lib/src/design_system/foundations/tokens/app_spacing.dart`

Scale: `2, 4, 8, 12, 16, 24, 32, 40, 48`

Common presets:
- `all*`, `h*`, `v*`
- `h16v12`, `h16v8`, `h24v16`
- `screenPadding`, `screenHorizontal`

### 1.4 Radius (`AppRadius`)
Path: `lib/src/design_system/foundations/tokens/app_radius.dart`

Scale: `r4, r8, r12, r16, r24, rPill`

Semantic radius:
- `card`, `input`, `button`, `chip`, `bottomSheet`, `modal`, `chatBubble`

### 1.5 Motion and Effects
Paths:
- `lib/src/design_system/foundations/tokens/app_motion.dart`
- `lib/src/design_system/foundations/tokens/app_effects.dart`

Motion:
- Durations: `short`, `medium`, `standard`, `long`
- Curves: `standardCurve`, `emphasizedCurve`, `leavingCurve`, `bounceCurve`

Effects:
- Shadows: `cardShadow`, `floatingShadow`, `subtleShadow`, `buttonShadow`
- Glass tokens: `glassDecoration`, `glassCardDecoration`
- Opacity and animation duration helpers

## 2. Theme Contract

Path: `lib/src/design_system/foundations/theme/app_theme.dart`

Current contract:
- `ThemeData(useMaterial3: true, brightness: Brightness.dark)`
- Dark `ColorScheme` wired to `AppColors`
- Themed controls: `AppBar`, `InputDecoration`, `ElevatedButton`, `OutlinedButton`, `TextButton`, `Checkbox`, date/time pickers, snackbar, bottom sheet
- App root uses this theme at `lib/src/app.dart`

## 3. Component System

Base path: `lib/src/design_system/components/`

Categories:
- `badges`, `buttons`, `chips`, `data_display`, `feedback`, `inputs`, `interactions`, `loading`, `navigation`, `patterns`

Most used components in app code (outside design_system):
- `AppSnackBar` (82 refs)
- `AppButton` (55 refs)
- `AppTextField` (46 refs)
- `AppAppBar` (25 refs)
- `AppFilterChip` (14 refs)
- `UserAvatar` (10 refs)

### 3.1 Canonical components for new code

- Navigation: `AppAppBar`, `MainScaffold`
- Buttons: `AppButton` (+ `SocialLoginButton` where needed)
- Inputs/forms: `AppTextField`, `AppDropdownField`, `AppDatePickerField`, `AppSelectionModal`, `AppAutocompleteField`, `AppCheckbox`
- Feedback: `AppSnackBar`, `AppConfirmationDialog`, `EmptyStateWidget`
- Loading: `AppLoadingIndicator`, `AppShimmer`, skeletons from `app_skeleton.dart`
- Data display: `UserAvatar`

### 3.2 Legacy or transitional APIs

- `MubeAppBar` alias: deprecated (`typedef` to `AppAppBar`)
- `AppLoading`: older loader API (still present; prefer `AppLoadingIndicator`)
- `AppScaffold`: duplicate scaffold not used by router (`MainScaffold` is active)

## 4. Real Adoption Snapshot (2026-02-09)

Codebase metrics (outside `lib/src/design_system/**`):
- Files importing design system: `83`
- Token references:
  - `AppColors`: `800`
  - `AppSpacing`: `858`
  - `AppTypography`: `388`
  - `AppRadius`: `159`

Exception metrics (native widgets or hardcoded colors still present):
- Files with at least one native UI exception: `15`
- Native `AppBar`: `0` occurrences outside `AppAppBar`
- Native `TextField`: `0` occurrences
- Native `ElevatedButton`: `3` occurrences
- Native `OutlinedButton`: `2` occurrences
- Native `TextButton`: `11` occurrences (mostly low emphasis actions)
- Direct `Colors.*`: `6` occurrences
- Direct `Color(0x...)`: `5` occurrences (mostly medal/confetti colors)

## 5. Rules for New Work

1. Prefer design-system components over raw Material widgets.
2. Use tokens (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`) instead of hardcoded style values.
3. Use `AppAppBar` for screen app bars.
4. Use `AppTextField` for forms and standard text input.
5. Use `AppButton` for primary/secondary actions.
6. Use `AppSnackBar` for transient feedback.
7. If a screen needs a raw widget for a valid UX reason, document the reason in the PR.

## 6. Known Exceptions (remaining)

- Historical migration note:
  - native app bars and native text fields were removed in favor of `AppAppBar` and `AppTextField`.
  - legacy `MubeFilterChip` was removed; filters now use `AppFilterChip` only.

## 7. Related Documents

- Technical mirror spec: `docs/design-system-spec.md`
- Audit and migration backlog: `docs/design-system-audit-2026-02-09.md`
