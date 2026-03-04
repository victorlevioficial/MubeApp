# Mube Design System

> Version: 3.0.0
> Last Updated: 2026-03-04
> Status: canonical source of truth

Este e o unico documento canônico do design system do Mube.
Ele deve refletir o codigo real em:

- `lib/src/design_system/**`
- `lib/src/app.dart`
- `lib/src/routing/app_router.dart`

Documentos paralelos, espelhos tecnicos e auditorias antigas nao sao mais a fonte de verdade.

## 1. Escopo

O design system do app cobre:

- foundations: tokens, motion, effects e theme
- componentes compartilhados
- contrato visual para novas telas
- APIs canônicas e APIs legadas/deprecadas

Regras gerais:

1. Novas telas devem usar componentes e tokens do design system antes de recorrer a widgets Material puros.
2. Nao hardcode cor, tipografia, spacing, radius ou motion se houver token existente.
3. Se um componente novo for realmente necessario, ele deve ser reutilizavel e entrar no design system, nao ficar isolado na feature.

## 2. Foundations

### 2.1 Colors

Arquivo: `lib/src/design_system/foundations/tokens/app_colors.dart`

Tokens principais:

| Token | Hex | Uso |
| --- | --- | --- |
| `primary` | `#E8466C` | acao primaria e brand |
| `primaryPressed` | `#D13F61` | estado pressionado |
| `background` | `#0A0A0A` | fundo global |
| `surface` | `#141414` | cards e containers base |
| `surface2` | `#1F1F1F` | superficie elevada |
| `surfaceHighlight` | `#292929` | divisores, destaque e hover sutil |
| `border` | `#383838` | borda padrao |
| `textPrimary` | `#FFFFFF` | texto principal |
| `textSecondary` | `#B3B3B3` | texto secundario |
| `textTertiary` | `#8A8A8A` | texto terciario e placeholder |
| `error` | `#EF4444` | erro |
| `success` | `#22C55E` | sucesso |
| `info` | `#3B82F6` | informacao |
| `warning` | `#F59E0B` | alerta |

Outros grupos semanticos disponiveis:

- `primaryGradient`
- `primaryMuted`
- `primaryDisabled`
- `textPlaceholder`
- `textDisabled`
- `badgeMusician`
- `badgeBand`
- `badgeStudio`
- `skeletonBase`
- `skeletonHighlight`
- `avatarColors`
- `avatarBorder`
- `medalGold`
- `medalSilver`
- `medalBronze`
- `celebrationPink`

### 2.2 Typography

Arquivo: `lib/src/design_system/foundations/tokens/app_typography.dart`

Familias:

- Display: `Poppins`
- Body: `Inter`

Escalas base:

- Headlines: `headlineLarge` 28, `headlineCompact` 24, `headlineMedium` 20, `headlineSmall` 18
- Titles: `titleLarge` 18, `titleMedium` 16, `titleSmall` 14
- Body: `bodyLarge` 16, `bodyMedium` 14, `bodySmall` 12
- Labels: `labelLarge` 14, `labelMedium` 13, `labelSmall` 11

Estilos semanticos disponiveis:

- `cardTitle`
- `chipLabel`
- `settingsGroupTitle`
- `profileTypeLabel`
- `matchSuccessTitle`
- `matchSuccessKicker`
- `buttonPrimary`
- `buttonSecondary`
- `input`
- `inputHint`
- `error`
- `link`

### 2.3 Spacing

Arquivo: `lib/src/design_system/foundations/tokens/app_spacing.dart`

Scale tokens:

- `s2`
- `s4`
- `s8`
- `s10`
- `s12`
- `s14`
- `s16`
- `s20`
- `s24`
- `s32`
- `s40`
- `s48`

Presets mais usados:

- `all4`, `all8`, `all12`, `all16`, `all24`
- `h8`, `h12`, `h16`, `h24`, `h32`
- `v8`, `v12`, `v16`, `v24`, `v32`
- `h16v12`, `h16v8`, `h24v16`
- `screenPadding`, `screenHorizontal`

### 2.4 Radius

Arquivo: `lib/src/design_system/foundations/tokens/app_radius.dart`

Scale tokens:

- `r4`
- `r8`
- `r12`
- `r16`
- `r20`
- `r24`
- `rPill`

Radius semanticos:

- `chatBubble`
- `card`
- `bottomSheet`
- `modal`
- `input`
- `button`
- `chip`
- `avatar`

Helpers disponiveis:

- `all4`, `all8`, `all12`, `all16`, `all20`, `all24`, `pill`
- `top24`, `top16`
- `circular()`, `horizontal()`, `vertical()`

### 2.5 Motion

Arquivo: `lib/src/design_system/foundations/tokens/app_motion.dart`

Durations:

- `short`
- `medium`
- `standard`
- `long`

Curves:

- `standardCurve`
- `emphasizedCurve`
- `leavingCurve`
- `bounceCurve`

### 2.6 Effects

Arquivo: `lib/src/design_system/foundations/tokens/app_effects.dart`

Shadows:

- `cardShadow`
- `floatingShadow`
- `subtleShadow`
- `buttonShadow`
- `none`

Blur:

- `glassBlur`
- `lightBlur`
- `heavyBlur`
- `blurFilter`
- `lightBlurFilter`

