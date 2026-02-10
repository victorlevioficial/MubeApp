# Design System Audit - 2026-02-09

This audit was produced from the current codebase state.
It is not based on planning docs.

## 1. Scope

Analyzed paths:
- `lib/src/design_system/**`
- `lib/src/app.dart`
- `lib/src/routing/app_router.dart`
- `lib/src/features/**`

Audit dimensions:
- foundation consistency (tokens/theme)
- component canonical usage
- exceptions (native widgets and hardcoded colors)
- legacy/duplicate API surface

## 2. Snapshot Metrics

Outside `lib/src/design_system/**`:
- Files with design-system imports: `83`
- Files with native UI exceptions: `15`

Token adoption counts:
- `AppColors`: `800` references
- `AppSpacing`: `858` references
- `AppTypography`: `388` references
- `AppRadius`: `159` references

Native widget exception counts:
- Native `AppBar`: `0`
- Native `TextField`: `0`
- Native `ElevatedButton`: `3`
- Native `OutlinedButton`: `2`
- Native `TextButton`: `11`

Direct color exceptions:
- `Color(0x...)`: `5`
- `Colors.*`: `6`

## 3. Findings

### F1 - Duplicate navigation shell API

Two shell widgets exist:
- `MainScaffold` (`lib/src/design_system/components/navigation/main_scaffold.dart`)
- `AppScaffold` (`lib/src/design_system/components/navigation/app_scaffold.dart`)

Router uses `MainScaffold` at `lib/src/routing/app_router.dart`.
`AppScaffold` currently has zero adoption outside design_system.

Impact:
- unclear API choice for new code
- potential visual drift between shells

### F2 - Input API overlap (resolved)

Current state:
- `AppTextField` is the single text input primitive in code.
- `AppTextInput` has been removed from production code and showcase.

Impact:
- reduced API surface area
- lower onboarding cost for contributors

### F3 - Chip API overlap

Current stack:
- base: `AppChip.filter`
- wrapper: `AppFilterChip`
- legacy wrapper: `MubeFilterChip` (removed)

All active feature code now uses `AppFilterChip`.

Impact:
- naming inconsistency (`Mube*` vs `App*`)
- migration friction

### F4 - Native app bar exceptions (resolved)

Native `AppBar` usage was migrated to `AppAppBar` in feature screens.

Impact:
- DS app-bar contract is now centralized
- title/leading behavior is consistent

### F5 - Native text input exceptions (resolved)

Native `TextField` usage in feature screens was migrated to `AppTextField`.

Assessment:
- `chat_screen.dart` now uses `AppTextField` for composer input
- `support_screen.dart` now uses `AppTextField` for search input

### F6 - Direct colors and hardcoded special colors

Hardcoded colors still used for medals/confetti and overlay dialogs:
- `lib/src/features/matchpoint/presentation/widgets/confetti_overlay.dart`
- `lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart`
- `lib/src/features/support/presentation/ticket_detail_screen.dart`

Assessment:
- medal/confetti colors can become semantic extension tokens
- full-screen image overlay can be represented with DS tokens (`AppColors.transparent` + alpha)

### F7 - Loader API overlap

Both loaders exist:
- `AppLoading`
- `AppLoadingIndicator` (documented as consolidated)

Impact:
- inconsistent loading patterns in new screens

## 4. Recommended Target State

- Keep one shell API: `MainScaffold`
- Keep one text input primitive: `AppTextField`
- Keep one filter-chip public API: `AppFilterChip` (internally using `AppChip.filter`)
- Keep one loader API: `AppLoadingIndicator`
- Keep `AppAppBar` as mandatory app-bar API for standard screens
- Move special celebratory/medal colors to semantic extension tokens

## 5. Migration Backlog (Prioritized)

### P0 - Contract cleanup (1 day)

1. Mark with `@Deprecated`:
- `AppScaffold`
- `AppLoading` (if team agrees)

2. Add clear migration notes in each deprecated file header.

### P1 - Functional migration (1-2 days)

1. Completed:
- native `AppBar` migration in `forgot_password_screen.dart` and `onboarding_form_screen.dart`
- native `TextField` migration in `chat_screen.dart` and `support_screen.dart`

2. Remaining:
- no pending chip migration; `MubeFilterChip` usages were removed.

### P2 - Token extension (0.5 day)

1. Add semantic extension colors in `AppColors`:
- `medalGold`, `medalSilver`, `medalBronze`
- `celebrationPink`

2. Replace hardcoded medal/confetti colors with these tokens.

### P3 - Showcase and docs alignment (0.5 day)

1. Update showcase sections to use canonical APIs only.
2. Keep this audit and `design-system.md` in sync with code after each migration step.

## 6. Validation Checklist

After migration, validate:
- No native `AppBar(` outside design-system implementation.
- No `MubeFilterChip` usage.
- No `AppTextInput` usage in active codebase.
- No direct `Color(0x...)` for DS-covered semantics.
- All changed screens still pass visual QA on mobile widths.

## 7. Notes

`TextButton` occurrences are mostly low-emphasis action affordances and are acceptable when theme tokens are respected.
Keep chat composer UX under visual QA after migration to `AppTextField`.
