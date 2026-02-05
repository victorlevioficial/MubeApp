# Relatorio de Design - Mube

## Visao Geral
- App Flutter com backend Firebase, arquitetura modular por `features`, e Design System proprio (tokens + componentes).
- Tema global dark aplicado via `AppTheme`.
- Fluxos principais: auth/onboarding, feed, search, matchpoint (swipe), chat, profile, settings, support, notifications e admin.

## Arquitetura e Navegacao
- Bootstrap e servicos: `C:\Users\Victor\Desktop\AppMube\lib\main.dart`
- App raiz e tema: `C:\Users\Victor\Desktop\AppMube\lib\src\app.dart` + `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\theme\app_theme.dart`
- Rotas: `C:\Users\Victor\Desktop\AppMube\lib\src\routing\app_router.dart` (GoRouter + AuthGuard + shell com bottom nav)

## Dependencias-chave (por categoria)
- Arquitetura: Riverpod, GoRouter, Freezed/Json
- Firebase: Core, Firestore, Auth, Messaging, Storage, Analytics, Crashlytics, Remote Config, App Check
- UI/UX: Google Fonts, SVG, Shimmer, Cached Network Image, Video Player/Compress/Crop, GNav, Card Swiper
- Utilidades: Geolocator, Shared Preferences, HTTP, Intl, Local Notifications, Easy Refresh, Share/PDF/Printing

## Mapa de Telas/Features (principais)
- Auth: login, register, forgot, email verification
- Onboarding: type, form e flows (band/studio/professional/contractor)
- Feed: feed principal, listas, cards vertical/compact, skeletons
- Search: tela, filtros, modal, tabs, cards
- MatchPoint: intro, explore, matches, wizard, swipe, sucesso
- Chat: conversas e chat
- Profile: profile, public profile, edit, invites, gallery
- Settings: settings, privacy, addresses, edit address
- Support: support, ticket list, create ticket
- Notifications e Admin

## Mudancas aplicadas no Design System
- Cor primaria unica: `#E8466C`, pressed `#D13F61`, disabled 30%
- Escala de cinza oficial: `#0A0A0A`, `#141414`, `#1F1F1F`, `#292929`, `#383838`
- Tipografia: Poppins para titulos/subtitulos, Inter para textos e labels
- Chips unificados (filter/skill/genre) em `AppChip`
- `RankBadge` criado com `primaryMuted` (20%)
- Espacamento e raio enxutos (sem s6/s20/s64 e sem r20/r28)

---

# Design System (Tokens oficiais)

## Cores - AppColors
`C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_colors.dart`

| Token | Valor | Uso/Significado |
|---|---|---|
| `_primary` | `#E8466C` | Primaria base |
| `_primaryPressed` | `#D13F61` | Primaria pressionada |
| `_bgDeep` | `#0A0A0A` | Background oficial |
| `_bgSurface` | `#141414` | Surface (cards) |
| `_bgSurface2` | `#1F1F1F` | Surface 2 (elevada) |
| `_bgHighlight` | `#292929` | Surface highlight |
| `_border` | `#383838` | Borda padrao |
| `_textWhite` | `#FFFFFF` | Texto primario |
| `_textGray` | `#B3B3B3` | Texto secundario |
| `_textDarkGray` | `#8A8A8A` | Texto terciario |
| `_error` | `#EF4444` | Erro |
| `_success` | `#22C55E` | Sucesso |
| `_info` | `#3B82F6` | Info |
| `_warning` | `#F59E0B` | Warning |
| `_badgeFuchsia` | `#C026D3` | Badge band |
| `_badgeRed` | `#DC2626` | Badge studio |
| `_badgeChipBg` | `#1F1F23` | Fundo badge chip |
| `primary` | `#E8466C` | Primaria unica |
| `primaryPressed` | `#D13F61` | Estado pressed |
| `primaryMuted` | `#E8466C` 20% | Primaria 20% |
| `primaryDisabled` | `#E8466C` 30% | Desabilitado |
| `primaryGradient` | `#E8466C -> #D13F61` | Gradiente sutil |
| `background` | `#0A0A0A` | Fundo |
| `surface` | `#141414` | Card/surface |
| `surface2` | `#1F1F1F` | Surface elevada |
| `surfaceHighlight` | `#292929` | Highlight |
| `border` | `#383838` | Bordas |
| `textPrimary` | `#FFFFFF` | Texto |
| `textSecondary` | `#B3B3B3` | Texto secundario |
| `textTertiary/textPlaceholder` | `#8A8A8A` | Baixa enfase |
| `textDisabled` | `#FFFFFF` 50% | Desabilitado |
| `error/success/info/warning` | `#EF4444/#22C55E/#3B82F6/#F59E0B` | Feedback |
| `badgeMusician` | `primary` | Badge musico |
| `badgeBand` | `#C026D3` | Badge banda |
| `badgeStudio` | `#DC2626` | Badge estudio |
| `badgeChipBackground` | `#1F1F23` | Fundo badge |
| `skeletonBase/Highlight` | `#141414/#292929` | Skeleton |
| `avatarColors` | `#F472B6,#A78BFA,#60A5FA,#34D399,#FBBF24,#F87171` | Avatar |
| `avatarBorder` | `#0A0A0A` | Borda avatar |

