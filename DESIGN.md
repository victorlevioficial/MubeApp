---
name: Mube
description: Focused dark product UI for the Brazilian music scene.
colors:
  primary: "#E8466C"
  primary-pressed: "#D13F61"
  primary-muted: "#E8466C4D"
  background: "#0A0A0A"
  surface: "#141414"
  surface-2: "#1F1F1F"
  surface-highlight: "#292929"
  border: "#383838"
  text-primary: "#FFFFFF"
  text-secondary: "#B3B3B3"
  text-tertiary: "#8A8A8A"
  error: "#EF4444"
  success: "#22C55E"
  info: "#3B82F6"
  warning: "#F59E0B"
  badge-band: "#C026D3"
  badge-studio: "#DC2626"
  avatar-pink: "#F472B6"
  avatar-violet: "#A78BFA"
  avatar-blue: "#60A5FA"
  avatar-emerald: "#34D399"
  avatar-amber: "#FBBF24"
  avatar-red: "#F87171"
typography:
  display:
    fontFamily: "Poppins, Inter, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Poppins, Inter, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Poppins, Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "0"
rounded:
  r4: "4px"
  r8: "8px"
  r12: "12px"
  r16: "16px"
  r20: "20px"
  r24: "24px"
  pill: "999px"
spacing:
  s2: "2px"
  s4: "4px"
  s8: "8px"
  s10: "10px"
  s12: "12px"
  s14: "14px"
  s16: "16px"
  s20: "20px"
  s24: "24px"
  s32: "32px"
  s40: "40px"
  s48: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.title}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "48px"
  button-secondary:
    backgroundColor: "{colors.surface-highlight}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "48px"
  button-outline:
    backgroundColor: "{colors.background}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "48px"
  input-text:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.r12}"
    padding: "14px 16px"
    height: "48px"
  chip-filter-selected:
    backgroundColor: "{colors.primary-muted}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "8px 16px"
  card-surface:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.r16}"
    padding: "16px"
---

# Design System: Mube

## 1. Overview

**Creative North Star: "Backstage Control Room"**

Mube is a dark, focused product interface for people actively making music work happen. The system should feel like a practical backstage control room: low glare, quick to scan, direct in tone, and built around the next useful action. The app is not a poster, a social feed clone, or a corporate dashboard. It is a working surface for finding people, evaluating credibility, applying to gigs, saving profiles, and starting conversations.

The visual system uses restrained dark surfaces, a rare pink primary action, compact sans typography, and pill-shaped controls. Energy comes from the user's content, profile media, avatars, stories, and state feedback. The UI itself stays organized and avoids spectacle unless the moment is genuinely celebratory, such as a match or completion event.

Mube explicitly rejects the PRODUCT.md anti-references: generic social network, corporate SaaS dashboard, nightlife flyer, dating app clone, decorative card grids, generic hero-metric layouts, vague "community" messaging, excessive gradients, overused glass effects, and UI that hides practical information behind spectacle.

**Key Characteristics:**
- Dark-only product shell with low glare and high content contrast.
- Primary pink is a working signal for action, selection, progress, and current state.
- Surfaces are mostly tonal, not shadow-heavy.
- Components are familiar, dense enough for mobile workflows, and consistent across features.
- Portuguese UI copy stays direct, specific, and tied to music work.

## 2. Colors

The palette is restrained: near-black product surfaces, one saturated pink action color, and small semantic colors for state.

### Primary
- **Stage Signal Pink**: The primary action and brand color. Use for the main action on a screen, active navigation, selected filters, progress, links, and high-value state indicators.
- **Pressed Stage Pink**: Pressed and active-state variant for primary actions. Use only for interaction feedback, not as a second accent.
- **Muted Stage Pink**: Low-emphasis selected background for filters, active pills, and subtle indicators.

### Secondary
- **Band Fuchsia**: Badge color for band identity. Keep it scoped to profile typing and classification.
- **Studio Red**: Badge color for studio identity. Keep it scoped to profile typing and classification.
- **Avatar Pastels**: Deterministic avatar fallback colors. They provide identity variation without turning the whole screen into a palette exercise.

### Tertiary
- **Info Blue**, **Success Green**, **Warning Amber**, and **Error Red**: Semantic state colors for snackbars, validation, status messages, permission states, and system feedback. These colors must be paired with text or icons, never used as the only meaning carrier.

