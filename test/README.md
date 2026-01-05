# Testes - MubeApp

## Estrutura

```
test/
├── helpers/                    # Utilitários de teste
│   ├── pump_app.dart          # Extension para pumpWidget com providers
│   └── test_utils.dart        # Mocks e finders comuns
├── unit/                       # Testes unitários (lógica pura)
│   ├── auth/
│   │   └── app_user_test.dart
│   └── routing/
│       └── route_paths_test.dart
├── widget/                     # Testes de widget (UI isolada)
│   └── common_widgets/
│       └── primary_button_test.dart
└── integration/                # Testes E2E (não implementado)
```

## Como Rodar

### Todos os testes
```bash
flutter test
```

### Testes específicos
```bash
flutter test test/unit/
flutter test test/widget/
flutter test test/unit/auth/app_user_test.dart
```

### Com cobertura
```bash
flutter test --coverage
```

### Em modo watch (re-roda ao salvar)
```bash
flutter test --watch
```

## Helpers Disponíveis

### `pump_app.dart`
```dart
// Renderiza widget com MaterialApp + ProviderScope
await tester.pumpApp(const MyWidget());

// Com overrides de providers
await tester.pumpApp(
  const MyWidget(),
  overrides: [myProvider.overrideWithValue(mockValue)],
);
```

### `test_utils.dart`
```dart
// Dados de teste
MockUserData.testEmail  // 'test@example.com'
MockUserData.testUid    // 'test-uid-12345'

// Container para testes de providers
final container = createTestContainer(overrides: [...]);
```

## Convenções

1. **Nomenclatura**: `{arquivo}_test.dart`
2. **Grupos**: Use `group()` para organizar cenários
3. **Descrições**: Use verbos como "renders", "calls", "returns"
4. **AAA Pattern**: Arrange, Act, Assert
