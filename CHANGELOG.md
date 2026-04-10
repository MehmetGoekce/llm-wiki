# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MehmetGoekce/llm-wiki/releases/tag/v1.0.0
