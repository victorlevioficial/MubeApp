# MubeApp Architecture Documentation

## Overview

MubeApp é um aplicativo Flutter que conecta músicos, bandas e estúdios. Este documento descreve a arquitetura técnica, padrões de código e decisões de design.

## Stack Tecnológica

### Framework & Linguagem
- **Flutter**: 3.32+ (SDK mínimo)
- **Dart**: 3.8+ (null-safety obrigatório)

### Backend & Infraestrutura
- **Firebase Core**: Autenticação e infraestrutura
- **Cloud Firestore**: Banco de dados NoSQL
- **Firebase Storage**: Armazenamento de mídia
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Analytics**: Métricas e eventos
- **Firebase Crashlytics**: Monitoramento de erros
- **Firebase Remote Config**: Feature flags

### State Management
- **Riverpod 3.x**: Gerenciamento de estado reativo
- **Riverpod Generator**: Geração automática de providers

### Navegação
- **Go Router**: Navegação declarativa com deep linking

### Geração de Código
- **Freezed**: Classes imutáveis e union types
- **JSON Serializable**: Serialização/deserialização JSON
- **Build Runner**: Automação de geração de código

### UI & Design
- **Material Design 3**: Componentes nativos do Flutter
- **Custom Theme**: Design System próprio
- **Shimmer**: Animações de loading
- **Cached Network Image**: Cache de imagens

### Programação Funcional
- **FPDart**: Tipos funcionais (Either, Option, etc)

## Arquitetura em Camadas

O projeto segue uma arquitetura **Feature-First Layered Architecture**:

```
lib/
├── src/
│   ├── app.dart                    # Configuração do MaterialApp
│   ├── main.dart                   # Entry point
│   │
│   ├── constants/                  # Constantes globais
│   │   ├── app_constants.dart
│   │   └── firestore_constants.dart
│   │
│   ├── core/                       # Camada Core (compartilhada)
│   │   ├── data/                   # Repositórios e datasources
│   │   ├── domain/                 # Entidades e interfaces
│   │   ├── errors/                 # Tratamento de erros
│   │   ├── providers/              # Providers globais
│   │   ├── services/               # Serviços (Analytics, Remote Config)
│   │   └── typedefs.dart           # Tipos compartilhados
│   │
│   ├── design_system/              # Design System
│   │   ├── components/             # Componentes UI reutilizáveis
│   │   ├── foundations/            # Tokens (cores, tipografia, espaçamento)
│   │   └── showcase/               # Widgetbook/Galeria de componentes
│   │
│   ├── features/                   # Features (módulos)
│   │   ├── auth/                   # Autenticação
│   │   ├── chat/                   # Mensagens
│   │   ├── feed/                   # Feed principal
│   │   ├── favorites/              # Favoritos
│   │   ├── matchpoint/             # Match/Tinder-like
│   │   ├── onboarding/             # Onboarding de novos usuários
│   │   ├── profile/                # Perfil do usuário
│   │   ├── search/                 # Busca
│   │   ├── settings/               # Configurações
│   │   └── support/                # Suporte/Tickets
│   │
│   ├── routing/                    # Configuração de rotas
│   │   └── app_router.dart
│   │
│   ├── shared/                     # Código compartilhado entre features
│   │   └── services/
│   │
│   └── utils/                      # Utilitários
│       ├── app_logger.dart
│       └── extensions/
│
└── test/                           # Testes
    ├── integration/                # Testes de integração
    ├── unit/                       # Testes unitários
    └── widget/                     # Testes de widget
```

## Padrões de Código

### 1. Nomenclatura

#### Arquivos
```
# Controllers (Riverpod)
{nome}_controller.dart
{nome}_controller.g.dart          # Gerado

# Models/Entities
{nome}_model.dart
{nome}_entity.dart

# Repository Pattern
{nome}_repository.dart
{nome}_remote_data_source.dart
{nome}_local_data_source.dart

# Screens
{nome}_screen.dart

# Widgets
{nome}_widget.dart
{nome}_card.dart
{nome}_list.dart

# Services
{nome}_service.dart
```

