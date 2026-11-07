# Project: llm-wiki

## Context

llm-wiki implements Andrej Karpathy's "LLM Wiki" concept — a persistent, structured
knowledge base maintained by an LLM (Claude Code) using a dual-layer cache architecture
inspired by CPU memory hierarchies.

- **Owner:** Mehmet Goekce / MEMOTECH
- **License:** MIT (open-source)
- **Repository:** github.com/MehmetGoekce/llm-wiki
- **Status:** Released (v1.8), actively developed

## Architecture

- **L1 (Fast, auto-loaded):** Claude Code memory directory (~10-20 files). Rules, gotchas,
  credentials, identity. Loaded every session. Git-excluded.
- **L2 (On-demand):** Logseq or Obsidian wiki (~50-200 pages). Projects, workflows,
  research, deep knowledge. Queried via `/llm-wiki` commands. Git-tracked.

## Tech Stack

- **Runtime:** Claude Code (CLI)
- **Distribution:** Claude Code plugin from this repository (which is also the marketplace); a
  skill copied by hand for installs without the plugin
- **Dependencies:** none beyond Claude Code; git optional (no scripts, no npm, no pip)
- **Wiki tools:** Logseq (outliner) or Obsidian (flat markdown)
- **Config:** `llm-wiki.yml` (YAML)
- **Format:** Markdown with tool-specific conventions

## Stakeholders

| Role | Who | Responsibility |
|------|-----|---------------|
| Maintainer | Mehmet Goekce | Architecture, releases, specs |
| Contributors | Open-source community | Features, bug fixes, templates |
| Users | Claude Code users | Install, configure, use /llm-wiki commands |

## Constraints

- No executable files and no dependencies: only Markdown, text, JSON, YAML and images
  (plugin directory policy, plugin.md REQ-835-837); git optional
- Must work on macOS, Linux, WSL
- Must support both Logseq and Obsidian (identical capabilities, different format)
- Config always reads from `llm-wiki.yml`
- Max 3 wiki pages loaded simultaneously (LLM context budget)
- Credentials MUST stay in L1 (L2 is git-tracked)
- No deletion: new facts are appended, superseded state moves to a collapsed History

## Specs

| Spec | Covers | Requirements | Scenarios |
|------|--------|-------------|-----------|
| specs/ingest.md | /llm-wiki ingest — 5-phase source processing pipeline | 36 | 11 |
| specs/query.md | /llm-wiki query — two-stage routing, synthesis, access log | 26 | 13 |
| specs/lint.md | /llm-wiki lint — 13 automated health checks with auto-fix | 58 | 16 |
| specs/prune.md | /llm-wiki prune — L2 index eviction, `--l1` verification | 39 | 15 |
| specs/schema.md | Page types, properties, validation, format rules | 49 | 10 |
| specs/config.md | Wiki root resolution, llm-wiki.yml loading, validation, error handling | 23 | 11 |
| specs/setup.md | `setup` subcommand: questions, page and config creation, first commit | 44 | 11 |
| specs/plugin.md | Plugin manifest, marketplace, root skill `/llm-wiki`, file policy | 23 | 5 |
| specs/l1-l2-routing.md | L1/L2 boundary decision logic, L1 staleness | 40 | 11 |
| **Total** | **Complete system coverage** | **338** | **103** |
