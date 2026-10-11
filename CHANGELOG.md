# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Documentation and support links in the plugin manifest, shown on the directory listing.
- Privacy section in the README and a privacy link in the plugin manifest.

## [1.7.1] - 2026-10-11

Housekeeping for a listing in Anthropic's plugin directory. No change to the skill or the scripts.

### Added

- Plugin icon in the `.claude-plugin` directory (1024 x 1024 PNG).

### Fixed

- Two spec scenarios showed a made-up API key as sample input (`openspec/specs/lint.md`
  scenario 6, `openspec/specs/ingest.md` scenario 3). The directory's validation reads such a
  string as a real secret, so the scenarios now describe the value instead of showing one.

## [1.7.0] - 2026-10-11

One command. v1.6.0 shipped the plugin as two skills, `/llm-wiki:wiki` and `/llm-wiki:setup`. The
plugin is now a single root skill with subcommands, as originally intended.

### Changed

- **The plugin command is `/llm-wiki <subcommand>`.** `/llm-wiki:wiki ingest` becomes
  `/llm-wiki ingest`, and `/llm-wiki:setup` becomes `/llm-wiki setup`. This breaks the v1.6.0
  command names; see Migration.
- The skill moved from `skills/wiki/SKILL.md` to `SKILL.md` in the repository root. The plugin has
  no `skills/` directory any more: with one, Claude Code would not load the root file as the
  plugin's single skill (`plugin.md` REQ-860, REQ-862).
- Setup is a subcommand of the skill instead of a skill of its own.
- README, docs, specs and page templates write `/llm-wiki <command>`.
- A skill copied by `setup.sh` is still `.claude/commands/wiki.md` and still invoked as `/wiki`, so
  it never collides with the plugin. `setup.sh` now also writes the path of the repository clone
  into the copy, which makes `/wiki setup` work there.
- The pointer file `wiki.md` stays until v1.8.0 and points to `SKILL.md`.

### Migration

- From v1.6.0: update the plugin and type `/llm-wiki ...` instead of `/llm-wiki:wiki ...` and
  `/llm-wiki setup` instead of `/llm-wiki:setup`. The Wiki root option and the wiki are unaffected.
- Copied skills (`/wiki`) are unaffected.

## [1.6.0] - 2026-10-11

llm-wiki is now a Claude Code plugin. Until now, installing meant cloning the repo and letting
`setup.sh` copy `wiki.md` into one project: no update path, one copy per project, and a skill that
did not know where the wiki was. The repository now doubles as its own plugin marketplace.

### Added

- **Plugin and marketplace manifests** (`.claude-plugin/`). Install with
  `claude plugin marketplace add MehmetGoekce/llm-wiki` and
  `claude plugin install llm-wiki@mehmetgoekce`.
- **Wiki root option.** The plugin asks for the wiki directory once and hands it to the skill.
  Everything else stays in `llm-wiki.yml`.
- **`/llm-wiki:setup`**: creates the wiki skeleton from inside Claude Code.
- **`scripts/init-wiki.sh`**: non-interactive page and config creation, used by both `setup.sh`
  and the setup skill. Validates all input before writing; a second run skips everything.
- Spec `openspec/specs/plugin.md` (REQ-830-880). `config.md` REQ-670-672 define how the wiki root
  is resolved. Counts: 348 requirements, 104 scenarios.

### Changed

- `wiki.md` moved to `skills/wiki/SKILL.md`. A pointer file stays at the old path until v1.7.0.
  With the plugin the command is `/llm-wiki:wiki <command>`; a copied skill stays `/wiki`.
- `setup.sh` asks the same questions as before and delegates page creation to the init script.
- The initial commit contains only the files setup created. Before, `git add -A` also committed
  whatever else was uncommitted in an existing vault.
- Entering `skip` at the memory path prompt now skips it; before, the word was written to
  `memory_path`.
- A missing `llm-wiki.yml` is reported with the wiki root and both ways to create it.

### Fixed

- The skill never received the wiki location. `setup.sh` replaced a `<CONFIG_PATH>` placeholder
  that `wiki.md` did not contain, so the copied skill had to infer the wiki root from context.
  A copied skill now carries the absolute path.
- The Dashboard page was created with a literal `{{NAMESPACES}}` line: the template used a
  placeholder the renderer did not fill. New wikis get the namespace links.

### Migration

- Existing wikis need no change. To move from a copied skill to the plugin: install it, enter the
  existing wiki directory as Wiki root, delete `.claude/commands/wiki.md` from the project.
- An existing Dashboard with a `{{NAMESPACES}}` line: replace the line by hand with one
  `[[Wiki/<Namespace>]]` link per namespace.
- Several wikis on one machine: the plugin holds one Wiki root per user. See the FAQ.

### Not included

- A SessionStart hook for due L1 claims, a deterministic lint script, and the listing in
  Anthropic's plugin directory. Separate changes.

## [1.5.1] - 2026-10-05

### Fixed

- Five places still described page updates as append-only ("never overwrite"), which v1.5.0
  replaced with State + History (REQ-032, REQ-032a/b): `openspec/AGENTS.md`,
  `docs/l1-l2-architecture.md`, both `Schema.md` templates and `.github/SECURITY.md`. New installs
  got a Schema page that contradicted `wiki.md`. The Access-Log stays append-only.

## [1.5.0] - 2026-09-28

Current state on top, history collapsed. The append-only rule ("never overwrite, only append") kept
every fact, but it also turned long-lived blocks into paragraphs of dated addenda: a task picked up
"Status <date>: ..." sentences until the valid state sat in the last line of 2,400 characters, and a
hub's `updated::` property grew into a 5,000-character change log. Nothing was lost, but nothing was
readable either. Piloted on a real hub page before release.

