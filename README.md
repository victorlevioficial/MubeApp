# Mube - Conectando Músicos

Aplicativo mobile para conectar músicos, bandas, estúdios e contratantes no Brasil.

## 📱 Sobre o Projeto

O Mube é uma plataforma que facilita a conexão entre profissionais da música. Nossa missão é criar oportunidades para músicos encontrarem bandas, estúdios disponibilizarem seus serviços e contratantes descobrirem talentos.

### Funcionalidades Principais

- 🔐 **Autenticação**: Login e cadastro com email/senha
- 👤 **Perfis**: Criação de perfis para músicos, bandas, estúdios e contratantes
- 🔍 **Busca**: Encontre profissionais por localização, gênero musical, instrumentos e mais
- 💖 **MatchPoint**: Sistema de match para conectar músicos compatíveis
- 💬 **Chat**: Conversas em tempo real entre usuários
- ⭐ **Favoritos**: Salve perfis favoritos para acesso rápido
- 🔔 **Notificações**: Push notifications para matches e mensagens
- 🎨 **Design System**: Interface consistente e moderna com tema dark

## 🚀 Tecnologias

- **Framework**: Flutter 3.8+
- **Linguagem**: Dart
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **State Management**: Riverpod
- **Navegação**: GoRouter
- **Arquitetura**: Clean Architecture

## 📁 Estrutura do Projeto

```
lib/
├── src/
│   ├── core/           # Configurações, erros, providers globais
│   ├── design_system/  # Componentes UI, tokens, tema
│   ├── features/       # Funcionalidades do app (por feature)
│   │   ├── auth/       # Autenticação
│   │   ├── feed/       # Feed principal
│   │   ├── search/     # Busca
│   │   ├── matchpoint/ # Sistema de match
│   │   ├── chat/       # Mensagens
│   │   ├── profile/    # Perfil do usuário
│   │   └── ...
│   ├── routing/        # Configuração de rotas
│   └── utils/          # Utilitários
├── l10n/               # Internacionalização (PT/EN)
└── main.dart           # Entry point
```

## 🛠️ Configuração do Ambiente

### Pré-requisitos

- Flutter SDK >= 3.8.0
- Dart SDK >= 3.8.0
- Android Studio / Xcode (para emuladores)
- Conta Firebase configurada

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/mube.git
cd mube
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Firebase:
   - Adicione o `google-services.json` em `android/app/`
   - Adicione o `GoogleService-Info.plist` em `ios/Runner/`

4. Configure as API Keys (opcional para desenvolvimento):
```bash
# Crie o arquivo .vscode/launch.json com as chaves:
# GOOGLE_VISION_API_KEY
# GOOGLE_MAPS_API_KEY
```

5. Execute o app:
```bash
flutter run
```

## 📦 Build de Release

### Android

```bash
# APK
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

Veja o [BUILD_GUIDE.md](BUILD_GUIDE.md) para instruções detalhadas.

## 🧪 Testes

```bash
# Rodar todos os testes
flutter test

# Rodar testes específicos
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

## 📝 Convenções de Código

- **Lint**: `flutter_lints` configurado
- **Formatação**: `dart format`
- **Const constructors**: Sempre que possível para melhor performance
- **Imports**: Organizados em ordem alfabética

## 🌐 Internacionalização

O app suporta:
- 🇧🇷 Português (Brasil) - Padrão
- 🇺🇸 Inglês

## 📄 Licença

Este projeto é privado e de propriedade da Mube.

## 🤝 Contribuição

Para contribuir com o projeto:

1. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
2. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
3. Push para a branch (`git push origin feature/nova-feature`)
4. Abra um Pull Request

## 📞 Suporte

Para suporte ou dúvidas, entre em contato através do app ou pelo email: suporte@mube.app

---

**Versão**: 1.0.0+1  
**Última atualização**: Fevereiro 2026