### Neutral
- **Deep Stage Black**: Global background for the app shell and major screens.
- **Quiet Surface**: Default card, sheet, input, and container background.
- **Raised Surface**: Elevated surface for selected cards, denser panels, and secondary separation.
- **Hover Surface**: Dividers, selected backgrounds, hover treatments, skeleton highlights, and low emphasis controls.
- **Working Border**: Standard 1px border on cards, inputs, sheets, and selection components.
- **Primary Text**, **Secondary Text**, and **Tertiary Text**: Main reading hierarchy. Do not use opacity-only text styles when these tokens already communicate hierarchy.

### Named Rules

**The One Signal Rule.** Stage Signal Pink is rare and functional. If everything is pink, nothing is actionable.

**The State Must Speak Rule.** Success, error, warning, and info must include text or an icon. Color alone is forbidden.

**The Scene Is The Content Rule.** Use user photos, media, names, roles, instruments, locations, and gigs for character. Do not decorate the chrome to compensate for weak content.

## 3. Typography

**Display Font:** Poppins with Inter fallback
**Body Font:** Inter with system-ui fallback
**Label/Mono Font:** Inter with system-ui fallback

**Character:** Poppins gives headings and buttons a confident product voice without feeling formal. Inter keeps dense lists, forms, labels, messages, and metadata legible on mobile.

### Hierarchy

- **Display** (700, 28px, 1.2): Screen-level headlines, onboarding moments, and rare high-emphasis product moments.
- **Headline** (700, 18-24px, 1.25): Section headings, app bar titles, empty state titles, and compact screen headers.
- **Title** (600, 14-18px, 1.3): Card titles, list item names, form group titles, and component headings.
- **Body** (500, 12-16px, 1.3-1.5): Main UI text, descriptions, empty state copy, form text, chat-adjacent labels, and support content. Keep long prose near 65-75 characters per line when it appears.
- **Label** (500-700, 10-14px, 1.2): Buttons, chips, nav labels, helper labels, counters, profile type labels, and metadata.

### Named Rules

**The Product Type Rule.** Do not use display styling for controls, dense metadata, or labels. UI labels must stay compact and predictable.

**The Scan First Rule.** Names, roles, location, instruments, and availability need a clearer hierarchy than decorative headings.

## 4. Elevation

Mube is tonal by default. Depth is conveyed primarily through surface color, borders, selected backgrounds, and spacing. Shadows exist for floating navigation, overlays, buttons, and momentary emphasis, but standard cards and panels should remain visually quiet.

### Shadow Vocabulary

- **Card Shadow** (`0 4px 12px rgba(10,10,10,0.5)`): Use sparingly for cards that truly need separation from a busy surface.
- **Floating Shadow** (`0 12px 32px rgba(10,10,10,0.6)`): Use for bottom navigation, popups, overlays, and elements that float above content.
- **Subtle Shadow** (`0 2px 8px rgba(10,10,10,0.3)`): Use for low elevation on interactive elements.
- **Button Glow** (`0 2px 8px rgba(232,70,108,0.3)`): Use only when a button needs added emphasis beyond its fill.
- **None**: Default for cards, app bars, dialogs, sheets, and most containers.

### Named Rules

**The Flat Until Needed Rule.** Surfaces are flat at rest. Add elevation only when it clarifies layering, floating position, or interaction state.

**The Glass Is Not The Brand Rule.** Blur and glass tokens exist, but overused glass effects are prohibited. Use solid surfaces first.

## 5. Components

### Buttons

Buttons are pill-shaped, tactile, and direct. They should read as product controls, not marketing CTAs.

- **Shape:** Full pill for button controls (999px or half the component height).
- **Primary:** Stage Signal Pink background, Primary Text, Poppins 16/700, 48px medium height or 56px large height, 24-32px horizontal padding.
- **Hover / Focus:** Use overlay, press scale, and focus-visible outline. Pressed state resolves to Pressed Stage Pink. Loading state replaces the leading content with a 16px spinner.
- **Secondary / Ghost / Tertiary:** Secondary uses Hover Surface fill. Outline uses transparent fill with a surface-highlight border. Ghost uses text-only treatment and Secondary Text.

### Chips

Chips are compact filters and metadata tags, not mini cards.