### Changed

- Ingest (REQ-032, new REQ-032a/b): delete nothing, but overwrite stale state. A fact that supersedes
  nothing is still appended. A fact that supersedes a stated state rewrites the block's headline,
  properties and next step, and the superseded wording moves, dated and verbatim, into a collapsed
  `History` child (Logseq `collapsed:: true`, Obsidian folded callout).
- `updated::` holds the date only (REQ-035). Change notes go to the commit message; hubs keep them in a
  collapsed `## Change log`.
- Query write-back follows the same rule (REQ-423).

### Added

- Format section **State + History** in `wiki.md` and `docs/schema-reference.md`, with Logseq and
  Obsidian examples.
- `/wiki lint` Rule 13 **Block Bloat** (REQ-230-234): warns on blocks with more than 600 characters of
  prose outside history sections, and on `updated::` values that are more than a date. `--fix` moves
  `updated::` notes verbatim into `## Change log`; oversized blocks are never auto-restructured.
- Scenarios: ingest 11, lint 15-16. `openspec/project.md` counts: 315 requirements, 95 scenarios.

### Migration

- Existing pages stay valid. Run `/wiki lint` to find bloated blocks, then restructure them by hand or
  on the next ingest that touches them. `lint --fix` handles the `updated::` part.

## [1.4.0] - 2026-09-16

L1 verification. Access-based eviction cannot find stale L1 rules: every L1 file loads every
session, so a stale rule never looks cold. It shows up as the agent confidently acting on an
outdated assumption. L1 staleness is now tied to the kind of claim a rule makes. Prompted by a
reader asking what moves a rule back out of L1 once auto-loading keeps repeating a stale assumption.

Piloted on a real, long-lived L1 (15 files) before release. The pilot changed the spec: verdicts
per claim with an evidence basis, corrections that also reach `description` and the index line,
reference rewriting before removal, and a carry-over summary instead of dumping full files.

### Added

- L1 frontmatter keys `asserts-current-behavior` (`true` = claim about a system's current state,
  `false` = decision/preference, never stale) and `verified` (last evidence check).
  Read at top level or inside a `metadata:` block; writes preserve all other keys.
- `/wiki lint` Rule 12 **L1 Verification Due**: warns on behavior claims never verified or older than
  `l1_verify_days`, reports the unclassified count as one info line. No auto-fix, never prints L1 bodies.
- `/wiki prune --l1 [--batch N] [--days N]`: classify unclassified L1 files (propose, confirm), check due
  claims against read-only local evidence (supports / contradicts / inconclusive), then per rule
  re-verify, demote to L2 as a history block (`source:: l1-demotion`), or delete. Verdicts are per claim
  with an evidence basis (executed / source / file). Corrections reach body, description, and index line;
  references from other L1 files are rewritten before removal. Credential rules are never demoted.
- Config key `l1_verify_days` (default 90).
- Specs: `l1-l2-routing.md` REQ-370-379, `lint.md` REQ-220-225, `prune.md` REQ-900-929,
  `config.md` REQ-660-661, with scenarios. `docs/schema-reference.md` now also documents lint rules 10-11.

### Changed

- REQ-353 (flag L1 files unreferenced for 90 days) superseded by REQ-370-379.
- `openspec/project.md` spec table brought up to date (prune added, counts: 308 requirements, 92 scenarios).

### Not included

- A runtime planning-vs-action gate (warn when a due rule is about to justify an action). Claude Code
  loads L1, not llm-wiki, so there is no hook to enforce it (REQ-379). On the roadmap.

### Known limitations

- Not yet confirmed that Claude Code keeps `asserts-current-behavior` and `verified` when it rewrites
  a memory file's frontmatter (e.g. its own `modified` timestamp). If a key disappears, lint will count
  the file as unclassified again rather than fail silently.

### Fixed

- `docs/l1-l2-architecture.md`: removed the claim that `/wiki lint` flags L1 files unreferenced for 90 days and L2 pages queried in every session. Neither is implemented; lint only flags L1/L2 duplicates. The section now explains why access-based eviction cannot see L1 staleness; the L1 mechanism added in this release replaces that claim.

## [1.3.0] - 2026-06-08

Routing transparency. The Access-Log already recorded which pages a query pulled; now it
records *why* each was picked. Loading becomes auditable — not just what loaded, but the
index description or grep term that selected it. Inspired by a reader pointing out that
knowing *when and why* context loads is half the problem.

### Added

- **Routing reason in the Access-Log** — every `query` log line now carries a
  `matched: "<reason>"` field: the matched hub `### Index` routing description / #tag on
  index routing, or the grep term on the L3 fallback (`<date> -- [[page]] -- query --
  matched: "..."`). Shows not just WHICH page loaded but WHY it was selected for the question.
- `status` cache profile now breaks down the most frequent `matched:` reasons per hot page,
  surfacing mis-routing: a page always hit via the same grep term instead of its index line
  signals a weak or missing routing description in its hub `### Index`.

### Changed

- `openspec/specs/query.md` — REQ-450 line format extended; new REQ-450b defines the
  `matched:` reason semantics (<= 60 chars, quoted, parsing-safe).

### Notes

- Backward compatible: legacy Access-Log lines without `matched:` stay valid (the field is
  additive). prune/status parse date + `[[page]]` from fixed positions (split on ` -- `), so
  the suffix never affects LRU aggregation.

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

[1.5.1]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/MehmetGoekce/llm-wiki/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MehmetGoekce/llm-wiki/releases/tag/v1.0.0