## Espacamentos - AppSpacing
`C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_spacing.dart`

| Token | Valor |
|---|---|
| `s2,s4,s8,s12,s16,s24,s32,s40,s48` | `2,4,8,12,16,24,32,40,48` |
| `all4/all8/all12/all16/all24` | `EdgeInsets.all(4/8/12/16/24)` |
| `h8/h12/h16/h24/h32` | `EdgeInsets.symmetric(horizontal)` |
| `v8/v12/v16/v24/v32` | `EdgeInsets.symmetric(vertical)` |
| `h16v12/h16v8/h24v16` | `EdgeInsets.symmetric(h/v)` |
| `screenPadding` | `EdgeInsets.symmetric(16,24)` |
| `screenHorizontal` | `EdgeInsets.symmetric(16,0)` |

## Arredondamentos - AppRadius
`C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_radius.dart`

| Token | Valor |
|---|---|
| `r4,r8,r12,r16,r24,rPill` | `4,8,12,16,24,999` |
| `chatBubble,card,bottomSheet,modal,input,button,chip,avatar` | `12,16,24,24,12,999,999,999` |
| `all4/all8/all12/all16/all24/pill` | `BorderRadius` |
| `top24/top16` | `BorderRadius.vertical(top)` |

## Tipografia - AppTypography
`C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_typography.dart`

Headlines e titles usam Poppins. Body/labels/buttons usam Inter.

| Token | Size | Weight | LetterSpacing | Height |
|---|---|---|---|---|
| `headlineLarge` | 28 | 700 | -0.5 | - |
| `headlineMedium` | 20 | 700 | -0.3 | - |
| `headlineSmall` | 18 | 700 | -0.2 | - |
| `titleLarge` | 18 | 600 | -0.2 | - |
| `titleMedium` | 16 | 600 | -0.1 | - |
| `titleSmall` | 14 | 600 | 0 | - |
| `bodyLarge` | 16 | 500 | 0 | 1.5 |
| `bodyMedium` | 14 | 500 | 0 | 1.4 |
| `bodySmall` | 12 | 500 | 0 | 1.3 |
| `labelLarge` | 14 | 500 | 0 | - |
| `labelMedium` | 13 | 500 | 0 | - |
| `labelSmall` | 11 | 500 | 0.1 | - |
| `cardTitle` | 16 | 700 | -0.1 | - |
| `chipLabel` | 10 | 500 | 0.1 | - |
| `buttonPrimary` | 16 | 700 | 0 | - |
| `buttonSecondary` | 16 | 500 | 0 | - |
| `input/inputHint` | 14 | 500 | 0 | - |
| `error` | 12 | 500 | 0 | - |

---

# Hardcoded fora do Design System