- **Style:** Pill radius, 12-16px horizontal padding, 4-8px vertical padding.
- **State:** Unselected filter chips use Hover Surface. Selected filter chips use Muted Stage Pink plus a 1px pink border at 50% alpha.
- **Use:** Instruments, genres, filters, profile metadata, and removable selections.

### Cards / Containers

Cards are working containers for scannable decisions. They should not multiply without purpose.

- **Corner Style:** Gently rounded surface corners (16px).
- **Background:** Quiet Surface by default, Raised Surface for selected cards.
- **Shadow Strategy:** Flat by default. Use border and tonal difference before shadow.
- **Border:** Working Border at 1px, or Stage Signal Pink at 2px for selected selection cards.
- **Internal Padding:** 16px for dense cards, 20px for onboarding selection, 24px for broader screen sections.

### Inputs / Fields

Inputs are solid, readable, and easy to validate.

- **Style:** Quiet Surface fill, Working Border, 12px radius, 14px vertical and 16px horizontal padding.
- **Focus:** Stage Signal Pink border at 1.5px. Cursor uses Stage Signal Pink.
- **Error / Disabled:** Error uses semantic red border and error text. Disabled controls reduce opacity but must keep readable labels.

### Navigation

Navigation is adaptive and familiar. Mobile uses a floating bottom bar. Wide layouts use a navigation rail.

- **Mobile Bar:** Quiet Surface gradient, 24px radius, 16px side margin, 8px horizontal and 4px vertical inner padding, floating shadow.
- **Active State:** Stage Signal Pink icon and label, low-alpha pink capsule behind the icon, optional unread badge.
- **Inactive State:** Secondary Text at reduced opacity with outlined Material icons.
- **Wide State:** NavigationRail on Deep Stage Black with pink selected indicator and 1px divider.

### Loading, Empty, and Error States

State components must keep the user inside the task.

- **Skeletons:** Use Quiet Surface and Hover Surface shimmer. Prefer skeletons over centered spinners when content shape is known.
- **Loading Indicator:** Primary pink circular indicator, 16px inline, 32px content, 48px overlay.
- **Empty State:** Centered icon circle on Quiet Surface, Title Large, Body Medium, optional action button.
- **Snackbars:** Quiet Surface background, 12px radius, semantic icon and border, fixed behavior, 3-5 second duration based on severity.

### Signature Component: Full Width Selection Card

The onboarding selection card is the clearest signature product pattern: icon circle, title, description, selected border, and trailing selection state.

- **Shape:** 16px radius and full-width row layout.
- **Selected:** Raised Surface, 2px Stage Signal Pink border, pink icon tint, and checked indicator.
- **Unselected:** Quiet Surface, 1px Working Border, Hover Surface icon well.
- **Use:** Profile type, onboarding choices, multi-select settings, and other decisions where the user compares full text options.

## 6. Do's and Don'ts

### Do:

- **Do** use existing Flutter tokens: AppColors, AppTypography, AppSpacing, AppRadius, AppMotion, and AppEffects.
- **Do** keep Stage Signal Pink for primary actions, selected state, active navigation, progress, and meaningful feedback.
- **Do** make role, location, genre, instrument, media, availability, and social proof easy to scan in profile and gig surfaces.
- **Do** use skeleton states when the final content shape is known.
- **Do** pair semantic colors with icons or text.
- **Do** preserve the dark-only shell unless a product decision explicitly changes the theme strategy.
- **Do** write UI copy in Portuguese, direct and specific to the music-scene task.

### Don't:

- **Don't** make Mube look like a generic social network, a corporate SaaS dashboard, a nightlife flyer, or a dating app clone.
- **Don't** use decorative card grids, generic hero-metric layouts, vague "community" messaging, excessive gradients, overused glass effects, or UI that hides practical information behind spectacle.
- **Don't** use startup-deck or creator-economy language when a music-scene term is clearer.
- **Don't** hardcode color, spacing, radius, typography, or motion when a token exists.
- **Don't** use border-left or border-right greater than 1px as a colored card accent.
- **Don't** use gradient text.
- **Don't** use glassmorphism as the default surface treatment.
- **Don't** invent a new button, field, chip, app bar, loading, empty, or snackbar pattern when the design system has one.
- **Don't** rely on color alone for state, selection, validation, or severity.
