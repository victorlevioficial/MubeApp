---
description: Este documento define as convenções e boas práticas para o desenvolvimento do MubeApp, baseado em lições aprendidas durante o projeto.
---

## 📦 Estrutura de Providers (Riverpod)

### Regra #1: Evitar Dependências Circulares

**Antes de criar um provider que escuta outro, verifique:**

```
Se ProviderA.build() usa ref.listen(ProviderB) ou ref.watch(ProviderB),
então ProviderB NUNCA pode chamar ref.read(ProviderA)
```

**Exemplo do que NÃO fazer:**
```dart
// ❌ ERRADO - Cria ciclo
class FeedItemsNotifier extends Notifier<FeedItemsState> {
  @override
  FeedItemsState build() {
    ref.listen(favoritesProvider, ...); // Escuta favoritesProvider
    return FeedItemsState();
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  Future<void> toggleFavorite(String id) async {
    ref.read(feedItemsProvider.notifier).update(...); // ❌ CICLO!
  }
}
```

**Solução correta:**
```dart
// ✅ CORRETO - Fluxo unidirecional
class FeedItemsNotifier extends Notifier<FeedItemsState> {
  @override
  FeedItemsState build() {
    ref.listen(favoritesProvider, (_, next) {
      _syncFromFavorites(next); // Reage às mudanças
    });
    return FeedItemsState();
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  Future<void> toggleFavorite(String id) async {
    state = state.copyWith(...); // ✅ Só atualiza próprio estado
    // FeedItemsNotifier vai reagir automaticamente via listener
  }
}
```

### Regra #2: Fonte Única da Verdade

Para cada dado, defina **uma única fonte da verdade**:

| Dado | Fonte da Verdade | Cache Local |
|------|------------------|-------------|
| `favoriteIds` | `favoritesProvider` | - |
| `FeedItem` (com `isFavorited`) | `feedItemsProvider` | - |
| `favoriteCount` (persistido) | Firestore | `FeedItem.favoriteCount` |

---

## 🔥 Firestore

### Regra #3: Sempre Logar Operações de Escrita

```dart
Future<void> operacaoFirestore() async {
  print('DEBUG: Iniciando operação para $userId');
  try {
    await _firestore.runTransaction(...);
    print('DEBUG: Operação concluída com sucesso');
    
    // Verificação pós-escrita (opcional em debug)
    final doc = await ref.get();
    print('DEBUG: Valor atual no banco: ${doc.data()}');
  } catch (e) {
    print('DEBUG: ERRO: $e');
    rethrow;
  }
}
```

### Regra #4: Validar Regras de Segurança Antes de Implementar

Antes de implementar uma feature que escreve no Firestore:

1. Abra `firestore.rules`
2. Verifique se a operação é permitida
3. Se necessário, adicione regra específica:

```javascript
// Exemplo: Permitir update apenas de um campo específico
allow update: if request.auth != null &&
  request.resource.data.diff(resource.data).affectedKeys().hasOnly(['favoriteCount']);
```

---

## ✅ Checklist Para Novas Features

Antes de implementar qualquer feature que envolva estado reativo:

```markdown
## Feature: [Nome da Feature]

### Análise de Estado
- [ ] Qual provider é a fonte da verdade?
- [ ] Quem lê esse provider?
- [ ] Quem escreve nesse provider?
- [ ] Existe risco de dependência circular?

### Firestore
- [ ] As regras de segurança permitem a operação?
- [ ] Logs de debug estão implementados?

### UI
- [ ] O widget é `Consumer` ou `ConsumerWidget`?
- [ ] Usa `ref.watch` com `select` para rebuilds granulares?
- [ ] Fallback para valores padrão se provider não tiver dados?

### Testes
- [ ] Teste unitário para lógica de estado?
- [ ] Teste de widget para interação?
```

---

## 🎨 Widgets e UI

### Regra #5: Usar Providers Granulares

**Evite:**
```dart
// ❌ Reconstrói quando QUALQUER item muda
final state = ref.watch(feedItemsProvider);
final item = state.items[itemId];
```

**Prefira:**
```dart
// ✅ Reconstrói apenas quando ESTE item muda
final item = ref.watch(feedItemProvider(itemId));

// ✅ Ainda mais granular - só quando isFavorited muda
final isFavorited = ref.watch(feedItemIsFavoritedProvider(itemId));
```

### Regra #6: Registrar Item Antes de Operar

Se uma operação depende de um item estar no provider:
```dart
void _toggleFavorite(WidgetRef ref) {
  // Garantir que o item existe no provider
  if (ref.read(feedItemsProvider).items[item.uid] == null) {
    ref.read(feedItemsProvider.notifier).loadItems([item]);
  }
  
  // Agora é seguro operar
  ref.read(favoritesProvider.notifier).toggleFavorite(item.uid);
}
```

---

## 🧪 Testes

### Regra #7: Testar Lógica de Estado Isoladamente

```dart
test('toggleFavorite deve atualizar favoriteIds', () async {
  final container = ProviderContainer();
  final notifier = container.read(favoritesProvider.notifier);
  
  await notifier.toggleFavorite('user123');
  
  expect(
    container.read(favoritesProvider).favoriteIds,
    contains('user123'),
  );
});
```

---

## 📋 Resumo das Regras

| # | Regra | Categoria |
|---|-------|-----------|
| 1 | Se A escuta B, B não pode chamar A | Providers |
| 2 | Definir fonte única da verdade | Providers |
| 3 | Logar todas as operações de Firestore | Firestore |
| 4 | Validar regras de segurança antes de implementar | Firestore |
| 5 | Usar providers granulares com `select` | UI |
| 6 | Registrar item no provider antes de operar | UI |
| 7 | Testar lógica de estado isoladamente | Testes |

---

*Documento criado em 06/01/2026 com base em lições aprendidas durante a implementação da feature de favoritos.*
