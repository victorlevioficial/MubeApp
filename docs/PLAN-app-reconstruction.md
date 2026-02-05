# PLAN-app-reconstruction.md

> **Goal**: Reverse engineer the existing Mube application codebase to generate a comprehensive "Maximum Documentation" suite. This serves as a foundational specification for a hypothetical rebuild or scaling effort.

## Context
- **Objective**: Analyze the entire codebase (`lib/`, `pubspec.yaml`, assets) to produce the most detailed documentation possible.
- **Scope**: Auth, Profile (all user types), Social Features (MatchPoint, Chat), Media/Gallery, Legal, and Infrastructure.
- **Output**: A collection of specifications (PRD, Technical, Design, Data) that fully describe the app's current state.

## Phase 1: Deep Codebase Analysis (Survey)
**Goal**: Map the entire application structure and extract implicit knowledge.

- [ ] **Structural Mapping**
    - [ ] Map `lib/src/features` directory tree to identify all functional modules.
    - [ ] List all shared components in `lib/src/design_system`.
    - [ ] Catalog all dependencies and their versions from `pubspec.yaml`.
- [ ] **Logic Extraction**
    - [ ] Analyze `AppRouter` (`app_router.dart`) to define the Navigation Graph.
    - [ ] Analyze Riverpod Providers to understand State Management hierarchy.
    - [ ] Analyze Repositories to infer Firestore Data Schema.
    - [ ] Extract validation rules from Form Widgets (e.g., `EditProfileScreen`).

## Phase 2: "Maximum Documentation" Suite Generation
**Goal**: Create specific documentation artifacts based on Phase 1 analysis.

### 2.1 Product & Requirements (The "Rebuild Spec")
- [ ] **Reverse-Engineered PRD (Product Requirement Doc)**
    - [ ] **Feature List**: Exhaustive list of every user-facing feature.
    - [ ] **User Personas**: Details on Professional, Studio, Band, Contractor types.
    - [ ] **User Stories**: "As a [UserType], I can [Action] so that [Benefit]" for all features.

### 2.2 Technical Specification
- [ ] **Architecture Document**
    - [ ] Diagram: Layered Architecture (Presentation -> Controller -> Repository -> Data).
    - [ ] State Management Strategy (Riverpod patterns used).
    - [ ] Error Handling Strategy (Failure types, Functional Programming with `fpdart`).
- [ ] **Data Dictionary**
    - [ ] **Firestore Schema**: Collections (`users`, `matches`, `chats`, etc.) and document structures.
    - [ ] **Flutter Models**: `fromJson`/`toJson` mappings and field types.

### 2.3 UX/UI Documentation
- [ ] **Flow Diagrams (Mermaid)**
    - [ ] Authentication Flow (Login, Register, Recover).
    - [ ] Onboarding & Profile Creation Flow (branching by User Type).
    - [ ] "MatchPoint" Interaction Flow.
- [ ] **Design System Spec**
    - [ ] **Token Map**: Colors (`AppColors`), Typography (`AppTypography`), Spacing.
    - [ ] **Component Library**: List of reusable widgets and their API (e.g., `AppButton`, `AppTextField`).

### 2.4 Business Logic & Rules
- [ ] **Business Rules Catalog**
    - [ ] **Validation Rules**: Regex patterns (Phone, Docs), Required fields per profile type.
    - [ ] **Access Control**: Permissions based on User Type (Free vs Premium/VIP logic if present).
    - [ ] **Complex Logic**: Matching algorithm criteria, specialized form handling.

## Phase 3: Infrastructure & Deployment
- [ ] **Infrastructure Map**
    - [ ] Firebase Services configured (Auth, Firestore, Storage, Analytics, functions).
    - [ ] Native Integration points (Permissions, Info.plist rules, AndroidManifest).
- [ ] **DevOps & CI/CD**
    - [ ] Build flavors/environments.
    - [ ] Deployment checklist (Play Store assets, signing config).

## Execution Strategy
1. **Agent**: `orchestrator` to manage the process.
2. **Specialists**:
    - `documentation-writer`: To draft the prose and detailed descriptions.
    - `mobile-developer`: To parse Dart/Flutter specific logic.
    - `product-manager`: To structure user stories and PRD.
    - `architecture`: To map the technical design.

---
**Status**: Ready to Start
**Next Step**: Run the structural mapping to populate the initial feature list.
