se voce fosse fazer um app do zero, com essas especificações:

Aplicativo mobile para conectar músicos, bandas, estúdios e contratantes no Brasil.

📱 Sobre o Projeto
O Mube é uma plataforma que facilita a conexão entre profissionais da música. Nossa missão é criar oportunidades para músicos encontrarem bandas, estúdios disponibilizarem seus serviços e contratantes descobrirem talentos.

Funcionalidades Principais
🔐 Autenticação: Login e cadastro com email/senha
👤 Perfis: Criação de perfis para músicos, bandas, estúdios e contratantes
🔍 Busca: Encontre profissionais por localização, gênero musical, instrumentos e mais
💖 MatchPoint: Sistema de match para conectar músicos compatíveis
💬 Chat: Conversas em tempo real entre usuários
⭐ Favoritos: Salve perfis favoritos para acesso rápido
🔔 Notificações: Push notifications para matches e mensagens
🎨 Design System: Interface consistente e moderna com tema dark
Product Requirements Document (Reverse Engineered)
Application: Mube
Version: 1.0.0+1 (as of analysis)
Status: MVP / Production-Ready

1. Executive Summary
Mube is a social platform and utility network designed for the music ecosystem. It connects musicians, bands, studios, and event contractors, facilitating hiring, collaboration, and discovery. The app combines "LinkedIn-style" professional networking with "Tinder-style" matching (MatchPoint) for finding musical partners.

2. User User Personas
The application supports 4 distinct profile types, each with specific data fields and capabilities:

2.1 Professional (profissional)
Who: Individual musicians, singers, DJs, rodies, tech crew.
Key Data: Artistic Name, Instruments, Genres, Roles (e.g., Drummer, Sound Tech), Media Portfolio.
Apps Goals: Find bands to join, get gigs, showcase talent.
2.2 Band (banda)
Who: Musical groups, bands, orchestras.
Key Data: Band Name, Genres, current Members (linked users), Press Kit.
Apps Goals: Find replacement members, book studios, get booked for events.
2.3 Studio (estudio)
Who: Recording, rehearsal, and mixing studios.
Key Data: Services offered (Recording, Rehearsal), Equipment list, Location, Pricing/Availability (implied).
Apps Goals: Attract clients (bands/musicians) for sessions.
2.4 Contractor (contratante)
Who: Venue owners, event organizers, wedding planners.
Key Data: Organization name, Location, Event types.
Apps Goals: Discover and book talent for events.
3. Core Features & Functional Requirements
3.1 Authentication & Onboarding
Login: Email/Password and potentially Social Login (Google/Apple - infra dependencies).
Registration: Multi-step wizard.
Step 1: Account Creation (Email/Pass).
Step 2: Profile Type Selection (Crucial branching point).
Step 3: Profile Completion (Dynamic form based on Type).
Account Recovery: Password reset flow.
3.2 Main Feed
Content: Algorithmically sorted list of Cards.
Types:
Artists: Discovery of new musicians.
Opportunities: Job posts or "Looking for" ads (implied by feed structure).
Interaction: Like, Connect/Follow (implied).
3.3 MatchPoint (The "Matching" Engine)
Concept: Location-based discovery of musical partners.
Capabilities:
Radar: Find users within a specific radius (Geohash based).
Filters: Intent (Serious vs Hobby), Genres, Roles.
Swiping/Action: Send "Connect" request.
3.4 Chat & Messaging
Direct Messaging: 1-on-1 conversations between users.
MatchPoint Integration: Successful matches likely auto-create a conversation.
Media Support: Sending text, potentially images/audio.
3.5 Profile & Portfolio
Public Profile: Viewable by others. Shows Bio, Stats, Gallery.
Edit Profile: Comprehensive form to update professional details.
Media Gallery:
Photos: Up to 6 images.
Videos: Up to 3 videos (Youtube links or upload).
Management: DND reordering, Delete, Add.
3.6 Social Networking
Connections: "Invites" system to manage friend requests/band invites.
Favorites: Save interesting profiles for later.
Blocking: Privacy control to block unwanted users.
3.7 Tools & Utilities
Guitar Tuner: Built-in chromatic tuner tool for musicians (Feature flag: active).
Developer Tools: Internal menu for debugging/logging.
3.8 Settings & Privacy
Addresses: Manage saved locations (for Discovery).
Privacy: Ghost Mode (hide visibility), Account Deactivation.
Support: Ticket creation system for help.
Legal: Terms of Use and Privacy Policy viewers.
4. Navigation Structure
Bottom Navigation Bar (Main Shell):
Feed
Search
MatchPoint
Chat
Settings
Top Level Routes: Profile Edit, Public Profile, Splash, Onboarding.
5. Non-Functional Requirements
Performance: Cached images (cached_network_image), List virtualization.
Offline Mode: Basic support checking (connectivity).
Security: Auth Guards on routes, Firebase Security Rules (Backend).
qual linguagem voce usaria, qual backend? quais especificações voce usaria pra ser algo bem profissional e escalavel?






---



claude-opus-4-6-thinking

Thought for 15 seconds

The user is asking me for a comprehensive technical architecture recommendation for building the Mube app from scratch - a music networking platform. They want it to be professional and scalable. Let me provide a thorough, well-structured response covering frontend, backend, infrastructure, and all the key architectural decisions.

Let me think about this holistically:

Mobile App:

The PRD mentions Flutter (cached_network_image is a Flutter package), but since they're asking "from scratch", I should recommend what I'd actually choose.
Flutter is actually a great choice here - cross-platform, great performance, strong ecosystem.
React Native with Expo is another option but Flutter has better performance for complex UIs.
Backend:

Real-time chat, geolocation-based matching, and notifications require a backend that handles WebSockets efficiently, so I'm leaning toward Node.js with NestJS for its structure and scalability, or Go for raw performance.
PostgreSQL handles the relational data, Redis manages caching and real-time operations, and Elasticsearch powers the search functionality for discovering musicians and content.
For infrastructure, I'd containerize everything with Docker and deploy on Kubernetes for orchestration, likely on AWS or GCP depending on their existing setup and regional requirements.
Frontend:

Flutter makes sense for cross-platform iOS and Android development with strong performance and a mature widget ecosystem.
Recommended Architecture for a Brazilian Startup:

Node.js with NestJS in TypeScript for the backend, PostgreSQL with PostGIS extensions for geolocation queries, Redis for caching and real-time features, and Elasticsearch for advanced search with filters.
Object storage through S3 or Cloudflare R2 paired with a CDN for media delivery, WebSockets for real-time chat, and either custom JWT authentication or Supabase Auth for simplicity.
Start with a well-structured monolith that can be broken into microservices later as the platform scales.
I'll write the response in Portuguese since that's what the user is using.

Arquitetura Completa do Mube — Do Zero
TL;DR da Stack
text

┌─────────────────────────────────────────────────────────┐
│                        MOBILE                           │
│              Flutter (Dart) — iOS & Android              │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS / WSS
┌────────────────────────▼────────────────────────────────┐
│                     API GATEWAY                         │
│              Nginx / AWS ALB / CloudFlare                │
└──┬──────────┬──────────┬──────────┬─────────┬───────────┘
   │          │          │          │         │
┌──▼──┐  ┌───▼───┐  ┌───▼───┐  ┌──▼──┐  ┌───▼────┐
│AUTH │  │ API   │  │ CHAT  │  │MATCH│  │MEDIA   │
│SVC  │  │ CORE  │  │ SVC   │  │ SVC │  │SVC     │
└──┬──┘  └───┬───┘  └───┬───┘  └──┬──┘  └───┬────┘
   │         │          │         │          │
┌──▼─────────▼──┐  ┌────▼──┐  ┌──▼───┐  ┌───▼────┐
│  PostgreSQL   │  │ Redis │  │PostGIS│  │S3 / R2 │
│  + PostGIS    │  │       │  │       │  │+ CDN   │
└───────────────┘  └───────┘  └──────-┘  └────────┘
1. Frontend Mobile — Flutter (Dart)
Por que Flutter e não React Native?
Critério	Flutter	React Native
Performance em animações pesadas (swipe do MatchPoint)	✅ Renderiza direto via Skia/Impeller	❌ Bridge com native
UI pixel-perfect cross-platform	✅ Controle total	⚠️ Componentes nativos diferem
Hot Reload	✅	✅
Ecossistema para áudio (Tuner)	✅ flutter_audio_capture, FFT nativo	⚠️ Possível mas mais trabalhoso
Comunidade BR	✅ Enorme	✅ Grande
Web/Desktop futuro	✅ Mesmo codebase	⚠️ Limitado
Arquitetura do App Flutter
text

lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp, tema, rotas
│   ├── injector.dart               # Injeção de dependência
│   └── env.dart                    # Variáveis de ambiente
│
├── core/
│   ├── design_system/
│   │   ├── theme/
│   │   │   ├── mube_theme.dart     # ThemeData completo
│   │   │   ├── mube_colors.dart
│   │   │   ├── mube_typography.dart
│   │   │   └── mube_spacing.dart
│   │   ├── components/
│   │   │   ├── mube_button.dart
│   │   │   ├── mube_card.dart
│   │   │   ├── mube_input.dart
│   │   │   ├── mube_avatar.dart
│   │   │   ├── mube_bottom_sheet.dart
│   │   │   └── mube_skeleton.dart  # Loading states
│   │   └── tokens/
│   │       ├── border_radius.dart
│   │       ├── shadows.dart
│   │       └── animations.dart
│   │
│   ├── network/
│   │   ├── api_client.dart         # Dio wrapper
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── retry_interceptor.dart
│   │   │   └── logging_interceptor.dart
│   │   ├── websocket_client.dart
│   │   └── api_exceptions.dart
│   │
│   ├── storage/
│   │   ├── secure_storage.dart     # flutter_secure_storage
│   │   ├── local_database.dart     # Drift (SQLite)
│   │   └── cache_manager.dart
│   │
│   ├── auth/
│   │   ├── auth_state.dart
│   │   ├── auth_guard.dart
│   │   └── token_manager.dart
│   │
│   └── utils/
│       ├── extensions/
│       ├── validators.dart
│       ├── formatters.dart
│       └── geolocation.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/auth_repository_impl.dart
│   │   │   ├── datasources/auth_remote_ds.dart
│   │   │   └── models/login_request.dart
│   │   ├── domain/
│   │   │   ├── entities/user.dart
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/login_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart
│   │       ├── pages/login_page.dart
│   │       ├── pages/register_page.dart
│   │       └── widgets/login_form.dart
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── pages/profile_type_selection_page.dart
│   │       ├── pages/profile_completion_page.dart
│   │       └── widgets/step_indicator.dart
│   │
│   ├── feed/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── bloc/feed_bloc.dart
│   │       ├── pages/feed_page.dart
│   │       └── widgets/
│   │           ├── artist_card.dart
│   │           └── opportunity_card.dart
│   │
│   ├── matchpoint/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── bloc/matchpoint_bloc.dart
│   │       ├── pages/matchpoint_page.dart
│   │       └── widgets/
│   │           ├── swipe_card.dart
│   │           ├── radar_view.dart
│   │           └── match_filters.dart
│   │
│   ├── chat/
│   │   ├── data/
│   │   │   ├── datasources/chat_websocket_ds.dart
│   │   │   └── models/message_model.dart
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── conversations_bloc.dart
│   │       │   └── chat_room_bloc.dart
│   │       ├── pages/
│   │       │   ├── conversations_page.dart
│   │       │   └── chat_room_page.dart
│   │       └── widgets/
│   │           ├── message_bubble.dart
│   │           └── chat_input.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── bloc/profile_bloc.dart
│   │       ├── pages/
│   │       │   ├── public_profile_page.dart
│   │       │   └── edit_profile_page.dart
│   │       └── widgets/
│   │           ├── media_gallery.dart
│   │           ├── reorderable_photos.dart
│   │           └── profile_stats.dart
│   │
│   ├── search/
│   ├── favorites/
│   ├── tools/                      # Guitar tuner etc.
│   └── settings/
│
├── shared/
│   ├── models/
│   │   ├── profile_type.dart       # enum
│   │   ├── genre.dart
│   │   ├── instrument.dart
│   │   └── location.dart
│   ├── widgets/
│   │   ├── user_card.dart
│   │   └── genre_chip.dart
│   └── bloc/
│       └── connectivity_bloc.dart
│
└── router/
    ├── app_router.dart             # GoRouter
    ├── routes.dart
    └── guards.dart
Pacotes-chave do Flutter
YAML

# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0

  # Navigation
  go_router: ^14.0.0

  # Network
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  connectivity_plus: ^6.0.0

  # Storage
  flutter_secure_storage: ^9.0.0
  drift: ^2.15.0              # SQLite local
  sqlite3_flutter_libs: ^0.5.0

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0
  lottie: ^3.1.0

  # Media
  image_picker: ^1.0.0
  image_cropper: ^5.0.0
  video_player: ^2.8.0
  flutter_sound: ^9.0.0       # Para o tuner
  fft: ^2.0.0                 # FFT para detecção de pitch

  # Location
  geolocator: ^11.0.0
  geocoding: ^3.0.0

  # Push Notifications
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^17.0.0

  # Analytics & Monitoring
  firebase_analytics: ^10.0.0
  firebase_crashlytics: ^3.0.0
  sentry_flutter: ^7.0.0

  # DI
  get_it: ^7.6.0
  injectable: ^2.3.0

  # Utils
  intl: ^0.19.0
  url_launcher: ^6.2.0
  share_plus: ^7.0.0
  permission_handler: ^11.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  golden_toolkit: ^0.15.0     # Visual regression
  injectable_generator: ^2.4.0
  build_runner: ^2.4.0
  drift_dev: ^2.15.0
  flutter_lints: ^3.0.0
2. Backend — Go (Golang) + Node.js (serviço de chat)
Por que Go como linguagem principal?
Critério	Go	Node.js (NestJS)	Elixir	Python (FastAPI)
Latência p/ API REST	✅ ~1ms	⚠️ ~5-15ms	✅ ~2ms	⚠️ ~10-20ms
Concorrência (goroutines)	✅ Milhões	⚠️ Event loop single-thread	✅ BEAM VM	❌ GIL
Geospatial / cálculos pesados	✅	⚠️	⚠️	✅ numpy
WebSockets em escala	✅	✅ Socket.io maduro	✅ Phoenix Channels	⚠️
Facilidade de contratação BR	✅ Crescendo rápido	✅ Abundante	❌ Nicho	✅
Deploy (binário estático)	✅ 10MB container	❌ node_modules	⚠️	⚠️
Custo de infra	✅ Usa pouca RAM	⚠️	✅	⚠️
Decisão pragmática
text

Go  → API Core, Auth, MatchPoint, Feed, Profiles, Search
Node.js (com Socket.io) → Chat em tempo real (ecossistema mais maduro para WS)
Alternativa: Se o time for mais forte em TypeScript, NestJS puro funciona perfeitamente até ~500k usuários. Go brilha quando você precisa de performance extrema no matching geoespacial.

Estrutura do Backend (Go)
text

backend/
├── cmd/
│   ├── api/
│   │   └── main.go                 # Entry point da API
│   ├── worker/
│   │   └── main.go                 # Workers assíncronos
│   └── migrate/
│       └── main.go                 # Migrações de banco
│
├── internal/
│   ├── config/
│   │   ├── config.go               # Viper config
│   │   └── config.yaml
│   │
│   ├── server/
│   │   ├── server.go               # HTTP server setup
│   │   ├── middleware/
│   │   │   ├── auth.go             # JWT middleware
│   │   │   ├── cors.go
│   │   │   ├── ratelimit.go
│   │   │   ├── request_id.go
│   │   │   └── logging.go
│   │   └── router.go
│   │
│   ├── domain/                     # Entidades puras (sem dependências)
│   │   ├── user.go
│   │   ├── profile.go
│   │   ├── profile_type.go         # enum: profissional, banda, estudio, contratante
│   │   ├── match.go
│   │   ├── conversation.go
│   │   ├── message.go
│   │   └── errors.go
│   │
│   ├── auth/
│   │   ├── handler.go              # HTTP handlers
│   │   ├── service.go              # Business logic
│   │   ├── repository.go           # Interface
│   │   ├── postgres_repo.go        # Implementação
│   │   ├── jwt.go                  # Token generation/validation
│   │   └── dto.go                  # Request/Response structs
│   │
│   ├── profile/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── postgres_repo.go
│   │   └── dto.go
│   │
│   ├── matchpoint/
│   │   ├── handler.go
│   │   ├── service.go              # Algoritmo de matching
│   │   ├── repository.go
│   │   ├── postgres_repo.go        # Queries com PostGIS
│   │   ├── scorer.go               # Scoring de compatibilidade
│   │   └── geohash.go
│   │
│   ├── feed/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── repository.go
│   │   ├── postgres_repo.go
│   │   └── algorithm.go            # Ranking/sorting
│   │
│   ├── search/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── elasticsearch_repo.go
│   │
│   ├── media/
│   │   ├── handler.go
│   │   ├── service.go
│   │   ├── s3_storage.go
│   │   └── image_processor.go      # Resize, compress
│   │
│   ├── notification/
│   │   ├── service.go
│   │   ├── firebase_push.go
│   │   └── templates.go
│   │
│   └── shared/
│       ├── pagination.go
│       ├── validator.go
│       └── response.go
│
├── pkg/                            # Pacotes reutilizáveis
│   ├── postgres/
│   │   ├── client.go
│   │   └── migrations/
│   │       ├── 001_create_users.sql
│   │       ├── 002_create_profiles.sql
│   │       ├── 003_create_matches.sql
│   │       ├── 004_create_conversations.sql
│   │       └── 005_create_favorites.sql
│   ├── redis/
│   │   └── client.go
│   ├── elasticsearch/
│   │   └── client.go
│   ├── s3/
│   │   └── client.go
│   └── logger/
│       └── logger.go               # Zerolog structured logging
│
├── api/
│   └── openapi.yaml                # Spec OpenAPI 3.0
│
├── deployments/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── k8s/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── hpa.yaml                # Auto-scaling
│
├── go.mod
├── go.sum
├── Makefile
└── .env.example
Libs Go
Go