#### Classes
```dart
// Controllers
class FeedController extends StateNotifier<FeedState>

// Repositories  
class FeedRepository {

// Data Sources
class FeedRemoteDataSource {

// Models (Freezed)
@freezed
class FeedItem with _$FeedItem {
```

### 2. Estrutura de Features

Cada feature segue a estrutura:

```
features/{feature_name}/
├── data/                       # Camada de dados
│   ├── {feature}_repository.dart
│   ├── {feature}_remote_data_source.dart
│   └── models/                 # Modelos específicos
│
├── domain/                     # Camada de domínio
│   ├── {feature}_entity.dart   # Entidades (opcional)
│   └── {feature}_state.dart    # Estados
│
└── presentation/               # Camada de apresentação
    ├── {feature}_screen.dart
    ├── {feature}_controller.dart
    ├── {feature}_controller.g.dart
    └── widgets/                # Widgets específicos
```

### 3. Gerenciamento de Estado (Riverpod)

#### Controller Pattern
```dart
@Riverpod(keepAlive: true)
class FeedController extends _$FeedController {
  @override
  FutureOr<FeedState> build() {
    return const FeedState();
  }
  
  Future<void> loadData() async {
    // Lógica de negócio
  }
}
```

#### Consumo no Widget
```dart
class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedControllerProvider);
    final controller = ref.read(feedControllerProvider.notifier);
    
    return state.when(
      data: (state) => FeedContent(state: state),
      loading: () => FeedSkeleton(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### 4. Tratamento de Erros

Usamos **Either** (FPDart) para tratamento funcional de erros:

```dart
// Repository
FutureResult<List<FeedItem>> getFeed() async {
  try {
    final data = await _dataSource.fetch();
    return Right(data);
  } on FirebaseAuthException catch (e) {
    return Left(AuthFailure.fromCode(e.code));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}

// Controller
final result = await _repository.getFeed();
result.fold(
  (failure) => state = AsyncError(failure, StackTrace.current),
  (data) => state = AsyncData(data),
);
```

### 5. Navegação

Usamos **Go Router** com rotas tipadas:

```dart
// Definição
GoRoute(
  path: '/profile/:id',
  builder: (context, state) => ProfileScreen(
    userId: state.pathParameters['id']!,
  ),
),

// Navegação
context.push('/profile/123');
context.go('/home');
context.pop();
```

## Design System

### Tokens

#### Cores
```dart
AppColors.background       // Fundo principal
AppColors.surface          // Cards e containers
AppColors.brandPrimary     // Cor da marca
AppColors.textPrimary      // Texto principal
AppColors.textSecondary    // Texto secundário
```

#### Espaçamento
```dart
AppSpacing.xs              // 4
AppSpacing.sm              // 8
AppSpacing.md              // 16
AppSpacing.lg              // 24
AppSpacing.xl              // 32
```

#### Tipografia
```dart
AppTextStyles.heading1     // Títulos grandes
AppTextStyles.heading2     // Títulos médios
AppTextStyles.body         // Texto corrido
AppTextStyles.caption      // Legendas
```

### Componentes

#### Botões
```dart
AppButton.primary(
  onPressed: () {},
  child: Text('Entrar'),
)

AppButton.secondary(
  onPressed: () {},
  child: Text('Cancelar'),
)
```

#### Inputs
```dart
AppTextField(
  label: 'Email',
  hint: 'seu@email.com',
  validator: (value) => validateEmail(value),
)
```

#### Loading
```dart
AppShimmer.box(width: 200, height: 100)
AppShimmer.circle(size: 48)
```

## Integração com Firebase

### Autenticação

```dart
// Login
await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Auth State
final authState = ref.watch(authStateChangesProvider);
```

### Firestore

```dart
// Stream de dados
final usersStream = FirebaseFirestore.instance
  .collection('users')
  .snapshots();

// Query única
final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get();
```

### Storage

```dart
// Upload
final ref = FirebaseStorage.instance
  .ref()
  .child('images/$userId/profile.jpg');
await ref.putFile(imageFile);

// Download URL
final url = await ref.getDownloadURL();
```

## Testes

### Estrutura de Testes

```
test/
├── integration/              # Testes de integração
│   ├── auth/
│   ├── feed/
│   └── chat/
│
├── unit/                     # Testes unitários
│   ├── auth/
│   ├── core/
│   └── routing/
│
├── widget/                   # Testes de widget
│   ├── auth/
│   └── design_system/
│
└── helpers/
    └── pump_app.dart         # Helper para pump widgets
```

### Exemplo de Teste Unitário

```dart
group('FeedRepository', () {
  test('should return Right(List<FeedItem>) on success', () async {
    // Arrange
    when(mockDataSource.getUsers()).thenAnswer((_) async => mockData);
    
    // Act
    final result = await repository.getUsers();
    
    // Assert
    expect(result.isRight(), true);
  });
});
```

### Exemplo de Teste de Widget

```dart
testWidgets('should show login button', (tester) async {
  await tester.pumpApp(const LoginScreen());
  
  expect(find.text('Entrar'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

## Performance

### Otimizações Implementadas

1. **Paginação**: Feed usa cursor-based pagination
2. **Cache de Imagens**: CachedNetworkImage com limites de memória
3. **Shimmer**: Placeholders animados durante carregamento
4. **Lazy Loading**: ListView.builder para listas grandes
5. **Riverpod keepAlive**: Providers que persistem estado
6. **Geohash**: Busca por localização otimizada

### Boas Práticas

- ✅ Usar `const` constructors quando possível
- ✅ Evitar rebuilds desnecessários com `Consumer` específicos
- ✅ Usar `select` do Riverpod para observar apenas campos específicos
- ✅ Limitar tamanho de imagens antes do upload
- ✅ Usar paginação para coleções grandes

## Segurança

### Firestore Rules
- ✅ Todas as operações exigem autenticação
- ✅ Validação de ownership em todos os recursos
- ✅ Updates parciais validados
- ✅ Least privilege principle

### Dados Sensíveis
- ❌ Nunca logar senhas ou tokens
- ✅ Usar Firebase App Check
- ✅ Validar dados no cliente e servidor

## Deploy

### Build
```bash
# Debug
flutter run

# Profile
flutter run --profile

# Release
flutter build apk --release          # Android
flutter build ios --release          # iOS
```

### CI/CD
O projeto usa GitHub Actions para:
- ✅ Análise estática (flutter analyze)
- ✅ Testes unitários
- ✅ Build de verificação

## Contribuindo

### Antes de Commit
1. Rodar `flutter analyze` - deve ter 0 erros
2. Rodar `flutter test` - todos os testes devem passar
3. Verificar formatação com `dart format`

### Code Review Checklist
- [ ] Código segue os padrões de nomenclatura
- [ ] Tratamento de erros adequado
- [ ] Testes inclusos
- [ ] Documentação atualizada
- [ ] Não há prints (usar AppLogger)

## Recursos

### Documentação
- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Documentation](https://firebase.google.com/docs)

### Tools
- [Widgetbook](https://widgetbook.io) - Galeria de componentes
- [Flutter Inspector](https://docs.flutter.dev/tools/devtools/inspector)

## Troubleshooting

### Problemas Comuns

**Erro: "Target of URI doesn't exist"**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Erro: "No tests match"**
Verificar se o arquivo termina com `_test.dart`

**Erro: "Firebase not configured"**
Verificar se `google-services.json` e `GoogleService-Info.plist` estão configurados

## Contato

Para dúvidas sobre a arquitetura:
- Criar issue no GitHub
- Consultar documentação em `/docs`
