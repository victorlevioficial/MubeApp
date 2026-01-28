---
description: Design-system
---

# Mube Design System

> **Versão:** 1.0.0
> **Última Atualização:** 26/01/2026
> **Padrão Obrigatório:** Todas as novas telas e componentes DEVEM seguir rigorosamente estas definições.

Este documento serve como a "Fonte da Verdade" para o design do aplicativo Mube. Agentes e Desenvolvedores devem consultar este arquivo antes de criar qualquer interface.

---

## 1. Fundações (Foundations)

### 1.1 Cores (`AppColors`)

O sistema de cores é centralizado em `lib/src/design_system/foundations/app_colors.dart`.
Evite usar cores hardcoded (`Color(0xFF...)`). Use sempre os tokens semânticos.

| Token | Valor (Aprox) | Uso Recomendado |
| :--- | :--- | :--- |
| **`brandPrimary`** | `#D40055` (Razzmatazz) | Identidade da marca, logos, elementos institucionais. |
| **`semanticAction`** | `#FF5C8D` (Neon Pink) | **Ações de Interface**: Botões, Links, Ícones clicáveis. Otimizado para contraste em fundo escuro. |
| **`background`** | `#0A0A0A` (Deep Black) | Fundo padrão de todas as telas (`Scaffold`). |
| **`surface`** | `#18181B` (Zinc 900) | Cartões, Modais, BottomSheets. |
| **`surfaceHighlight`** | `#27272A` (Zinc 800) | Bordas, divisores, estados de hover/pressed. |
| **`textPrimary`** | `#FFFFFF` (White) | Títulos, texto principal. |
| **`textSecondary`** | `#A1A1AA` (Zinc 400) | Subtítulos, descrições secundárias. |
| **`textTertiary`** | `#52525B` (Zinc 600) | Placeholders, textos desabilitados. |
| **`error`** | `#EF4444` (Red) | Mensagens de erro, validação negativa. |
| **`success`** | `#22C55E` (Green) | Mensagens de sucesso, validação positiva. |

### 1.2 Tipografia (`AppTypography`)

Fonte Padrão: **Inter** (Google Fonts).
Centralizado em: `lib/src/design_system/foundations/app_typography.dart`.

| Token | Tamanho | Peso | Uso |
| :--- | :--- | :--- | :--- |
| **`headlineLarge`** | 28sp | Bold (700) | Cabeçalhos principais de telas grandes. |
| **`headlineMedium`** | 20sp | Bold (700) | Títulos de seções importantes. |
| **`titleLarge`** | 18sp | SemiBold (600) | Títulos de Cards ou Modais. |
| **`bodyMedium`** | 14sp | Medium (500) | Texto padrão de leitura. |
| **`bodySmall`** | 12sp | Medium (500) | Legendas, datas, metadados. |
| **`cardTitle`** | 16sp | Bold (700) | *Específico:* Título dentro de Feed Cards. |
| **`chipLabel`** | 10sp | Medium (500) | *Específico:* Texto dentro de Chips/Tags. |

### 1.3 Espaçamento (`AppSpacing`)

Use sempre múltiplos de 4.
Centralizado em: `lib/src/design_system/foundations/app_spacing.dart`.

*   **Pequeno:** `s4`, `s8` (elementos relacionados)
*   **Médio:** `s12`, `s16` (padding padrão de containers/cards)
*   **Grande:** `s24`, `s32` (separação de seções)
*   **Margem de Tela:** `s16` (Padding horizontal padrão)

---

## 2. Componentes Globais (`Common Widgets`)

### 2.1 MubeAppBar (OBRIGATÓRIO) 🚨

**Nunca** use o widget `AppBar` nativo do Flutter diretamente. Use sempre `MubeAppBar`.
Isso garante consistência no ícone de voltar (seta iOS), cores de texto e background.

**Caminho:** `lib/src/common_widgets/mube_app_bar.dart`

#### Como Usar:

```dart
import 'package:mube/src/common_widgets/mube_app_bar.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    // ✅ CORRETO:
    appBar: MubeAppBar(
      title: 'Minha Tela',
      centerTitle: true, // Padrão é true
      showBackButton: true, // Automático se houver histórico
      actions: [
        IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
      ],
    ),
    // ❌ ERRADO:
    // appBar: AppBar(title: Text('Minha Tela')),
    body: ...
  );
}
```

### 2.2 Botões

*   **`PrimaryButton`:** Ação principal da tela (ex: "Salvar", "Entrar").
*   **`SecondaryButton`:** Ação secundária ou "Cancel" (Outlined style).
*   **`AppFilterChip`:** Para filtros e seleção múltipla.

### 2.3 Inputs

*   **`AppTextField`:** Input de texto padrão com suporte a labels e ícones.
*   **`AppDropdownField`:** Seleção de lista.

### 2.4 Feedback

*   **`AppSnackbar`:** Para toasts e feedback flutuante (Success/Error/Info).
*   **`AppSkeleton`:** Para estados de loading (Shimmer effect).

---

## 3. Diretrizes de Desenvolvimento

1.  **Impostos:** Sempre importe classes de fundação (`app_colors.dart`, etc.) ao invés de hardcodar valores.
2.  **Responsividade:** Use `Expanded` e `Flexible` com sabedoria. Evite tamanhos fixos em pixels para alturas de containers grandes.
3.  **Dark Mode:** O app é *Dark Mode First*. Assegure-se de que textos pretos não estão sendo usados sobre funco escuro. Use `AppColors.textPrimary` (Branco) como padrão.