// go.mod (principais)
module github.com/mube/backend

go 1.22

require (
    // HTTP Framework
    github.com/labstack/echo/v4        // Ou gin-gonic/gin — Echo é mais leve
    
    // Database
    github.com/jackc/pgx/v5            // PostgreSQL driver (melhor que lib/pq)
    github.com/jmoiron/sqlx            // SQL helpers
    github.com/golang-migrate/migrate  // Migrações
    
    // Cache
    github.com/redis/go-redis/v9
    
    // Search
    github.com/elastic/go-elasticsearch/v8
    
    // Auth
    github.com/golang-jwt/jwt/v5
    golang.org/x/crypto                // bcrypt
    
    // Storage
    github.com/aws/aws-sdk-go-v2      // S3 compatible
    
    // Push Notifications
    firebase.google.com/go/v4
    
    // Config
    github.com/spf13/viper
    
    // Logging
    github.com/rs/zerolog
    
    // Validation
    github.com/go-playground/validator/v10
    
    // Testing
    github.com/stretchr/testify
    github.com/testcontainers/testcontainers-go
    
    // Observability
    go.opentelemetry.io/otel
    github.com/prometheus/client_golang
)
3. Serviço de Chat (Node.js/TypeScript)
text

chat-service/
├── src/
│   ├── index.ts
│   ├── server.ts
│   ├── socket/
│   │   ├── handlers/
│   │   │   ├── connection.handler.ts
│   │   │   ├── message.handler.ts
│   │   │   ├── typing.handler.ts
│   │   │   └── presence.handler.ts
│   │   ├── middleware/
│   │   │   └── auth.middleware.ts       # Valida JWT do Go
│   │   └── events.ts
│   ├── services/
│   │   ├── message.service.ts
│   │   ├── conversation.service.ts
│   │   └── notification.service.ts
│   ├── repositories/
│   │   ├── message.repository.ts        # PostgreSQL
│   │   └── presence.repository.ts       # Redis
│   └── config/
│       └── index.ts
├── package.json
├── tsconfig.json
└── Dockerfile
JSON

{
  "dependencies": {
    "socket.io": "^4.7.0",
    "@socket.io/redis-adapter": "^8.3.0",
    "pg": "^8.12.0",
    "ioredis": "^5.4.0",
    "jsonwebtoken": "^9.0.0",
    "zod": "^3.23.0",
    "pino": "^9.0.0"
  }
}
4. Banco de Dados
PostgreSQL 16 + PostGIS
SQL

-- ============================================================
-- SCHEMA PRINCIPAL
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Para busca fuzzy

-- ============================================================
-- USERS & AUTH
-- ============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    email_verified  BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    ghost_mode      BOOLEAN DEFAULT FALSE,
    fcm_token       VARCHAR(500),                  -- Push notifications
    last_seen_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- PROFILES (Polimórfico com tabela base + específicas)
-- ============================================================
CREATE TYPE profile_type AS ENUM (
    'profissional', 'banda', 'estudio', 'contratante'
);

CREATE TABLE profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            profile_type NOT NULL,
    display_name    VARCHAR(100) NOT NULL,
    bio             TEXT,
    avatar_url      VARCHAR(500),
    cover_url       VARCHAR(500),
    
    -- Location (PostGIS)
    location        GEOGRAPHY(Point, 4326),        -- lat/lng
    city            VARCHAR(100),
    state           VARCHAR(2),
    
    -- Common arrays
    genres          TEXT[] DEFAULT '{}',
    
    -- Metadata
    is_complete     BOOLEAN DEFAULT FALSE,
    intent          VARCHAR(20),                    -- 'serious', 'hobby', 'both'
    verified        BOOLEAN DEFAULT FALSE,
    
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_user ON profiles(user_id);
CREATE INDEX idx_profiles_type ON profiles(type);
CREATE INDEX idx_profiles_location ON profiles USING GIST(location);
CREATE INDEX idx_profiles_genres ON profiles USING GIN(genres);

-- Tabela específica para Profissionais
CREATE TABLE professional_profiles (
    profile_id      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    artistic_name   VARCHAR(100),
    instruments     TEXT[] DEFAULT '{}',
    roles           TEXT[] DEFAULT '{}',           -- 'baterista', 'tecnico_som', etc
    experience_years INTEGER DEFAULT 0
);

CREATE INDEX idx_prof_instruments ON professional_profiles USING GIN(instruments);

-- Tabela específica para Bandas
CREATE TABLE band_profiles (
    profile_id      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    band_name       VARCHAR(100) NOT NULL,
    formation_year  INTEGER,
    looking_for     TEXT[] DEFAULT '{}',           -- Roles que estão procurando
    member_count    INTEGER DEFAULT 0
);

-- Membros da banda (relacionamento N:N)
CREATE TABLE band_members (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    band_profile_id UUID NOT NULL REFERENCES band_profiles(profile_id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    role            VARCHAR(50),
    is_confirmed    BOOLEAN DEFAULT FALSE,
    joined_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela específica para Estúdios
CREATE TABLE studio_profiles (
    profile_id      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    studio_name     VARCHAR(100) NOT NULL,
    services        TEXT[] DEFAULT '{}',           -- 'gravacao', 'ensaio', 'mixagem'
    equipment       JSONB DEFAULT '[]',
    hourly_rate_min DECIMAL(10,2),
    hourly_rate_max DECIMAL(10,2)
);

-- Tabela específica para Contratantes
CREATE TABLE contractor_profiles (
    profile_id      UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    org_name        VARCHAR(100),
    event_types     TEXT[] DEFAULT '{}',           -- 'casamento', 'corporativo', 'bar'
    website         VARCHAR(255)
);

-- ============================================================
-- MEDIA GALLERY
-- ============================================================
CREATE TABLE media (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type            VARCHAR(10) NOT NULL CHECK (type IN ('photo', 'video')),
    url             VARCHAR(500) NOT NULL,
    thumbnail_url   VARCHAR(500),
    sort_order      INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_profile ON media(profile_id);

-- ============================================================
-- MATCHPOINT
-- ============================================================
CREATE TABLE match_actions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action          VARCHAR(10) NOT NULL CHECK (action IN ('like', 'pass', 'superlike')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(actor_id, target_id)
);

CREATE INDEX idx_match_actor ON match_actions(actor_id);
CREATE INDEX idx_match_target ON match_actions(target_id);
CREATE INDEX idx_match_action ON match_actions(action);

CREATE TABLE matches (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_a_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    profile_b_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    matched_at      TIMESTAMPTZ DEFAULT NOW(),
    is_active       BOOLEAN DEFAULT TRUE,
    
    UNIQUE(profile_a_id, profile_b_id)
);

-- ============================================================
-- CHAT / MESSAGING
-- ============================================================
CREATE TABLE conversations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id        UUID REFERENCES matches(id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ
);

CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_read_at    TIMESTAMPTZ,
    is_muted        BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (conversation_id, profile_id)
);

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES profiles(id),
    content         TEXT NOT NULL,
    type            VARCHAR(10) DEFAULT 'text' CHECK (type IN ('text', 'image', 'audio')),
    media_url       VARCHAR(500),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    
    -- Partitioning-ready
    is_deleted      BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);

-- ============================================================
-- SOCIAL
-- ============================================================
CREATE TABLE favorites (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, profile_id)
);

