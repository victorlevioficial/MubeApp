# Mube – Project Map (source of truth for the AI)

## Goals
- Keep changes minimal and scoped.
- Respect existing architecture and design system.
- Prefer Riverpod patterns already used.

## Structure (high level)
- lib/src/features: feature modules (onboarding, profile, chat, feed, etc.)
- lib/src/core: core/shared utilities
- lib/src/design_system: UI components and tokens
- firebase: rules / functions / configs (if present)

## Architecture
- State: Riverpod
- UI: custom design system components
- Backend: Firebase (Auth/Firestore/Storage/RTDB if used)

## Coding rules
- Do not add dependencies without justification.
- Always run: flutter format . && flutter analyze
- Never commit secrets (google-services.json, keystores, API keys).
