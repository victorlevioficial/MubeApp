# Project Docs Organization

This folder keeps planning artifacts and historical material.
Current implementation source of truth lives mostly in `docs/` and `lib/`.

## Current Source Of Truth

- Design System: `../reference/design-system-current.md`
- Architecture: `../../ARCHITECTURE.md`
- Firestore rules spec: `../FIRESTORE_RULES.md`
- Runtime security rules: `../../firestore.rules`
- Legal text shown in app: `../../lib/src/features/legal/data/legal_content.dart`
- Business rules catalog: `../business-rules-catalog.md`

## Folder Map

- `../plans/`: active technical plans still useful for execution.
- `../analysis/`: diagnostics and investigations that can still support refactors.
- `subagents-playbook.md`: project-specific subagent profiles and prompt templates for AppMube task delegation.
- `../../.agent/workflows/appmube-package.md`: one-shot workflow shortcut for AppMube delegation.
- `../archive/2025-mvp-foundation/`: initial planning batch from Dec/2025.
- `../archive/2026-reconstruction/`: reverse-engineering and test-coverage snapshots kept only for traceability.
- `status.md`: per-file status index with replacement references.

## Naming Standard

- Use `kebab-case` for files and folders.
- Use lowercase only.
- Avoid spaces, accents, and parentheses in names.

## Archive Notes

All files versioned as `v1`, `v2`, `v4`, `v5` and created in Dec/2025 were moved to archive.
They are preserved for traceability, but should not be treated as current specs.

Some documentation generated during the 2026 reverse-engineering pass was also archived once newer source-of-truth docs became available.

## Archived Batch (2025 MVP Foundation)

- `architecture-backend/`
- `design-system/`
- `legal/`
- `product-strategy/`
- `store-listing/`

## Archived Batch (2026 Reconstruction)

- `../archive/2026-reconstruction/PLAN-app-reconstruction.md`
- `../archive/2026-reconstruction/PRD-reconstructed.md`
- `../archive/2026-reconstruction/TEST_COVERAGE_REPORT.md`

## Maintenance Rule

When a document becomes superseded:
1. Move it to `archive/<year-or-batch>/<topic>/`.
2. Keep only active docs in `plans/`, `analysis/`, `reference/`, `operations/`, or the docs root when they are still current.
3. Update this file with new source-of-truth paths.
