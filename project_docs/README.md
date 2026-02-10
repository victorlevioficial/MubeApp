# Project Docs Organization

This folder keeps planning artifacts and historical material.
Current implementation source of truth lives mostly in `docs/` and `lib/`.

## Current Source Of Truth

- Design System: `design-system.md`
- Architecture: `docs/ARCHITECTURE.md`
- Firestore rules spec: `docs/FIRESTORE_RULES.md`
- Runtime security rules: `firestore.rules`
- Legal text shown in app: `lib/src/features/legal/data/legal_content.dart`
- Business rules catalog: `docs/business-rules-catalog.md`

## Folder Map

- `active-plans/`: active technical plans still useful for execution.
- `analysis/`: diagnostics and investigations that can still support refactors.
- `archive/2025-mvp-foundation/`: initial planning batch from Dec/2025.
- `doc-status.md`: per-file status index with replacement references.

## Naming Standard

- Use `kebab-case` for files and folders.
- Use lowercase only.
- Avoid spaces, accents, and parentheses in names.

## Archive Notes

All files versioned as `v1`, `v2`, `v4`, `v5` and created in Dec/2025 were moved to archive.
They are preserved for traceability, but should not be treated as current specs.

## Archived Batch (2025 MVP Foundation)

- `architecture-backend/`
- `design-system/`
- `legal/`
- `product-strategy/`
- `store-listing/`

## Maintenance Rule

When a document becomes superseded:
1. Move it to `archive/<year-or-batch>/<topic>/`.
2. Keep only active docs in `active-plans/` and `analysis/`.
3. Update this file with new source-of-truth paths.
