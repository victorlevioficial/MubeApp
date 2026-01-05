---
description: Padrões de UI para criar novas telas no MubeApp
---

# Workflow: Criando Novas Telas no MubeApp

Ao criar qualquer nova tela no MubeApp, siga estas regras para garantir consistência visual:

## 1. AppBar

**SEMPRE** use `MubeAppBar` ao invés de `AppBar`:

```dart
import '../../../common_widgets/mube_app_bar.dart';

// ✅ CORRETO
Scaffold(
  appBar: MubeAppBar(title: 'Título da Tela'),
  body: ...
)

// ❌ ERRADO - Não use AppBar diretamente
Scaffold(
  appBar: AppBar(title: Text('Título')),
  body: ...
)
```

## 2. Ícones

Use os ícones do design system (`AppIcons`):

```dart
import '../../../design_system/foundations/app_icons.dart';

// ✅ CORRETO
Icon(AppIcons.arrowBack)      // Seta de voltar (iOS style)
Icon(AppIcons.arrowForward)   // Seta para frente
Icon(AppIcons.dropdown)       // Dropdown arrow

// ❌ ERRADO - Não use Icons diretamente para ícones padronizados
Icon(Icons.arrow_back)  // Material style, não é o padrão do app
```

## 3. Cores

**⚠️ NUNCA use cores hardcoded como `Colors.white`, `Colors.black`, `Color(0xFF...)`!**

Use APENAS `AppColors` para todas as cores:

```dart
import '../../../design_system/foundations/app_colors.dart';

// ✅ CORRETO
color: AppColors.textPrimary   // Branco (0xFFFFFFFF)
color: AppColors.textSecondary // Cinza (0xFFBEBEBE)
color: AppColors.primary       // Rosa/Pink (0xFFD40055)
color: AppColors.background    // Preto escuro (0x0E0E0E)
color: AppColors.surface       // Cinza escuro (0x161718)

// ❌ ERRADO - PROIBIDO usar cores hardcoded
color: Colors.white      // ❌ Use AppColors.textPrimary
color: Colors.black      // ❌ Use AppColors.background
color: Color(0xFFFFFFFF) // ❌ Use AppColors.textPrimary
```

## 4. Tipografia

Use `AppTypography` para todos os estilos de texto:

```dart
import '../../../design_system/foundations/app_typography.dart';

// ✅ CORRETO
Text('Título', style: AppTypography.titleMedium)
Text('Corpo', style: AppTypography.bodyMedium)

// ❌ ERRADO
Text('Título', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
```

## 5. Espaçamento

Use `AppSpacing` para margens e paddings:

```dart
import '../../../design_system/foundations/app_spacing.dart';

// ✅ CORRETO
padding: EdgeInsets.all(AppSpacing.s16)
SizedBox(height: AppSpacing.s8)

// ❌ ERRADO
padding: EdgeInsets.all(16)
```

## 6. Background

Sempre defina o background do Scaffold:

```dart
Scaffold(
  backgroundColor: AppColors.background,
  appBar: MubeAppBar(title: 'Título'),
  body: ...
)
```

## 7. Estrutura de Arquivos

- Telas vão em: `lib/src/features/[feature]/presentation/`
- Widgets específicos: `lib/src/features/[feature]/presentation/widgets/`
- Widgets compartilhados: `lib/src/common_widgets/`
