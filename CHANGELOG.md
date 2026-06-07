# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-07

Two retrieval-scaling mechanisms, the CPU-cache analogy carried through to the index
and eviction layers. As a wiki grows past a few dozen pages, grep-over-everything gets
imprecise; these keep retrieval sharp.

### Added

- **Hub-Index-Routing** — two-stage `query`. Each hub page carries an `### Index` of
  routing lines (`[[page]] -- description #tags`); query reads the cheap index first,
  picks the 3 best pages by description, then reads only those. Full-text grep becomes
  the L3 fallback. `ingest` maintains the routing line for every page (the wiki's page table).
- **LRU-Demote** — new `/wiki prune [--months N]` command. `query` appends every full-page
  read to an append-only `Wiki/Reference/Access-Log`; `prune` evicts pages with no access
  in N months (default 6) from the live index into the hub `### Archive`, marked `archived::`.
  Eviction never deletes, renames, or moves a file — incoming `[[links]]` stay valid and the
  page is still greppable (L3). Re-promotion is automatic on re-hit.
- `openspec/specs/prune.md` — new spec (EARS requirements + BDD scenarios)
- Lint rules 10 (Index Drift) and 11 (Archived-in-Live-Index), both auto-fixable;
  `lint --fix` now backfills missing routing lines into hub indexes
- `status` now reports a hot/cold cache profile (most-queried pages, demote-ready cold pages)
- Access-Log page templates for Logseq and Obsidian; `setup.sh` scaffolds the Access-Log page

### Changed

- Hub page templates (Logseq + Obsidian) now include `### Index` and `### Archive` sections
- `docs/schema-reference.md` — Hub example updated; new "Hub-Index-Routing & LRU-Demote" section
- Specs updated: `query.md` (Phase 0 routing + Phase 1b access logging), `ingest.md`
  (routing-line maintenance), `lint.md` (11 rules), `schema.md` (hub index, `archived::`
  marker, Access-Log page)

### Notes

- Backward compatible. Existing wikis keep working; run `/wiki lint --fix` once to backfill
  routing lines into hubs that predate this release.
- `archived::` is the canonical demote marker and is valid on any page type. `status:: archived`
  is set additionally only where the type's status enum allows it (Entity).

## [1.1.1] - 2026-04-18

### Added

- README badge row — license, release, stars, top language, last commit
- `docs/faq.md` — 10 questions first-time users actually ask (paid plan, L1/L2 rationale, tool choice, credential safety, wiki growth thresholds)
- `docs/troubleshooting.md` — setup, wiki-app integration, Claude Code integration, and wiki-growth issues with symptom → cause → fix format
- README "Documentation" section linking all five docs pages

### Notes

- Documentation-only release. No code, schema, or command changes.
- Focus: adoption friction. The v1.1.0 feedback pointed at missing onboarding docs, not missing features.

## [1.1.0] - 2026-04-10

### Added

- 7 OpenSpec specifications with 162 EARS requirements and 66 BDD scenarios
  - `ingest.md` — 5-phase source processing pipeline
  - `query.md` — Search, synthesis, write-back, source attribution
  - `lint.md` — 9 health checks with auto-fix rules
  - `schema.md` — Page types, property validation, format rules
  - `config.md` — Configuration loading and error handling
  - `setup.md` — Interactive installer specification
  - `l1-l2-routing.md` — L1/L2 boundary decision logic
- GitHub issue templates (bug report, feature request)
- Pull request template with dual-tool testing checklist
- SECURITY.md with responsible disclosure process
- `.gitignore` for editor and OS files
- CHANGELOG.md

### Fixed

- `setup.sh`: Add prerequisite checks for python3 and git
- `setup.sh`: Add `set -eo pipefail` for stricter error handling
- `setup.sh`: Validate namespace names (letters, numbers, hyphens only)
- `setup.sh`: Skip existing wiki pages instead of silently overwriting
- `setup.sh`: Prompt before overwriting existing `llm-wiki.yml`

## [1.0.0] - 2026-04-07

First stable release.

### Added

- `/wiki ingest` — 5-phase source processing pipeline (URL, file, text)
- `/wiki query` — Search, synthesis, and source attribution
- `/wiki lint` — 9 automated health checks with `--fix` auto-repair
- `/wiki status` — Wiki metrics and health dashboard
- `setup.sh` — Interactive installer for Logseq and Obsidian
- L1/L2 dual-layer cache architecture (CPU cache metaphor)
- Templates for both Logseq (outliner) and Obsidian (flat markdown)
- Schema with 5 page types: Entity, Project, Knowledge, Feedback, Hub
- `config.example.yml` for reference configuration

### Security

- Credential leak detection (lint rule 6) scans for tokens, passwords, secrets
- L1/L2 security boundary: credentials stay in L1 (git-excluded), wiki is git-tracked

[1.2.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MehmetGoekce/llm-wiki/releases/tag/v1.0.0