Glass:

- `glassColor`
- `glassDecoration`
- `glassCardDecoration`

Opacity and durations:

- `disabledOpacity`
- `secondaryOpacity`
- `tertiaryOpacity`
- `hoverOpacity`
- `pressOpacity`
- `fast`
- `normal`
- `slow`
- `entrance`

## 3. Theme Contract

Arquivo: `lib/src/design_system/foundations/theme/app_theme.dart`

Contrato atual:

- `ThemeData(useMaterial3: true, brightness: Brightness.dark)`
- app dark-only
- `ColorScheme.dark` alinhado a `AppColors`
- theming centralizado para:
  - `AppBar`
  - `Dialog`
  - `Card`
  - `PopupMenu`
  - `TextButton`
  - `ElevatedButton`
  - `OutlinedButton`
  - `InputDecoration`
  - `Checkbox`
  - `BottomSheet`
  - `SnackBar`
  - `DatePicker`
  - `TimePicker`

Integracoes globais:

- tema aplicado em `lib/src/app.dart`
- scroll behavior em `lib/src/design_system/foundations/theme/app_scroll_behavior.dart`

## 4. Component Inventory

Base path: `lib/src/design_system/components/`

Categorias atuais:

| Categoria | Quantidade atual |
| --- | --- |
| `badges` | 1 |
| `buttons` | 3 |
| `chips` | 2 |
| `data_display` | 2 |
| `feedback` | 7 |
| `inputs` | 8 |
| `interactions` | 1 |
| `loading` | 4 |
| `navigation` | 5 |
| `patterns` | 6 |

## 5. Canonical APIs

Estas sao as APIs preferenciais para novas features.

### 5.1 Navigation

- `AppAppBar`
- `MainScaffold`
- `ResponsiveCenter`
- `AppBackButton`

### 5.2 Buttons

- `AppButton`
- `SocialLoginButton`
- `AppLikeButton`

### 5.3 Inputs and Selection

- `AppTextField`
- `AppDropdownField`
- `AppDatePickerField`
- `AppAutocompleteField`
- `AppSelectionModal`
- `EnhancedMultiSelectModal`
- `AppCheckbox`

### 5.4 Chips

- `AppFilterChip`
- `AppChip`

### 5.5 Feedback and States

- `AppSnackBar`
- `AppConfirmationDialog`
- `AppInfoDialog`
- `AppOverlay`
- `AppRefreshIndicator`
- `EmptyStateWidget`
- `ErrorBoundary`

### 5.6 Loading

- `AppLoadingIndicator`
- `AppLoadingOverlay`
- `AppShimmer`
- `AppSkeleton`

### 5.7 Data Display

- `UserAvatar`
- `OptimizedImage`

### 5.8 Patterns

- `FadeInSlide`
- `FullWidthSelectionCard`
- `OnboardingHeader`
- `OnboardingProgressBar`
- `OnboardingSectionCard`
- `OrDivider`

## 6. Legacy and Deprecated APIs

Estas APIs ainda existem para compatibilidade, mas nao devem ser usadas em codigo novo:

- `MubeAppBar`
  - alias deprecado para `AppAppBar`
- `AppLoading`
  - loader legado; preferir `AppLoadingIndicator`
- `AppScaffold`
  - shell legado; o router usa `MainScaffold`

## 7. Mandatory Rules for New Work

1. Use `AppAppBar` para app bars de telas padrao.
2. Use `AppButton` para acoes principais e secundarias.
3. Use `AppTextField` para inputs de texto padrao.
4. Use `AppSnackBar` para feedback transiente.
5. Use `AppLoadingIndicator` para loading e `AppLoadingOverlay` para bloqueio de tela.
6. Use `AppFilterChip` para filtros quando o padrao visual existente atender.
7. Use tokens de `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppMotion` e `AppEffects` antes de criar estilos customizados.
8. Se um widget Material puro for necessario por uma razao de UX real, isso deve ser uma excecao consciente e documentada no contexto da mudanca.

## 8. Known Exceptions

Excecoes ainda toleradas no app:

- alguns `TextButton` nativos de baixa enfase quando o tema global ja garante consistencia
- alguns usos residuais de cores especiais em fluxos comemorativos ou overlays, quando ainda nao foram encapsulados melhor

Essas excecoes nao autorizam expandir uso de widgets nativos ou estilos hardcoded em novas features.

## 9. Checklist para Novas Features

Antes de implementar UI nova:

1. verificar se a tela pode usar `AppAppBar`
2. verificar se botoes podem usar `AppButton`
3. verificar se formularios podem usar `AppTextField`, `AppDropdownField`, `AppDatePickerField` e modais de selecao existentes
4. verificar se estados vazios, loading e feedback podem usar componentes compartilhados
5. aplicar apenas tokens do design system para cor, spacing, radius, typography e motion
6. se faltar um componente, promover um componente reutilizavel para o design system em vez de criar uma versao isolada na feature

## 10. Maintenance Policy

Este documento deve ser atualizado quando houver:

- adicao ou remocao de tokens
- adicao, remocao ou deprecacao de componentes
- mudanca de API canonica
- mudanca estrutural relevante no `MainScaffold` ou no contrato global de tema

Nao manter espelhos ou documentos paralelos de especificacao e auditoria para o design system.
