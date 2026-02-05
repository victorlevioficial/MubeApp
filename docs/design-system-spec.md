# Design System Specification

**Name**: Mube Design System
**Theme**: Dark Mode First (High Contrast, Neon Accents)

## 1. Design Tokens

### 1.1 Color Palette (`AppColors`)
The system uses a semantic token layer over a raw palette, ensuring consistence and easy theming.

**Brand Colors**
*   **Primary**: `Razzmatazz 300` (#D71E68) - Main brand identity.
*   **Glow**: `#D71E68` - Neon effects.
*   **Gradient**: Linear Gradient from Primary to `#990033`.

**Backgrounds**
*   **Deep**: `#0A0A0A` (App Background)
*   **Surface**: `#161616` (Cards, Sheets)
*   **Highlight**: `#202020` (Dividers, Borders)

**Text**
*   **Primary**: `#FFFFFF` (White)
*   **Secondary**: `#B3B3B3` (Zinc 400)
*   **Tertiary**: `#737373` (Zinc 600)

**Feedback**
*   **Error**: `Red 500` (#EF4444)
*   **Success**: `Green 500` (#22C55E)
*   **Warning**: `Amber 500` (#F59E0B)

### 1.2 Typography (`AppTypography`)
*   **Font Family**: Custom (likely generic sans-serif tailored via Google Fonts, e.g., Inter/Roboto).
*   **Scale**:
    *   `Display`: Large headers.
    *   `Title`: Section headers.
    *   `Body`: Standard content (Regular/Bold).
    *   `Label`: Small tags and captions.

## 2. Component Library (`lib/src/design_system/components`)

### 2.1 Atoms (Basic Building Blocks)
*   **Buttons**: `AppButton` (Primary, Secondary, Ghost, Outline).
*   **Inputs**: `AppTextField` (Standard, Password, Search).
*   **Chips**:
    *   `SkillChip`: For instruments/roles.
    *   `GenreChip`: For musical genres.
    *   `StatusChip`: For user statuses.
*   **Feedback**: `AppSnackbar`, `AppConfirmationDialog`.

### 2.2 Navigation
*   **`AppAppBar`**: Custom top bar with back button support.
*   **`MainScaffold`**: Wraps the bottom navigation logic.

### 2.3 Loading States
*   **Skeletons**: Shimmer effects for loading lists (`AppColors.skeletonBase`).
*   **Loaders**: Circular indicators customized with Brand Color.

## 3. UI Patterns
*   **Cards**: Rounded corners (likely 12px-16px), Surface color background.
*   **Lists**: Vertical scrolling with virtualization (`ListView.builder`).
*   **Grids**: Used for Gallery (`AppReorderableGridView` implied).
*   **Modals**: Bottom Sheets for filters/actions.

## 4. Assets
*   **Icons**: FontAwesome (`font_awesome_flutter`) + Custom SVGs.
*   **Images**: Specialized handling for User Avatars (Circular + Cache).