CREATE TABLE blocks (
    blocker_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

CREATE TABLE invites (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id       UUID NOT NULL REFERENCES profiles(id),
    receiver_id     UUID NOT NULL REFERENCES profiles(id),
    type            VARCHAR(20) NOT NULL,          -- 'band_join', 'connection'
    status          VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
    message         TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    responded_at    TIMESTAMPTZ
);

-- ============================================================
-- SUPPORT
-- ============================================================
CREATE TABLE support_tickets (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id),
    subject         VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    status          VARCHAR(20) DEFAULT 'open',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
Queries geoespaciais para o MatchPoint (Go)
Go

// matchpoint/postgres_repo.go

const findNearbyProfilesQuery = `
    SELECT 
        p.id,
        p.display_name,
        p.type,
        p.genres,
        p.avatar_url,
        p.intent,
        ST_Distance(p.location, ST_MakePoint($1, $2)::geography) AS distance_meters,
        pp.instruments,
        pp.roles
    FROM profiles p
    LEFT JOIN professional_profiles pp ON pp.profile_id = p.id
    WHERE 
        p.id != $3
        AND p.is_complete = true
        AND p.user_id NOT IN (
            SELECT blocked_id FROM blocks WHERE blocker_id = $4
            UNION
            SELECT blocker_id FROM blocks WHERE blocked_id = $4
        )
        AND p.id NOT IN (
            SELECT target_id FROM match_actions WHERE actor_id = $3
        )
        AND ST_DWithin(
            p.location, 
            ST_MakePoint($1, $2)::geography, 
            $5  -- raio em metros
        )
        AND ($6::profile_type IS NULL OR p.type = $6)
        AND ($7::text[] IS NULL OR p.genres && $7)    -- Overlap de gêneros
        AND ($8::text IS NULL OR p.intent = $8)
    ORDER BY 
        ST_Distance(p.location, ST_MakePoint($1, $2)::geography) ASC
    LIMIT $9
    OFFSET $10
`
5. Redis — Uso Estratégico
text

┌─────────────────────────────────────────────┐
│                REDIS USAGE                   │
├─────────────────────────────────────────────┤
│                                              │
│  🔐 Sessions & Tokens                       │
│     key: "session:{user_id}"                │
│     TTL: 7 days                              │
│                                              │
│  👤 Presence (Online/Offline)               │
│     key: "presence:{user_id}"               │
│     value: "{last_seen, status}"            │
│     TTL: 5 minutes (heartbeat)              │
│                                              │
│  🔄 Rate Limiting                           │
│     key: "ratelimit:{ip}:{endpoint}"        │
│     value: counter                           │
│     TTL: 1 minute                            │
│                                              │
│  💖 Match Queue (async processing)          │
│     STREAM: "matchpoint:actions"            │
│     → Consumer Group para processar matches │
│                                              │
│  📍 Geolocation Cache                       │
│     GEOADD "geo:profiles" lng lat id        │
│     → Cache quente para busca por raio      │
│                                              │
│  🔔 Notification Queue                      │
│     LIST: "notifications:pending"           │
│                                              │
│  📊 Counters                                │
│     key: "profile:{id}:views"               │
│     key: "profile:{id}:likes"               │
│                                              │
└─────────────────────────────────────────────┘
6. Elasticsearch — Busca
JSON

// Index mapping para profiles
{
  "settings": {
    "analysis": {
      "analyzer": {
        "brazilian_custom": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "brazilian_stem",
            "asciifolding"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "display_name": { 
        "type": "text", 
        "analyzer": "brazilian_custom",
        "fields": {
          "suggest": {
            "type": "completion"
          }
        }
      },
      "type": { "type": "keyword" },
      "genres": { "type": "keyword" },
      "instruments": { "type": "keyword" },
      "roles": { "type": "keyword" },
      "city": { "type": "keyword" },
      "state": { "type": "keyword" },
      "bio": { 
        "type": "text", 
        "analyzer": "brazilian_custom" 
      },
      "location": { "type": "geo_point" },
      "intent": { "type": "keyword" },
      "verified": { "type": "boolean" },
      "created_at": { "type": "date" }
    }
  }
}
Alternativa mais leve: Meilisearch — mais simples de operar, boa busca fuzzy, mas menos features geoespaciais. Para MVP pode ser melhor.

7. Infraestrutura & Deploy
Opção A: AWS (Produção Escalável)
text

┌────────────────────────────────────────────────────────────────┐
│                         AWS Architecture                        │
│                                                                  │
│  ┌──────────┐    ┌───────────┐    ┌──────────────────────┐     │
│  │CloudFront│───▶│   ALB     │───▶│   ECS Fargate        │     │
│  │  (CDN)   │    │           │    │  ┌────┐ ┌────┐       │     │
│  └──────────┘    └───────────┘    │  │ Go │ │ Go │ (x3)  │     │
│                                    │  │API │ │API │        │     │
│  ┌──────────┐                     │  └────┘ └────┘       │     │
│  │   S3     │                     │  ┌──────┐ ┌──────┐   │     │
│  │ (media)  │                     │  │Chat  │ │Chat  │   │     │
│  └──────────┘                     │  │Node  │ │Node  │   │     │
│                                    │  └──────┘ └──────┘   │     │
│                                    └──────────────────────┘     │
│                                                                  │
│  ┌───────────────┐  ┌────────────┐  ┌──────────────────┐       │
│  │ RDS PostgreSQL│  │ElastiCache │  │ OpenSearch       │       │
│  │ (Multi-AZ)    │  │ (Redis)    │  │ (Elasticsearch)  │       │
│  │ + PostGIS     │  │ Cluster    │  │                  │       │
│  └───────────────┘  └────────────┘  └──────────────────┘       │
│                                                                  │
│  ┌───────────────┐  ┌────────────┐                              │
│  │ SQS / SNS     │  │ CloudWatch │                              │
│  │ (queues)      │  │ (logs/mon) │                              │
│  └───────────────┘  └────────────┘                              │
└────────────────────────────────────────────────────────────────┘
Opção B: Custo Otimizado (MVP / Seed Stage) 🇧🇷
text

┌──────────────────────────────────────────────────────────┐
│                   MVP Architecture                        │
│                                                            │
│  ┌───────────┐                                            │
│  │CloudFlare │  CDN + DDoS + DNS                          │
│  │  (free)   │                                            │
│  └─────┬─────┘                                            │
│        │                                                   │
│  ┌─────▼──────────────────────────────────────┐           │
│  │         VPS (Hetzner / DigitalOcean)       │           │
│  │         ~$40-80/mês                         │           │
│  │                                             │           │
│  │  ┌─────────────────────────────────────┐   │           │
│  │  │         Docker Compose              │   │           │
│  │  │                                     │   │           │
│  │  │  ┌────────┐  ┌──────────────────┐  │   │           │
│  │  │  │  Nginx │  │  Go API (x1)     │  │   │           │
│  │  │  │  Proxy │  │                  │  │   │           │
│  │  │  └────────┘  └──────────────────┘  │   │           │
│  │  │              ┌──────────────────┐   │   │           │
│  │  │              │  Chat Node (x1)  │   │   │           │
│  │  │              └──────────────────┘   │   │           │
│  │  │  ┌───────────┐  ┌──────────────┐   │   │           │
│  │  │  │PostgreSQL │  │    Redis     │   │   │           │
│  │  │  │ + PostGIS │  │              │   │   │           │
│  │  │  └───────────┘  └──────────────┘   │   │           │
│  │  │  ┌────────────┐                     │   │           │
│  │  │  │Meilisearch │  (em vez de ES)    │   │           │
│  │  │  └────────────┘                     │   │           │
│  │  └─────────────────────────────────────┘   │           │
│  └────────────────────────────────────────────┘           │
│                                                            │
│  ┌───────────────┐                                        │
│  │ Cloudflare R2 │  Object Storage (S3-compatible)       │
│  │ (media files) │  Egress gratuito!                     │
│  └───────────────┘                                        │
│                                                            │
│  ┌───────────────┐                                        │
│  │   Firebase    │  Push Notifications + Crashlytics     │
│  │   (free tier) │                                        │
│  └───────────────┘                                        │
└──────────────────────────────────────────────────────────┘

Custo estimado MVP:
  Hetzner CPX31 (4vCPU, 8GB): ~€15/mês
  OU DigitalOcean: ~$48/mês
  Cloudflare R2: ~$0 (até 10GB free)
  Firebase: $0 (free tier)
  Domínio: ~R$40/ano
  ─────────────────────
  TOTAL: ~R$150-300/mês
Docker Compose (MVP)
YAML

# docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - SEARCH_HOST=meilisearch
      - S3_ENDPOINT=https://xxx.r2.cloudflarestorage.com
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M

  chat:
    build:
      context: ./chat-service
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  postgres:
    image: postgis/postgis:16-3.4
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backend/pkg/postgres/migrations:/docker-entrypoint-initdb.d
    environment:
      POSTGRES_DB: mube
      POSTGRES_USER: mube
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mube"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
    restart: unless-stopped

  meilisearch:
    image: getmeili/meilisearch:v1.7
    volumes:
      - meilidata:/meili_data
    environment:
      MEILI_MASTER_KEY: ${MEILI_KEY}
      MEILI_ENV: production
    ports:
      - "7700:7700"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/certs:/etc/nginx/certs
    depends_on:
      - api
      - chat
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:
  meilidata:
8. CI/CD
YAML

# .github/workflows/deploy.yml
name: Build & Deploy

on:
  push:
    branches: [main]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env:
          POSTGRES_DB: mube_test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
      redis:
        image: redis:7-alpine
        ports: ['6379:6379']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: |
          cd backend
          go test ./... -v -race -coverprofile=coverage.out
      - uses: codecov/codecov-action@v4

  test-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: |
          cd app
          flutter pub get
          flutter analyze
          flutter test --coverage

  build-and-deploy:
    needs: [test-backend, test-flutter]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Build Go binary
      - run: |
          cd backend
          CGO_ENABLED=0 GOOS=linux go build -o mube-api ./cmd/api
          
      # Build Docker images
      - uses: docker/build-push-action@v5
        with:
          context: ./backend
          push: true
          tags: ghcr.io/mube/api:${{ github.sha }}
          
      # Deploy to server
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: deploy
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/mube
            docker compose pull
            docker compose up -d --remove-orphans
            
  build-mobile:
    needs: [test-flutter]
    runs-on: macos-latest          # Necessário para iOS
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      # Android
      - run: |
          cd app
          flutter build appbundle --release
          
      # iOS
      - run: |
          cd app
          flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
9. Algoritmo de Matching (MatchPoint Scorer)
Go

// matchpoint/scorer.go
package matchpoint

type MatchScore struct {
    ProfileID    string
    TotalScore   float64
    Breakdown    ScoreBreakdown
}

type ScoreBreakdown struct {
    GenreScore      float64 // 0-30 points
    DistanceScore   float64 // 0-25 points
    IntentScore     float64 // 0-20 points
    RoleCompatScore float64 // 0-15 points
    ActivityScore   float64 // 0-10 points
}

func (s *MatchService) ScoreCandidate(
    seeker Profile, 
    candidate Profile, 
    distanceMeters float64,
) MatchScore {
    var breakdown ScoreBreakdown

    // 1. Genre Overlap (30% weight)
    // Jaccard similarity
    commonGenres := intersect(seeker.Genres, candidate.Genres)
    allGenres := union(seeker.Genres, candidate.Genres)
    if len(allGenres) > 0 {
        breakdown.GenreScore = (float64(len(commonGenres)) / float64(len(allGenres))) * 30
    }

    // 2. Distance (25% weight) — closer = better
    // 0-5km = 25pts, 5-15km = 20pts, 15-30km = 15pts, 30-50km = 10pts, 50km+ = 5pts
    switch {
    case distanceMeters <= 5000:
        breakdown.DistanceScore = 25
    case distanceMeters <= 15000:
        breakdown.DistanceScore = 20
    case distanceMeters <= 30000:
        breakdown.DistanceScore = 15
    case distanceMeters <= 50000:
        breakdown.DistanceScore = 10
    default:
        breakdown.DistanceScore = 5
    }

    // 3. Intent compatibility (20% weight)
    if seeker.Intent == candidate.Intent {
        breakdown.IntentScore = 20
    } else if seeker.Intent == "both" || candidate.Intent == "both" {
        breakdown.IntentScore = 15
    } else {
        breakdown.IntentScore = 5
    }

    // 4. Role Compatibility (15% weight)
    // Band looking for drummer + Professional is drummer = high score
    breakdown.RoleCompatScore = s.calculateRoleCompat(seeker, candidate) * 15

    // 5. Activity Score (10% weight)
    // Based on last_seen_at — active users score higher
    daysSinceActive := time.Since(candidate.LastSeenAt).Hours() / 24
    switch {
    case daysSinceActive <= 1:
        breakdown.ActivityScore = 10
    case daysSinceActive <= 7:
        breakdown.ActivityScore = 7
    case daysSinceActive <= 30:
        breakdown.ActivityScore = 4
    default:
        breakdown.ActivityScore = 1
    }

    total := breakdown.GenreScore +
        breakdown.DistanceScore +
        breakdown.IntentScore +
        breakdown.RoleCompatScore +
        breakdown.ActivityScore

    return MatchScore{
        ProfileID:  candidate.ID,
        TotalScore: total,
        Breakdown:  breakdown,
    }
}
10. Observabilidade
text

┌────────────────────────────────────────────────────┐
│               Observability Stack                    │
│                                                      │
│  Logs:     Zerolog (Go) → Loki → Grafana            │
│  Metrics:  Prometheus → Grafana                      │
│  Traces:   OpenTelemetry → Jaeger                    │
│  Errors:   Sentry (backend + Flutter)                │
│  Crashes:  Firebase Crashlytics (mobile)             │
│  APM:      Grafana dashboards customizados           │
│                                                      │
│  MVP simplificado:                                   │
│  - Sentry (errors, ambos)                            │
│  - Firebase Crashlytics (mobile)                     │
│  - CloudWatch ou Grafana Cloud free tier             │
└────────────────────────────────────────────────────┘
11. Segurança
Go

// Checklist implementado no backend:

// 1. Rate Limiting
middleware.RateLimit(100, time.Minute)  // 100 req/min por IP

// 2. Input Validation
validator.New().Struct(request)         // Validação em todas as entradas

// 3. SQL Injection Prevention
sqlx.Get(db, &user, query, param)      // Prepared statements sempre

// 4. JWT com rotação
AccessToken:  15 min expiry
RefreshToken: 7 days expiry, rotação a cada uso

// 5. Password Hashing
bcrypt.GenerateFromPassword(password, 12)

// 6. CORS configurado
AllowOrigins: []string{"https://mube.app"}

// 7. Headers de segurança
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000

// 8. Upload seguro
- Validação de MIME type
- Limite de tamanho (10MB fotos, 100MB vídeos)
- Scan antivírus (ClamAV em produção)
- Nomes randomizados (UUID)

// 9. Dados sensíveis
- Nunca loga senhas ou tokens
- PII encriptado em repouso
- LGPD compliance (direito ao esquecimento)
12. Resumo das Decisões
Camada	Tecnologia	Justificativa
Mobile	Flutter 3.22+ (Dart)	Cross-platform, performance, ecossistema
State Management	flutter_bloc	Previsível, testável, padrão da comunidade
Navegação	GoRouter	Deep linking, guards, type-safe
Backend Core	Go 1.22 (Echo)	Performance, baixo consumo, deploys leves
Chat Service	Node.js + Socket.io	Ecossistema WS maduro, Redis adapter
Database	PostgreSQL 16 + PostGIS	Relacional + geoespacial nativo
Cache	Redis 7	Sessions, presence, pub/sub, geo cache
Search	Meilisearch (MVP) → Elasticsearch (scale)	Busca fuzzy, fácil operação
Storage	Cloudflare R2	S3-compatible, egress grátis
CDN	CloudFlare	Performance, DDoS, SSL grátis
Push	Firebase Cloud Messaging	Padrão mobile, free
CI/CD	GitHub Actions	Integrado ao repo, gratuito para open source
Monitoring	Sentry + Firebase Crashlytics	Errors + crashes mobile
Infra MVP	Hetzner/DO + Docker Compose	Custo baixo, simples
Infra Scale	AWS ECS Fargate + RDS	Auto-scaling, managed services
Evolução planejada
text

Fase 1 (MVP, 0-10k users):
  └── Monolito Go + Docker Compose em VPS
      └── ~R$200/mês

Fase 2 (Growth, 10k-100k users):
  └── Migra para AWS ECS + RDS + ElastiCache
  └── Separa Chat Service
  └── Adiciona Elasticsearch
      └── ~R$2.000-5.000/mês

Fase 3 (Scale, 100k+ users):
  └── Kubernetes (EKS)
  └── Event-driven (SQS/SNS)
  └── Read replicas PostgreSQL
  └── Redis Cluster
  └── CDN para mídia global
      └── ~R$10.000+/mês
Essa arquitetura permite começar enxuto (~R$200/mês) e escalar progressivamente sem reescritas. O Go garante que um único servidor aguenta muito tráfego antes de precisar escalar horizontalmente, e o Flutter te dá iOS + Android com um time só.




----




certo, eu usei o firebase, olha o README do meu app

Mube - Conectando Músicos
Aplicativo mobile para conectar músicos, bandas, estúdios e contratantes no Brasil.

📱 Sobre o Projeto
O Mube é uma plataforma que facilita a conexão entre profissionais da música. Nossa missão é criar oportunidades para músicos encontrarem bandas, estúdios disponibilizarem seus serviços e contratantes descobrirem talentos.

Funcionalidades Principais
🔐 Autenticação: Login e cadastro com email/senha
👤 Perfis: Criação de perfis para músicos, bandas, estúdios e contratantes
🔍 Busca: Encontre profissionais por localização, gênero musical, instrumentos e mais
💖 MatchPoint: Sistema de match para conectar músicos compatíveis
💬 Chat: Conversas em tempo real entre usuários
⭐ Favoritos: Salve perfis favoritos para acesso rápido
🔔 Notificações: Push notifications para matches e mensagens
🎨 Design System: Interface consistente e moderna com tema dark
🚀 Tecnologias
Framework: Flutter 3.8+
Linguagem: Dart
Backend: Firebase (Firestore, Auth, Storage, Messaging)
State Management: Riverpod
Navegação: GoRouter
Arquitetura: Clean Architecture
📁 Estrutura do Projeto
text

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
🛠️ Configuração do Ambiente
Pré-requisitos
Flutter SDK >= 3.8.0
Dart SDK >= 3.8.0
Android Studio / Xcode (para emuladores)
Conta Firebase configurada
Instalação
Clone o repositório:
Bash

git clone https://github.com/seu-usuario/mube.git
cd mube
Instale as dependências:
Bash

flutter pub get
Configure o Firebase:

Adicione o google-services.json em android/app/
Adicione o GoogleService-Info.plist em ios/Runner/
Configure as API Keys (opcional para desenvolvimento):

Bash

# Crie o arquivo .vscode/launch.json com as chaves:
# GOOGLE_VISION_API_KEY
# GOOGLE_MAPS_API_KEY
Execute o app:
Bash

flutter run
📦 Build de Release
Android
Bash

# APK
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle --release
iOS
Bash

flutter build ios --release
Veja o BUILD_GUIDE.md para instruções detalhadas.

🧪 Testes
Bash

# Rodar todos os testes
flutter test

# Rodar testes específicos
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
📝 Convenções de Código
Lint: flutter_lints configurado
Formatação: dart format
Const constructors: Sempre que possível para melhor performance
Imports: Organizados em ordem alfabética
🌐 Internacionalização
O app suporta:

🇧🇷 Português (Brasil) - Padrão
🇺🇸 Inglês
📄 Licença
Este projeto é privado e de propriedade da Mube.

🤝 Contribuição
Para contribuir com o projeto:

Crie uma branch para sua feature (git checkout -b feature/nova-feature)
Commit suas mudanças (git commit -m 'Adiciona nova feature')
Push para a branch (git push origin feature/nova-feature)
Abra um Pull Request
📞 Suporte
Para suporte ou dúvidas, entre em contato através do app ou pelo email: suporte@mube.app

Versão: 1.0.0+1
Última atualização: Fevereiro 2026

MubeApp Architecture Documentation
Overview
MubeApp é um aplicativo Flutter que conecta músicos, bandas e estúdios. Este documento descreve a arquitetura técnica, padrões de código e decisões de design.

Stack Tecnológica
Framework & Linguagem
Flutter: 3.32+ (SDK mínimo)
Dart: 3.8+ (null-safety obrigatório)
Backend & Infraestrutura
Firebase Core: Autenticação e infraestrutura
Cloud Firestore: Banco de dados NoSQL
Firebase Storage: Armazenamento de mídia
Firebase Cloud Messaging: Push notifications
Firebase Analytics: Métricas e eventos
Firebase Crashlytics: Monitoramento de erros
Firebase Remote Config: Feature flags
State Management
Riverpod 3.x: Gerenciamento de estado reativo
Riverpod Generator: Geração automática de providers
Navegação
Go Router: Navegação declarativa com deep linking
Geração de Código
Freezed: Classes imutáveis e union types
JSON Serializable: Serialização/deserialização JSON
Build Runner: Automação de geração de código
UI & Design
Material Design 3: Componentes nativos do Flutter
Custom Theme: Design System próprio
Shimmer: Animações de loading
Cached Network Image: Cache de imagens
Programação Funcional
FPDart: Tipos funcionais (Either, Option, etc)
Arquitetura em Camadas
O projeto segue uma arquitetura Feature-First Layered Architecture:

text

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
Padrões de Código
1. Nomenclatura
Arquivos
text

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
Classes
dart

// Controllers
class FeedController extends StateNotifier<FeedState>

// Repositories  
class FeedRepository {

// Data Sources
class FeedRemoteDataSource {

// Models (Freezed)
@freezed
class FeedItem with _$FeedItem {
2. Estrutura de Features
Cada feature segue a estrutura:

text

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
3. Gerenciamento de Estado (Riverpod)
Controller Pattern
dart

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
Consumo no Widget
dart

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
4. Tratamento de Erros
Usamos Either (FPDart) para tratamento funcional de erros:

dart

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
5. Navegação
Usamos Go Router com rotas tipadas:

dart

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
Design System
Tokens
Cores
dart

AppColors.background       // Fundo principal
AppColors.surface          // Cards e containers
AppColors.brandPrimary     // Cor da marca
AppColors.textPrimary      // Texto principal
AppColors.textSecondary    // Texto secundário
Espaçamento
dart

AppSpacing.xs              // 4
AppSpacing.sm              // 8
AppSpacing.md              // 16
AppSpacing.lg              // 24
AppSpacing.xl              // 32
Tipografia
dart

AppTextStyles.heading1     // Títulos grandes
AppTextStyles.heading2     // Títulos médios
AppTextStyles.body         // Texto corrido
AppTextStyles.caption      // Legendas
Componentes
Botões
dart

AppButton.primary(
  onPressed: () {},
  child: Text('Entrar'),
)

AppButton.secondary(
  onPressed: () {},
  child: Text('Cancelar'),
)
Inputs
dart

AppTextField(
  label: 'Email',
  hint: 'seu@email.com',
  validator: (value) => validateEmail(value),
)
Loading
dart

AppShimmer.box(width: 200, height: 100)
AppShimmer.circle(size: 48)
Integração com Firebase
Autenticação
dart

// Login
await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Auth State
final authState = ref.watch(authStateChangesProvider);
Firestore
dart

// Stream de dados
final usersStream = FirebaseFirestore.instance
  .collection('users')
  .snapshots();

// Query única
final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get();
Storage
dart

// Upload
final ref = FirebaseStorage.instance
  .ref()
  .child('images/$userId/profile.jpg');
await ref.putFile(imageFile);

// Download URL
final url = await ref.getDownloadURL();
Testes
Estrutura de Testes
text

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
Exemplo de Teste Unitário
dart

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
Exemplo de Teste de Widget
dart

testWidgets('should show login button', (tester) async {
  await tester.pumpApp(const LoginScreen());
  
  expect(find.text('Entrar'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
Performance
Otimizações Implementadas
Paginação: Feed usa cursor-based pagination
Cache de Imagens: CachedNetworkImage com limites de memória
Shimmer: Placeholders animados durante carregamento
Lazy Loading: ListView.builder para listas grandes
Riverpod keepAlive: Providers que persistem estado
Geohash: Busca por localização otimizada
Boas Práticas
✅ Usar const constructors quando possível
✅ Evitar rebuilds desnecessários com Consumer específicos
✅ Usar select do Riverpod para observar apenas campos específicos
✅ Limitar tamanho de imagens antes do upload
✅ Usar paginação para coleções grandes
Segurança
Firestore Rules
✅ Todas as operações exigem autenticação
✅ Validação de ownership em todos os recursos
✅ Updates parciais validados
✅ Least privilege principle
Dados Sensíveis
❌ Nunca logar senhas ou tokens
✅ Usar Firebase App Check
✅ Validar dados no cliente e servidor
Deploy
Build
Bash

# Debug
flutter run

# Profile
flutter run --profile

# Release
flutter build apk --release          # Android
flutter build ios --release          # iOS
CI/CD
O projeto usa GitHub Actions para:

✅ Análise estática (flutter analyze)
✅ Testes unitários
✅ Build de verificação
Contribuindo
Antes de Commit
Rodar flutter analyze - deve ter 0 erros
Rodar flutter test - todos os testes devem passar
Verificar formatação com dart format
Code Review Checklist
 Código segue os padrões de nomenclatura
 Tratamento de erros adequado
 Testes inclusos
 Documentação atualizada
 Não há prints (usar AppLogger)
Recursos
Documentação
Flutter Documentation
Riverpod Documentation
Firebase Documentation
Tools
Widgetbook - Galeria de componentes
Flutter Inspector
Troubleshooting
Problemas Comuns
Erro: "Target of URI doesn't exist"

Bash

flutter pub run build_runner build --delete-conflicting-outputs
Erro: "No tests match"
Verificar se o arquivo termina com _test.dart

Erro: "Firebase not configured"
Verificar se google-services.json e GoogleService-Info.plist estão configurados

Contato
Para dúvidas sobre a arquitetura:

Criar issue no GitHub
Consultar documentação em /docs
dito isso, o que voce achou que eu fiz errado, fiz algo errado?
teria algo pra melhorar antes de lançar pra teste, tendo em vista que o mvp está 90% pronto






----




claude-opus-4-6-thinking

Thought for 27 seconds

The user has built a Flutter app called Mube using Firebase as the backend, Riverpod for state management, and GoRouter for navigation. They're asking me to review their architecture and identify what they did wrong or could improve before launching for testing, given that their MVP is 90% ready.

Let me analyze their choices carefully:

Firebase as backend - They chose Firebase (Firestore, Auth, Storage, FCM) vs what I recommended (Go + PostgreSQL)

Riverpod vs what I recommended (flutter_bloc)

Freezed for immutable classes

FPDart for functional error handling

Clean Architecture with feature-first approach

Now I need to distinguish between what's genuinely problematic versus what's simply different from my preferences, and focus on what actually needs fixing before they launch for testing. They've made solid architectural decisions overall—feature-first structure, proper separation of concerns, design tokens, Either-based error handling, and immutable models are all sound choices. The real question is whether there are any actual gaps or risks in their implementation that could cause problems during testing.

The main concern is Firestore's limitations for a matching app with complex filtering across multiple dimensions like location, genres, instruments, and user intent—it lacks native joins, requires composite indexes for every query combination, has weak geospatial support, and the read costs could spiral as the matching algorithm scales. Beyond that, there's no clear offline-first strategy mentioned, and while they reference Firebase Security Rules, there's no visibility into whether they're actually secure. The Riverpod choice is fine and arguably more modern than BLoC, so that's not a real issue.

For the features they're building, Firestore's real gaps show up in search (they'd need Algolia or Typesense for full-text), geospatial matching (PostGIS would be vastly superior for proximity queries with multiple filters), and the lack of Cloud Functions to handle match detection, push notifications, data denormalization, moderation, and rate limiting. Chat in Firestore actually works well for real-time, so that's a good fit, but the heavy denormalization required elsewhere in Firestore adds complexity and maintenance burden.

The pricing model is the real concern—per-document read/write costs will compound quickly when they're reading many profiles for feeds, scoring candidates for matching, and running searches across collections. Firebase is a solid MVP choice for speed and no server management, but these architectural issues need addressing before they scale beyond testing.

I should organize feedback into what's genuinely risky versus what's acceptable for MVP, then give them a practical pre-launch checklist since they're ready to test.

Review Honesta da Arquitetura do Mube
Primeiro: o que você fez BEM
Antes de criticar, reconhecimento justo — tem muita decisão sólida aqui:

✅ Feature-first architecture — organização excelente
✅ Riverpod — escolha perfeitamente válida (eu sugeri BLoC, mas Riverpod é igualmente profissional)
✅ Freezed + FPDart (Either) — tratamento de erro maduro, poucos devs Flutter fazem isso
✅ Design System com tokens — isso separa amador de profissional
✅ GoRouter — acertou
✅ Internacionalização desde o início — maioria deixa pra depois e sofre
✅ Shimmer/Loading states — UX profissional
✅ Separação data/domain/presentation por feature
Você NÃO fez errado em escolher Firebase para o MVP. É uma decisão pragmática e válida para ir rápido ao mercado. Mas tem problemas reais que você precisa conhecer.

🔴 Problemas CRÍTICOS (resolver antes do teste)
1. MatchPoint no Firestore — Bomba de Custo e Performance
Esse é o maior problema da sua arquitetura. O MatchPoint é um sistema tipo Tinder — precisa fazer queries como:

"Me traga perfis num raio de 30km, que toquem rock ou blues, que sejam bateristas, que tenham intent 'serious', que eu ainda não dei like/pass, ordenados por compatibilidade"

No Firestore isso é quase impossível:

dart

// O que você QUER fazer:
FirebaseFirestore.instance
  .collection('profiles')
  .where('genres', arrayContainsAny: ['rock', 'blues'])  // ✅ ok
  .where('instruments', arrayContainsAny: ['bateria'])     // ❌ ERRO: 2 arrayContainsAny
  .where('intent', isEqualTo: 'serious')                   // ❌ ERRO: precisa composite index
  .orderBy('distance')                                      // ❌ ERRO: Firestore NÃO tem geo-query nativo
  .where('id', whereNotIn: alreadySwipedIds)               // ❌ ERRO: whereNotIn max 10 itens
  .limit(20);

// O que você ACABA fazendo:
// Buscar TODOS os perfis → filtrar no client → $$$$$
Problemas concretos:

Problema	Impacto
Sem arrayContainsAny duplo	Não filtra gênero + instrumento na mesma query
whereNotIn limitado a 10 valores	Depois de 10 swipes, a exclusão quebra
Sem ordenação por distância	Precisa de geohash workaround impreciso
Cada perfil lido = 1 read cobrado	MatchPoint com 1000 candidatos = 1000 reads POR sessão
Sem JOIN	Pra saber se já deu like, precisa de query separada
Solução pragmática para o teste (sem reescrever):

dart

// Criar uma Cloud Function que faz o "matching" server-side
// e salva os resultados pré-computados

// Cloud Function (Node.js/TypeScript)
exports.computeMatchCandidates = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    // Para cada usuário ativo:
    // 1. Busca candidatos por geohash (região aproximada)
    // 2. Filtra por gêneros, instrumentos, intent
    // 3. Remove já swipados
    // 4. Calcula score
    // 5. Salva top 50 em /users/{id}/matchCandidates
  });

// No app, você só lê os candidatos pré-computados:
FirebaseFirestore.instance
  .collection('users')
  .doc(myId)
  .collection('matchCandidates')
  .orderBy('score', descending: true)
  .limit(20)
  .get(); // Apenas 20 reads!
2. Cadê as Cloud Functions?
No seu README, não há nenhuma menção a Cloud Functions. Para um app social, isso é crítico. Sem server-side logic, você está fazendo coisas no client que jamais deveriam estar lá:

text

❌ Coisas que NÃO devem rodar no client:

1. Detecção de match mútuo
   → Usuário A dá like em B, depois B dá like em A
   → Quem cria o match? Se ambos clients tentam, race condition.
   
2. Envio de push notifications
   → Client não deve ter acesso ao FCM token de outros usuários
   
3. Contagem de likes/views
   → Client pode manipular
   
4. Criação de conversa após match
   → Precisa ser atômico
   
5. Denúncia/moderação
   → Client não deve poder alterar status de outro usuário
O que você precisa ter em Cloud Functions (mínimo para teste):

TypeScript

// functions/src/index.ts

// 1. Detectar match mútuo
export const onLikeCreated = functions.firestore
  .document('matchActions/{actionId}')
  .onCreate(async (snap, context) => {
    const { actorId, targetId, action } = snap.data();
    
    if (action !== 'like') return;
    
    // Verificar se o outro já deu like
    const reciprocal = await admin.firestore()
      .collection('matchActions')
      .where('actorId', '==', targetId)
      .where('targetId', '==', actorId)
      .where('action', '==', 'like')
      .get();
    
    if (!reciprocal.empty) {
      // MATCH! Criar em batch
      const batch = admin.firestore().batch();
      
      // Criar match
      const matchRef = admin.firestore().collection('matches').doc();
      batch.set(matchRef, {
        profileA: actorId,
        profileB: targetId,
        matchedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Criar conversa
      const convRef = admin.firestore().collection('conversations').doc();
      batch.set(convRef, {
        matchId: matchRef.id,
        participants: [actorId, targetId],
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
      // Push notification para ambos
      await sendMatchNotification(actorId, targetId);
    }
  });

// 2. Push notification em nova mensagem  
export const onMessageCreated = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { convId } = context.params;
    
    // Atualizar lastMessageAt na conversa
    await admin.firestore()
      .collection('conversations')
      .doc(convId)
      .update({ 
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessagePreview: message.content.substring(0, 100),
      });
    
    // Enviar push para o receptor
    await sendMessageNotification(message.senderId, convId);
  });

// 3. Limpar dados ao deletar conta (LGPD)
export const onUserDeleted = functions.auth
  .user()
  .onDelete(async (user) => {
    // Deletar todos os dados do usuário
    await deleteUserData(user.uid);
  });
3. Firestore Security Rules — Mostrou que Existem, Mas Não Mostrou Nada
Você mencionou "Firestore Rules ✅" mas não mostrou as rules. Para teste com usuários reais, rules fracas = desastre de segurança.

Rules mínimas que você PRECISA ter:

JavaScript

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Funções auxiliares
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isNotBlocked(targetUserId) {
      return !exists(/databases/$(database)/documents/blocks/$(request.auth.uid + '_' + targetUserId));
    }
    
    // USERS
    match /users/{userId} {
      allow read: if isAuthenticated() && isNotBlocked(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
      
      // Nunca expor estes campos em reads
      // (precisa filtrar no client OU usar sub-collection privada)
    }
    
    // PROFILES  
    match /profiles/{profileId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
        && request.resource.data.userId == request.auth.uid;
      
      // Validar campos obrigatórios
      allow create: if isAuthenticated()
        && request.resource.data.keys().hasAll(['displayName', 'type', 'userId'])
        && request.resource.data.type in ['profissional', 'banda', 'estudio', 'contratante']
        && request.resource.data.displayName.size() <= 100;
    }
    
    // MATCH ACTIONS
    match /matchActions/{actionId} {
      allow read: if isAuthenticated() 
        && (resource.data.actorId == request.auth.uid 
            || resource.data.targetId == request.auth.uid);
      allow create: if isAuthenticated() 
        && request.resource.data.actorId == request.auth.uid
        && request.resource.data.action in ['like', 'pass', 'superlike'];
      allow update, delete: if false; // Imutável
    }
    
    // CONVERSATIONS
    match /conversations/{convId} {
      allow read: if isAuthenticated() 
        && request.auth.uid in resource.data.participants;
      allow create: if false; // Só Cloud Function cria
      
      match /messages/{msgId} {
        allow read: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
        allow create: if isAuthenticated()
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.content.size() <= 5000;
        allow update, delete: if false;
      }
    }
    
    // BLOCKS
    match /blocks/{blockId} {
      allow read: if isAuthenticated() 
        && resource.data.blockerId == request.auth.uid;
      allow create: if isAuthenticated()
        && request.resource.data.blockerId == request.auth.uid;
      allow delete: if isAuthenticated()
        && resource.data.blockerId == request.auth.uid;
    }
    
    // Negar tudo que não foi explicitamente permitido
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
4. Busca/Search — Como Está Implementado?
Firestore não tem full-text search. Se seu Search está fazendo:

dart

// ❌ Isso NÃO funciona para busca real
.where('displayName', isGreaterThanOrEqualTo: searchTerm)
.where('displayName', isLessThanOrEqualTo: searchTerm + '\uf8ff')
Isso só faz prefix match (busca "Mar" encontra "Maria" mas não encontra "Ana Maria").

Soluções para o MVP:

text

Opção 1: Algolia (Firebase Extension oficial)
  ✅ Instala em 5 minutos
  ✅ Busca fuzzy excelente
  ❌ Pago ($1/1000 requests — ok para teste)

Opção 2: Meilisearch no Cloud Run
  ✅ Open source
  ✅ Excelente para português
  ❌ Precisa manter sincronizado com Firestore

Opção 3: Campo de search keywords (gambiarra aceitável para MVP)
  // No Cloud Function, ao salvar perfil:
  const keywords = generateSearchKeywords(profile.displayName);
  // "João Silva" → ["joão", "silva", "jo", "joa", "joão", "si", "sil", "silv", "silva"]
  await doc.update({ searchKeywords: keywords });
  
  // No client:
  .where('searchKeywords', arrayContains: searchTerm.toLowerCase())
🟡 Problemas IMPORTANTES (resolver antes do lançamento público)
5. Firestore Data Modeling — Provavelmente Tem Problemas
No Firestore/NoSQL, a estrutura dos dados define suas queries. Sem ver seu modelo, aposto que tem pelo menos um destes problemas:

text

PROBLEMA COMUM #1: Dados aninhados demais
❌ /users/{id}/profile/media/photos/{photoId}
   → 4 níveis = queries impossíveis

✅ /profiles/{id}         (documento com dados do perfil)
✅ /media/{id}            (collection separada, campo profileId)


PROBLEMA COMUM #2: Falta de denormalização
❌ Conversa que precisa buscar nome/foto do outro participante
   → 1 read da conversa + N reads dos participantes = lento

✅ /conversations/{id}
   {
     participants: ['uid1', 'uid2'],
     participantNames: { 'uid1': 'João', 'uid2': 'Maria' },  // Denormalizado
     participantAvatars: { 'uid1': 'url...', 'uid2': 'url...' },
     lastMessage: 'Bora ensaiar?',
     lastMessageAt: Timestamp
   }


PROBLEMA COMUM #3: Sem campo de ordenação composto
❌ Tentar ordernar feed por relevância sem campo calculado
✅ Campo 'feedScore' pré-calculado por Cloud Function
Recomendação: Me mostra sua estrutura do Firestore que eu reviso.

6. Tratamento de Upload de Mídia
dart

// ❌ O que provavelmente está fazendo:
final ref = FirebaseStorage.instance
  .ref('images/$userId/profile.jpg');
await ref.putFile(imageFile); // Arquivo original, 5MB+

// ✅ O que deveria fazer:
Future<String> uploadProfileImage(File file) async {
  // 1. Comprimir ANTES de enviar
  final compressed = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    '${file.parent.path}/compressed.jpg',
    quality: 80,
    minWidth: 1080,
    minHeight: 1080,
  );
  
  // 2. Validar tamanho
  if (compressed!.lengthSync() > 2 * 1024 * 1024) {
    throw AppException('Imagem muito grande');
  }
  
  // 3. Gerar nome único (evitar cache stale)
  final fileName = '${const Uuid().v4()}.jpg';
  
  // 4. Upload com metadata
  final ref = FirebaseStorage.instance
    .ref('profiles/$userId/photos/$fileName');
  
  await ref.putFile(
    compressed,
    SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    ),
  );
  
  return await ref.getDownloadURL();
}
Storage Rules também:

JavaScript

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profiles/{userId}/photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024  // Max 5MB
        && request.resource.contentType.matches('image/.*');
    }
  }
}
7. Sem Rate Limiting no Client
dart

// ❌ Usuário pode spammar likes
Future<void> onLike(String targetId) async {
  await repository.createLike(targetId); // Sem throttle
}

// ✅ Com proteção
final _likeThrottle = Throttle(duration: const Duration(seconds: 1));
int _likesCount = 0;

Future<void> onLike(String targetId) async {
  if (_likesCount >= 100) {
    throw AppException('Limite diário de likes atingido');
    return;
  }
  
  _likeThrottle.run(() async {
    await repository.createLike(targetId);
    _likesCount++;
  });
}
🟢 Melhorias para DEPOIS do teste (nice to have)
8. Coisas Menores
text

□ Analytics Events — você tem Firebase Analytics, mas está
  rastreando os eventos certos?
  
  Eventos ESSENCIAIS para entender o produto:
  - sign_up (com tipo de perfil)
  - profile_completed
  - matchpoint_swipe (like/pass)
  - match_created
  - message_sent (primeiro msg vs subsequentes)
  - search_performed (com filtros usados)
  
□ Crashlytics — configurar bread crumbs em ações críticas:
  FirebaseCrashlytics.instance.log('User swiped on MatchPoint');
  
□ Remote Config — ter kill switch para features:
  matchpoint_enabled: true/false
  max_daily_likes: 50
  
□ Deep Links — GoRouter suporta, mas está configurado?
  mube.app/profile/xyz → abre direto no perfil
  
□ App Check — mencionou mas está ativo?
  Sem App Check, alguém pode chamar seu Firestore
  direto via REST API
Custo Estimado com Firebase (ATENÇÃO)
text

Cenário: 1.000 usuários teste ativos/dia

Firestore Reads:
  Feed (20 cards × 5 refreshes)         = 100 reads/user
  MatchPoint (50 candidatos × 3 sessões) = 150 reads/user  
  Chat (20 msgs × 5 conversas)           = 100 reads/user
  Profile views                          = 30 reads/user
  ────────────────────────────────────────
  Total: ~380 reads/user/dia
  
  1.000 users × 380 = 380.000 reads/dia
  × 30 dias = 11.4M reads/mês

Firebase Free Tier:     50.000 reads/dia ← ESTOURA no dia 1!
Spark → Blaze:          $0.06/100K reads
  11.4M reads =         ~$6.84/mês ← OK, barato

MAS com 10.000 usuários: ~$68/mês (ainda ok)
Com 100.000 usuários:    ~$684/mês (começa a doer)
Com MatchPoint mal otimizado: 3-5x mais

Storage:
  1.000 users × 6 fotos × 500KB = 3GB ← Free tier cobre

Cloud Functions:
  ~500K invocations/mês ← Free tier cobre (2M free)

TOTAL MVP (1K users): ~$0-10/mês ✅
TOTAL Growth (10K):   ~$50-100/mês ⚠️
TOTAL Scale (100K):   ~$500-2000/mês 🔴 (hora de migrar)
Checklist Pré-Teste
text

CRÍTICO (bloqueia teste):
  □ Cloud Functions para detecção de match
  □ Cloud Functions para push notifications
  □ Firestore Security Rules completas e testadas
  □ Storage Security Rules
  □ MatchPoint com candidatos pré-computados (ou limite de reads)
  □ App Check ativado

IMPORTANTE (pode ir ao teste mas resolve rápido):
  □ Compressão de imagem antes do upload
  □ Rate limiting no client (likes, mensagens)
  □ Tratamento de erro offline (sem internet)
  □ Analytics events nos fluxos principais
  □ Termos de Uso / Política de Privacidade (LGPD!)
  □ Tela de denúncia/report (App Store exige pra apps sociais)

NICE TO HAVE:
  □ Search com Algolia ou keywords
  □ Deep links configurados
  □ Onboarding tutorial
  □ Empty states bonitos em todas as telas
  □ Skeleton loading em TODAS as listas
  □ Teste de performance com Flutter DevTools
Veredicto Final
Firebase para MVP foi a decisão CERTA. Você foi ao mercado mais rápido do que se tivesse montado Go + PostgreSQL. O código Flutter está bem arquitetado.

O problema não é Firebase. É a falta de Cloud Functions e as limitações do Firestore para queries complexas do MatchPoint. Resolve as Cloud Functions e o pré-cálculo de candidatos, e você tem um MVP testável.

Quando chegar a 10-50K usuários, aí sim considere migrar o MatchPoint e Search para um backend próprio (Go/Node + PostgreSQL), mantendo Firebase para Auth e Chat (onde ele brilha).