Nota: a lista abaixo foi gerada antes da padronizacao de tokens desta etapa. Recomenda-se revarrer o projeto para atualizar os itens hardcoded restantes.

## Cores hardcoded
| Arquivo:linha | Valor | Contexto |
|---|---|---|
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\data_display\user_avatar.dart:118` | `Colors.black.withValues(alpha: 0.65)` | sombra do avatar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\inputs\app_autocomplete_field.dart:152` | `Colors.transparent` | scrim overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\inputs\app_autocomplete_field.dart:171` | `Colors.black.withValues(alpha: 0.15)` | sombra dropdown |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\inputs\app_dropdown_field.dart:118` | `Colors.transparent` | scrim overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\inputs\app_dropdown_field.dart:132` | `Colors.black.withValues(alpha: 0.5)` | sombra dropdown |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\theme\app_theme.dart:180` | `Colors.transparent` | shadowColor do ElevatedButton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\navigation\app_scaffold.dart:34` | `Colors.transparent` | indicatorColor nav |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\navigation\main_scaffold.dart:28` | `Colors.transparent` | indicatorColor nav |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_chip.dart:94` | `Colors.transparent` | fundo chip skill |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_chip.dart:145` | `Colors.white` | icone chip filtro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_chip.dart:152` | `Colors.white` | texto chip filtro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_chip.dart:163` | `Colors.white` | close chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_filter_chip.dart:62` | `Colors.white` | icone selecionado |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_filter_chip.dart:69` | `Colors.white` | texto selecionado |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\app_filter_chip.dart:80` | `Colors.white` | close |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\mube_filter_chip.dart:47` | `Colors.white` | icone selecionado |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\chips\mube_filter_chip.dart:54` | `Colors.white` | texto selecionado |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\components\buttons\app_social_button.dart:32` | `Colors.transparent` | background |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:25` | `Colors.black` 50% | cardShadow |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:34` | `Colors.black` 60% | floatingShadow |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:43` | `Colors.black` 30% | subtleShadow |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:91` | `Colors.white` 3% | glass bg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:92` | `Colors.white` 8% | glass border |
| `C:\Users\Victor\Desktop\AppMube\lib\src\design_system\foundations\tokens\app_effects.dart:99` | `Colors.white` 10% | glassCard border |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\search_screen.dart:192` | `Colors.transparent` | background modal filtro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\widgets\favorites_filter_bar.dart:53` | `Colors.white` | label chip selecionado |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:30` | `Colors.black` 20% | sombra card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:85` | `Colors.transparent` | gradiente overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:86` | `Colors.black` 0% | gradiente overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:87` | `Colors.black` 80% | gradiente overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:88` | `Colors.black` 95% | gradiente overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:129` | `Colors.white` 20% | chip idade |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:198` | `Colors.red` | icone debug |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:208` | `Colors.red` | SnackBar debug |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_swipe_deck.dart:30` | `Colors.white` | texto vazio |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_swipe_deck.dart:80` | `Colors.white` (alpha variavel) | icone overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_swipe_deck.dart:179` | `Colors.black` 20% | sombra botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_swipe_deck.dart:188` | `Colors.transparent` | Material botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:17` | `Colors.black` 85% | overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:36` | `Colors.white24` | divisor |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:69` | `Colors.white` | botao bg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:70` | `Colors.black` | botao fg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:79` | `Colors.black` | texto botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\matchpoint_tabs_screen.dart:60` | `Colors.white` 5% | borda tabs |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\matchpoint_tabs_screen.dart:64` | `Colors.transparent` | bg tabs |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\matchpoint_tabs_screen.dart:66` | `Colors.white` | activeColor |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\matchpoint_tabs_screen.dart:81` | `Colors.white` | label tab |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\matchpoint_tabs_screen.dart:89` | `Colors.white` | label tab |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:76` | `Colors.white` | "IT'S A" |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:116` | `Colors.white` | fundo icone |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:141` | `Colors.white` | texto |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:193` | `Colors.white` | borda avatar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:196` | `Colors.black` 30% | sombra avatar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:207` | `Colors.white` | icone pessoa |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\media_viewer_dialog.dart:55` | `Colors.white` | icone fechar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\media_viewer_dialog.dart:68` | `Colors.white` | texto indicador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\media_viewer_dialog.dart:87` | `Colors.white` | placeholder YouTube |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\media_viewer_dialog.dart:108` | `Colors.red` | icone erro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\public_gallery_grid.dart:89` | `Colors.white` | icone play |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:247` | `Colors.transparent` | Material slot vazio |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:105` | `Colors.red` | icone erro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:110` | `Colors.white` | texto erro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:122` | `Colors.white` | progress |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:131` | `Colors.black` | fundo player |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:151` | `Colors.black` 70% | gradiente |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:152` | `Colors.transparent` | gradiente |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:153` | `Colors.transparent` | gradiente |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:154` | `Colors.black` 70% | gradiente |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:171` | `Colors.black` 60% | botao play |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:179` | `Colors.white` | icone play |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:217` | `Colors.transparent` | Material slider |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:227` | `Color(0xFFFF2D55)` | activeTrack |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:230` | `Colors.white24` | inactiveTrack |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:231` | `Color(0xFFFF2D55)` | thumb |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:232` | `Color(0xFFFF2D55)` | overlay |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:269` | `Colors.white` | tempo atual |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:275` | `Colors.black` | sombra tempo |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:285` | `Colors.white` | tempo total |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_video_player.dart:291` | `Colors.black` | sombra tempo |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:46` | `Colors.transparent` | surfaceTint |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:294` | `Colors.black` 20% | sombra bottom bar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:378` | `Colors.black` 20% | sombra bottom bar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:718` | `Colors.black87` | barrier dialog |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:695` | `Colors.white` 5% | borda TabBar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:700` | `Colors.white` | label TabBar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:721` | `Colors.transparent` | divider TabBar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:769` | `Colors.white` 20% | borda avatar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:837` | `Colors.white` | icone camera |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\report_reason_dialog.dart:43` | `Colors.transparent` | background dialog |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:153` | `Colors.black` 20% | sombra card acao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:160` | `Colors.transparent` | Material card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\ticket_list_screen.dart:90` | `Colors.transparent` | Material |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:212` | `Colors.transparent` | Material logout |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:36` | `Colors.black` 20% | sombra card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:33` | `Colors.transparent` | Material |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\notifications\presentation\notification_list_screen.dart:66` | `Colors.white` | icone delete |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\notifications\presentation\notification_list_screen.dart:227` | `Colors.transparent` | Material |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:204` | `Colors.white` | badge/icone |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:173` | `Colors.red` | background debug |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:393` | `Colors.white` | icone enviar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\admin\presentation\maintenance_screen.dart:245` | `Colors.black` | card relatorio |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\admin\presentation\maintenance_screen.dart:247` | `Colors.white10` | borda |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\admin\presentation\maintenance_screen.dart:254` | `Colors.greenAccent` | texto |
| `C:\Users\Victor\Desktop\AppMube\lib\src\core\providers\connectivity_provider.dart:78` | `Colors.orange` | banner offline |
| `C:\Users\Victor\Desktop\AppMube\lib\src\core\providers\connectivity_provider.dart:85` | `Colors.white` | icone |
| `C:\Users\Victor\Desktop\AppMube\lib\src\core\providers\connectivity_provider.dart:90` | `Colors.white` | texto |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\forgot_password_screen.dart:100` | `Colors.transparent` | AppBar bg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\flows\onboarding_band_flow.dart:277` | `Colors.transparent` | bottom sheet bg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\flows\onboarding_professional_flow.dart:676` | `Colors.transparent` | bottom sheet bg |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\flows\onboarding_studio_flow.dart:304` | `Colors.transparent` | borda card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\flows\onboarding_studio_flow.dart:389` | `Colors.transparent` | bottom sheet bg |

## Espacamentos hardcoded
| Arquivo:linha | Valor | Contexto |
|---|---|---|
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\search_screen.dart:227` | `80` | `SizedBox(height: 80)` load-more |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\favorites_screen.dart:212` | `8.0` | `EdgeInsets.symmetric(vertical: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\favorites_screen.dart:252` | `8` | `SizedBox(height: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\favorites_screen.dart:276` | `16` | `SizedBox(height: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\favorites_screen.dart:299` | `80` | `SizedBox(height: 80)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\public_gallery_grid.dart:82` | `4,2` | padding badge |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:170` | `6,2` | padding badge |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:183` | `2` | `SizedBox(width: 2)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:351` | `12` | `EdgeInsets.all(12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:20` | `8` | `SizedBox(width: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:322` | `56` | `SizedBox(height: 56)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:397` | `14` | `EdgeInsets.symmetric(vertical: 14)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:629` | `12,6` | padding chips |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:643` | `12,6` | padding chips |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:670` | `32` | padding galeria vazia |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:438` | `100` | `SizedBox(height: 100)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:689` | `20,10,20,20` | `EdgeInsets.fromLTRB` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:722` | `4` | `EdgeInsets.all(4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:752` | `24,10` | padding form |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\edit_profile_screen.dart:826` | `8` | padding botao camera |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\invites_screen.dart:63` | `48` | botao Recusar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\invites_screen.dart:74` | `48` | botao Sair da banda |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\invites_screen.dart:87` | `48` | botao Aceitar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:52` | `8` | `EdgeInsets.only(top: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:103` | `40` | padding empty state |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:263` | `2` | `SizedBox(height: 2)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:282` | `8,2` | padding status |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:299` | `4` | `SizedBox(height: 4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:324` | `6,4` | padding botao cancelar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:336` | `4` | `SizedBox(width: 4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:33` | `16,8` | padding body |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:39` | `32` | `SizedBox(height: 32)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:177` | `16` | `SizedBox(height: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:182` | `12` | `SizedBox(height: 12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:195` | `40` | `SizedBox(height: 40)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:220` | `8` | `SizedBox(width: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_item.dart:33` | `16,16` | padding item |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_item.dart:41` | `16` | `SizedBox(width: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_item.dart:61` | `1` | Divider height |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_item.dart:62` | `0.5` | Divider thickness |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_item.dart:64` | `54` | Divider indent |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_group.dart:18` | `4,12` | margin group |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_group.dart:33` | `24` | `SizedBox(height: 24)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:82` | `8,2` | padding badge |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:102` | `4` | `SizedBox(height: 4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:150` | `12` | `SizedBox(width: 12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:164` | `12` | `SizedBox(width: 12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:25` | `20` | padding card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:61` | `20` | `SizedBox(width: 20)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:76` | `4` | `SizedBox(height: 4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:92` | `8` | `EdgeInsets.all(8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:108` | `12` | `SizedBox(height: 12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:147` | `16,16` | padding section |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:158` | `12` | `SizedBox(width: 12)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:31` | `8` | `EdgeInsets.only(bottom: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:40` | `12,12` | padding tile |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:58` | `16` | `SizedBox(width: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:75` | `2` | `SizedBox(height: 2)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:37` | `16` | `SizedBox(width: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:51` | `32` | `SizedBox(height: 32)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:71` | `16,8` | padding FAQ |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:89` | `16,0,16,16` | padding FAQ |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:168` | `10` | padding icone |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\support_screen.dart:175` | `8` | `SizedBox(height: 8)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\ticket_list_screen.dart:46` | `16` | padding list |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\support\presentation\ticket_list_screen.dart:97` | `16` | padding item |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\login_screen.dart:117` | `80` | `EdgeInsets.copyWith(top: 80)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\login_screen.dart:215` | `56` | `SizedBox(height: 56)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:81` | `80` | `EdgeInsets.copyWith(top: 80)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:124` | `16` | `SizedBox(height: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:167` | `16` | `EdgeInsets.symmetric(horizontal: 16)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\forgot_password_screen.dart:169` | `56` | botao enviar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\forgot_password_screen.dart:220` | `56` | botao voltar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\email_verification_screen.dart:457` | `56` | botao reenviar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\email_verification_screen.dart:480` | `56` | botao Ja verifiquei |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_form_screen.dart:240` | `24` | `SizedBox(height: 24)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:81` | `24,40` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:92` | `48` | `SizedBox(height: 48)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:105` | `4` | `SizedBox(height: 4)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:113` | `32` | `SizedBox(height: 32)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:145` | `56` | `SizedBox(height: 56)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\onboarding_type_screen.dart:156` | `24` | `SizedBox(height: 24)` |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\steps\onboarding_address_step.dart:450` | `12,6` | padding chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\steps\onboarding_address_step.dart:511` | `56` | botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\onboarding\presentation\flows\onboarding_contractor_flow.dart:326` | `56` | botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_compact.dart:56` | `2` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_section_widget.dart:51` | `176` | altura secao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:35` | `44` | skeleton filtro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:42` | `8` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:54` | `12` | header skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:67` | `8` | header skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:105` | `12` | secao skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:106` | `180` | lista horizontal |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:113` | `12` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\vertical_feed_list.dart:221` | `80` | espaco fim lista |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\quick_filter_bar.dart:25` | `48` | altura barra |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\quick_filter_bar.dart:27` | `16` | padding lateral |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\quick_filter_bar.dart:30` | `8` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:223` | `2` | divisores |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:244` | `8` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:403` | `10` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:419` | `4` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:172` | `8,3` | chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:197` | `8,3` | chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:250` | `6` | separador chips |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\widgets\search_filter_bar.dart:35` | `40` | altura |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\widgets\search_filter_bar.dart:42` | `8` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\widgets\category_tabs.dart:28` | `8` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\profile_type_badge.dart:46` | `6` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\profile_type_badge.dart:48` | `4` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\widgets\favorites_filter_bar.dart:25` | `44` | altura |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\widgets\favorites_filter_bar.dart:28` | `16` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\widgets\favorites_filter_bar.dart:31` | `8` | separador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\favorites\presentation\widgets\favorites_filter_bar.dart:40` | `12,8` | padding chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:45` | `50` | altura |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:65` | `150` | bottom |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\matchpoint_tutorial_overlay.dart:71` | `32,16` | padding botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:96` | `160` | altura avatars |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:114` | `8` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\notifications\presentation\notification_list_screen.dart:265` | `2` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\notifications\presentation\notification_list_screen.dart:290` | `6` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\notifications\presentation\notification_list_screen.dart:292` | `8` | indicador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:107` | `16,6` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:122` | `16` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:168` | `4` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:194` | `10,4` | padding badge |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:221` | `16` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:312` | `12,12,8,8` | padding input |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:351` | `16,12` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:371` | `8` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:388` | `20` | loader |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:424` | `4` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:434` | `12,8` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:477` | `4` | espacamento |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:507` | `16` | padding |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:513` | `16` | bottom |

## Arredondamentos hardcoded
| Arquivo:linha | Valor | Contexto |
|---|---|---|
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\search\presentation\search_screen.dart:172` | `BorderRadius.circular(12)` | botao filtro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:26` | `BorderRadius.circular(24)` | card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:37` | `BorderRadius.circular(24)` | clip card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:130` | `BorderRadius.circular(8)` | chip idade |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\widgets\match_card.dart:170` | `BorderRadius.circular(100)` | chips tags |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\public_gallery_grid.dart:57` | `BorderRadius.circular(8)` | thumbnail |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\public_gallery_grid.dart:85` | `BorderRadius.circular(4)` | badge video |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:148` | `BorderRadius.circular(12)` | slot imagem |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:173` | `BorderRadius.circular(4)` | badge video |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:239` | `BorderRadius.circular(12)` | slot vazio |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:265` | `Radius.circular(20)` | bottom sheet |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:345` | `BorderRadius.circular(12)` | container |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:363` | `BorderRadius.circular(4)` | progress |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:46` | `BorderRadius.circular(4)` | skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:180` | `Radius.circular(24)` | bottom sheet |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:288` | `BorderRadius.circular(4)` | badge |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:322` | `BorderRadius.circular(4)` | botao cancelar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:185` | `BorderRadius.circular(20)` | chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_header.dart:247` | `BorderRadius.circular(10)` | botao seta |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:65` | `BorderRadius.circular(16)` | card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:175` | `BorderRadius.circular(20)` | chip |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_section_widget.dart:93` | `BorderRadius.circular(12)` | card Ver todos |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:124` | `BorderRadius.circular(16)` | card skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_skeleton.dart:158` | `BorderRadius.circular(100)` | chip skeleton |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\settings_screen.dart:208` | `BorderRadius.circular(16)` | botao logout |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:30` | `BorderRadius.circular(12)` | card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:53` | `BorderRadius.circular(10)` | icone |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:30` | `BorderRadius.circular(24)` | card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:50` | `BorderRadius.circular(20)` | mini card |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\neon_settings_tile.dart:36` | `BorderRadius.circular(16)` | tile |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:48` | `BorderRadius.circular(12)` | popup |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\public_profile_screen.dart:399` | `BorderRadius.circular(12)` | botao acao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\invites_screen.dart:171` | `BorderRadius.circular(28)` | botao |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:356` | `BorderRadius.circular(24)` | input |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:437` | `Radius.circular(20/4)` | bubble chat |

## Tipografia hardcoded
| Arquivo:linha | Valores | Contexto |
|---|---|---|
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\media_viewer_dialog.dart:67` | `fontSize: 16` | texto indicador |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\widgets\gallery_grid.dart:188` | `fontSize: 10` | label Video |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:293` | `fontSize: 10, fontWeight: w500` | status convite |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\bands\presentation\manage_members_screen.dart:341` | `fontSize: 12, fontWeight: w600` | botao cancelar |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:119` | `fontSize: 12, fontWeight: w500` | distancia |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_vertical.dart:181` | `fontSize: 9, fontWeight: w600` | chip skill |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_compact.dart:33` | `fontSize: 13, fontWeight: w700` | nome |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\feed\presentation\widgets\feed_card_compact.dart:59` | `fontSize: 10, fontWeight: w500` | distancia |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\settings_group.dart:23` | `fontSize: 11, weight bold, letterSpacing 2` | titulo grupo |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\address_card.dart:94` | `fontSize: 10, weight w600` | badge principal |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\settings\presentation\widgets\bento_header.dart:71` | `height: 1.1` | nome usuario |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\profile\presentation\profile_screen.dart:85` | `letterSpacing: 1.5, weight bold` | label perfil |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\login_screen.dart:143` | `fontSize: 24` | titulo login |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:100` | `fontSize: 24` | titulo cadastro |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:73` | `fontSize: 12` | texto legal |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\auth\presentation\register_screen.dart:188` | `fontSize: 12, weight bold` | link Termos |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\conversations_screen.dart:146` | `fontSize: 16, weight bold/w600` | nome conversa |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\chat\presentation\chat_screen.dart:73` | `fontSize: 10` | horario bubble |
| `C:\Users\Victor\Desktop\AppMube\lib\src\features\matchpoint\presentation\screens\match_success_screen.dart:83` | `fontSize: 48, weight w900, letterSpacing 2` | MATCH |

---

## Direcao de design observada
- Base visual dark consistente, com accent rosa (#D71E68 / #FF5C8D).
- Tipografia Inter com pesos altos e micro-labels pequenas (9-12px).
- Ritmo de spacing usa tokens, mas ha muitos valores soltos.
- Raios misturam tokens com valores ad-hoc (12/16/20/24/28/100).

## Proximos passos sugeridos
1. Centralizar hardcoded em tokens especificos (chips, badges, overlays).
2. Padronizar raios e espacamentos nos pontos listados.
3. Gerar CSV completo para analise externa.
