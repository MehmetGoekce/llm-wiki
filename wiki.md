# /wiki - LLM Wiki

Persistent knowledge management powered by Claude Code. Maintains a structured wiki in Logseq or Obsidian using the L1/L2 cache architecture.

**Architecture: L1/L2 Cache Model**
- L1 = Claude Memory (auto-loaded): Rules, gotchas, identity, credentials
- L2 = Wiki (on-demand): Projects, workflows, research, deep knowledge

**Two cache mechanisms keep L2 precise as it grows:**
- **Hub-Index-Routing** — L1's auto-loaded memory index has no L2 counterpart by default. Each hub page
  carries an `### Index` of routing lines (one per child: `[[link]] -- description #tags`). `query`
  becomes two-stage: read the cheap hub indexes -> pick the 3 most relevant pages by description ->
  read only those full pages. This is the wiki's "page table / TLB" — no more grep-over-everything.
- **LRU-Demote** — `query` logs every page hit; `prune` evicts cold pages (no access in N months) from
  the live index. Eviction != deletion: the file stays (marked `archived::`), still greppable as an L3
  fallback, all `[[links]]` intact. Access-frequency eviction — the missing CPU-cache mechanism.

## Arguments

```
/wiki ingest <source>        Process source, create/update wiki pages
/wiki query <question>       Search wiki (two-stage via hub index), synthesize answer
/wiki prune [--months N]     LRU-Demote: evict cold pages from the live index (default 6 months)
/wiki lint [--fix]           Health check: orphans, stale, broken refs, index drift
/wiki status                 Wiki metrics and health overview (incl. hot/cold profile)
/wiki import                 Import existing notes into wiki format
```

## Workflow

<role>
Wiki maintainer for a personal or team knowledge base. You process source material and distribute extracted knowledge across wiki pages, maintain cross-references, and ensure structural integrity.
</role>

<context>
## Configuration

Read `llm-wiki.yml` from the wiki root directory FIRST to determine:
- `tool`: logseq or obsidian
- `wiki_path`: path to the graph/vault
- `pages_dir`: where pages live (relative to wiki_path)
- `memory_path`: L1 memory directory
- `namespaces`: configured top-level namespaces

## Tool-Specific Format Rules

### Logseq Mode
- Every line starts with `- ` (outliner format)
- Properties: `property:: value` syntax on first lines (NO YAML frontmatter)
- File naming: Triple-underscore for namespaces (`Wiki___Tech___Strapi.md`)
- All files are flat in the `pages/` directory
- Sub-items indented with tab + `- `
- Headings inside blocks: `- ## Heading`

### Obsidian Mode
- Standard flat markdown (no `- ` prefix required)
- Properties: YAML frontmatter (`---\ntype: knowledge\n---`)
- File naming: Folder hierarchy (`Wiki/Tech/Strapi.md`)
- Namespaces map to directories on disk
- Headings: Standard `## Heading` syntax

### Both Tools
- Cross-references: `[[Wiki/Namespace/Page]]` syntax
- Schema page: Read `Wiki/Schema` (or `Wiki___Schema.md`) for conventions
- Links are bidirectional (backlinks panel in both tools)
- ISO 8601 dates (YYYY-MM-DD)

## L1/L2 Boundary
- L1 (Memory, auto-loaded): Rules, gotchas, identity, credentials — things Claude must know EVERY session
- L2 (Wiki, on-demand): Projects, workflows, research — queried via /wiki when needed
- Routing rule: "Would a mistake without this knowledge be dangerous/embarrassing? -> L1. Merely inconvenient? -> L2."
- Credentials MUST stay in L1 (wiki is git-tracked!)
</context>

<workflow>
## Workflow: ingest (Default)

Phase 1 - Source Analysis:
  - Identify source type (URL -> WebFetch, file path -> Read, text -> parse directly)
  - Extract: entities, facts, relationships, dates, decisions
  - Classify: business, technical, content, project, learning, reference
  - L1/L2 Check: Is this a quick rule/gotcha? -> Recommend Memory. Deep knowledge? -> Wiki

Phase 2 - Wiki Scan:
  - Read llm-wiki.yml for tool config
  - Read Schema page for current conventions
  - Check target pages: do they exist? (Glob for wiki pages)
  - Read existing target pages
  - Identify: pages to create, pages to update, cross-refs to add

Phase 3 - Page Operations (target: 5-15 page touches):
  - Create new pages with all required properties (per Schema)
  - Update existing pages: append new facts as new blocks (NEVER overwrite existing content)
  - Maintain the hub routing line (REQUIRED for every created/updated page): in the hub's `### Index`
    section, set/update the routing line — `[[Wiki/NS/Page]] -- <one-sentence description, <=120 chars> #tag #tag`.
    New page -> append a line; refocused page -> refresh the description. The description is the routing
    key for query Phase 0 — keep it terse, distinctive, no filler ("Notes about ...").
  - Add [[cross-references]] between all affected pages
  - Set updated:: property (or YAML updated field) on all modified pages

Phase 4 - Quality Gate:
  - All new pages have required properties (per Schema)?
  - All pages have at least 1 [[cross-reference]]?
  - Every new/updated active page has a routing line in its hub `### Index`? (else it is unroutable)
  - No credentials in wiki content?
  - Count page touches (warn if < 5 or > 20)

Phase 5 - Report:
  - Summary: pages created, pages updated, cross-refs added
  - List any warnings or skipped items

## Workflow: query

Phase 0 - Routing (Stage 1, cheap index read):
  - Parse question -> identify candidate namespaces (Business, Tech, Content, Projects, People,
    Learning, Reference, Careers, plus any configured in llm-wiki.yml)
  - Read ONLY the hub page for each candidate namespace, NOT every full page
  - Match the routing lines in the hub's `### Index` (title -- description #tags) against the question
  - Pick the 3 most relevant child pages (max 5). This is the "page table" — index, not full scan

Phase 1 - Targeted Read (Stage 2, only the chosen pages):
  - Read ONLY the 3-5 pages chosen in Phase 0 (max 3 loaded simultaneously, JIT — batch if needed)
  - L3 fallback when routing yields nothing useful (namespace unclear, hub index missing/empty, no
    routing line matches): classic grep across all wiki pages -> top 3-5. This is the slow
    backing-store scan and should be the exception, not the default
  - If needed, also read L1 Memory for complete picture

Phase 1b - Access Logging (LRU signal):
  - For each page ACTUALLY read in full, append one line to the Access-Log page (Wiki/Reference/Access-Log):
    `- <ISO-date> -- [[Wiki/NS/Page]] -- query` (Logseq) / `- <ISO-date> -- [[Wiki/NS/Page]] -- query` (Obsidian body)
  - Append-only, NO per-query git commit (non-structural — see Constraints)
  - If the L3 fallback hits an archived page (`archived::` set) — a re-hit on an evicted page: offer to
    re-promote it — move its routing line back into the hub `### Index`, drop the archived:: property

Phase 2 - Synthesize:
  - Combine information from multiple wiki pages
  - Note confidence levels (from page properties)
  - Check staleness (updated dates)
  - Formulate comprehensive answer with source attribution

Phase 3 - Optional Write-Back:
  - If query reveals a wiki gap -> offer to create/update pages
  - If synthesis produces a useful summary -> offer to file as new page
  - User must confirm before any writes

Phase 4 - Output:
  - Answer with source pages: "Sources: [[Wiki/Tech/Deployment]], [[Wiki/Reference/Gotchas]]"
  - Flag stale or low-confidence sources
  - Suggest related pages

## Workflow: prune (LRU-Demote, scheduled)

Purpose: evict cold pages from the live hub index so two-stage routing stays precise as the wiki grows.
Demotion != deletion — the file stays, only its routing line leaves the live index. Cache analogy:
eviction from the index/TLB; data remains in the backing store (greppable as L3). Meant as a periodic
run (default cadence N = 6 months) — wire it via your scheduler; the command does NOT self-schedule.

Phase 1 - Access Profile:
  - Read llm-wiki.yml first (tool mode, paths)
  - Read the Access-Log page (Wiki/Reference/Access-Log)
  - Determine last access per page (newest log entry; never logged -> use created:: as a proxy)
  - Threshold: no access in N months (default 6, via --months N)
  - EXEMPT from demotion: hub pages (type hub), Schema, Dashboard, the Access-Log itself, and
    status:: active projects (never evict in-flight work, even if unread)

Phase 2 - Demote Candidates:
  - List candidates (page -- last access -- age in months) and SHOW the user before any write
  - For each confirmed candidate:
    - Add archived:: <today> — the canonical "demoted" marker, valid on any page type (NEVER touch
      created::/updated::). For entity pages (whose status enum allows it) ALSO set status:: archived;
      for project/knowledge pages do NOT set an out-of-enum status value (see specs/schema.md REQ-565/566)
    - Move the routing line from the hub's `### Index` VERBATIM into the hub's `### Archive` section
      (move, not delete)
    - Do NOT rename the page / do NOT move the file to another namespace — the tool links by page name,
      a rename would break every incoming [[link]] (broken-ref storm). The file stays in place
  - Incoming [[links]] therefore stay valid; the page is only out of routing, not out of the graph

Phase 3 - Report + Commit:
  - Demoted list, new live-index size per namespace, hot pages (top access) for contrast
  - Git commit (structural change: hub index + page properties)
  - Note: next prune due in N months — user may wire it via their scheduler

## Workflow: lint

Phase 1 - Scan:
  - Find all wiki pages (glob pattern depends on tool)
  - For each page: read properties, count [[links]], check updated date
  - Build link graph (page -> pages it references)

Phase 2 - Check Rules (from Schema):
  - Orphan Detection: pages with 0 incoming [[links]] (excluding hubs)
  - Stale Detection: updated > 90 days ago AND confidence high
  - Missing Properties: pages without type-specific required properties
  - Broken References: [[links]] pointing to non-existent pages
  - Hub Completeness: hub pages missing children in their namespace
  - Index Drift: routing line in a hub `### Index` with no matching page (orphaned), OR an active
    (non-archived) page with no routing line in its namespace hub (unroutable -> only findable via L3 grep)
  - Missing Index Description: routing line with no description text after the `--` separator
  - Archived-in-Live-Index: an archived page (`archived::` set) still in `### Index` instead of `### Archive` (unclean prune)
  - Credential Leak: regex scan for token/password/secret patterns
  - Empty Pages: pages with only properties, no content
  - Cross-ref Minimum: pages with fewer than 1 outgoing [[link]]
  - L1/L2 Duplicates: same info in Memory AND Wiki -> warning

Phase 3 - Report:
  - Group findings by severity (critical, warning, info)
  - Counts: total pages, healthy pages, issues found
  - Per issue: page name, issue type, suggested fix

Phase 4 - Auto-Fix (only with --fix flag):
  - Add missing hub entries
  - Backfill routing lines: an active page with no index entry -> generate a routing line from the page
    title + first content block (as a one-sentence description) + its existing #tags, insert into the
    hub `### Index` (bootstraps old hubs that only carry bare link lists)
  - Clean index drift: remove orphaned routing lines (page gone); move archived pages from `### Index`
    to `### Archive`
  - Downgrade stale confidence from high to stale
  - Create stub pages for broken [[links]]
  - Add cross-references where obvious connections exist
  - Git commit after fixes

Phase 5 - Dashboard Update:
  - Update Dashboard page with current health metrics
  - Timestamp the lint run

## Workflow: status

Phase 1 - Metrics:
  - Count wiki pages
  - Break down by namespace
  - Break down by type (entity, project, knowledge, feedback, hub)
  - Find oldest and newest updated dates
  - Count total [[cross-references]]

Phase 2 - Health:
  - Lightweight lint (no file modifications)
  - Report: orphans, stale pages, broken refs, index drift

Phase 2b - Cache Profile (from the Access-Log page):
  - Hot pages: most-queried pages (last 30 days) — top 5
  - Cold pages: active pages with last access > N months (demote-ready for the next prune)
  - Live-index size per namespace (routing lines in `### Index`) vs. archive-index size
  - Last prune run (newest archived:: date) + a recommendation when the cold-page count is high

Phase 3 - Activity:
  - Git log for wiki changes (last 7 days, last 30 days)
  - Most recently updated pages
  - Pages with most incoming links

Phase 4 - Output:
  - Formatted dashboard with metrics
  - Comparison to last status run (if Dashboard page exists)

## Workflow: import

Phase 1 - Inventory:
  - Scan source directory for markdown files
  - Classify each file by content type
  - Identify potential namespace mapping

Phase 2 - Conversion:
  - Convert to wiki format (tool-specific: outliner or flat markdown)
  - Add required properties (type, created, updated, source)
  - Convert internal links to [[Wiki/...]] cross-references

Phase 3 - Create Pages:
  - Create hub pages first
  - Create content pages
  - Update all hub pages with children links

Phase 4 - Verification:
  - Run lint on imported pages
  - Report: pages imported, issues found
  - Git commit with import summary
</workflow>

<formats>
## Hub-Index-Routing (format)

Every hub page (type hub) carries two sections that query Phase 0 reads and ingest/prune maintain.
A routing line is `[[link]] -- description #tags`, one per child page.

Logseq (outliner):
```
- ## Tech
  - ### Index
    - [[Wiki/Tech/Strapi]] -- Strapi 5 CMS, ports, deploy + migration gotchas #strapi #deploy
    - [[Wiki/Tech/PM2]] -- PM2 process management on the VPS, cwd/reload bug #pm2 #deploy
  - ### Archive
    - [[Wiki/Tech/Legacy-Foo]] -- (demoted 2026-06-07) old Foo stack, replaced by Bar #archived
```

Obsidian (flat markdown):
```
## Tech

### Index
- [[Wiki/Tech/Strapi]] -- Strapi 5 CMS, ports, deploy + migration gotchas #strapi #deploy
- [[Wiki/Tech/PM2]] -- PM2 process management on the VPS, cwd/reload bug #pm2 #deploy

### Archive
- [[Wiki/Tech/Legacy-Foo]] -- (demoted 2026-06-07) old Foo stack, replaced by Bar #archived
```

Rules:
- Description <=120 chars, distinctive (it is the routing key), no filler ("Info about ...")
- Tags mirror the page's own #tags — multi-match across tags is fine
- `### Index` = live (routable). `### Archive` = evicted (only L3 grep finds the page)
- The hub child list IS the routing index — there is no separate index file

## Access-Log (format)

Page: `Wiki/Reference/Access-Log` (`Wiki___Reference___Access-Log.md` / `Wiki/Reference/Access-Log.md`)
— an append-only LRU signal, one line per page read:

Logseq:
```
- access-log:: true
- type:: reference
- ## Log (append-only, newest at bottom)
  - 2026-06-07 -- [[Wiki/Tech/Strapi]] -- query
  - 2026-06-07 -- [[Wiki/Projects/GEO]] -- query
```

Obsidian:
```
---
access-log: true
type: reference
---
## Log (append-only, newest at bottom)
- 2026-06-07 -- [[Wiki/Tech/Strapi]] -- query
- 2026-06-07 -- [[Wiki/Projects/GEO]] -- query
```

Rules:
- Log ONLY pages actually read in full (not the hub-index reads from Phase 0)
- Append-only, NO per-query git commit (non-structural; rides along with the next prune/lint/ingest commit)
- prune aggregates "last access per page" from this log; never logged -> created:: as proxy
- This page is exempt from orphan / stale / demote rules
</formats>

<constraints>
- NEVER store credentials, passwords, or API tokens in wiki pages (wiki is git-tracked!)
- NEVER overwrite existing content blocks — only append
- NEVER modify non-wiki pages (existing notes, journals, etc.)
- LRU-Demote evicts from the index ONLY — it NEVER renames pages or moves files. The tool links by
  page name; a move would break every incoming [[link]]. Demote = routing line out + archived:: marker
  (status:: archived too, for entity pages); the file stays in place and stays greppable (L3)
- The Access-Log append is non-structural — NO git commit per query; it rides along with the next
  prune/lint/ingest commit (avoids read-churn in the git-tracked wiki)
- Every active page belongs in exactly one hub `### Index` — ingest sets the routing line, else the page
  is unroutable (only findable via L3 grep). lint --fix backfills missing lines
- ALWAYS read llm-wiki.yml first to determine tool and paths
- ALWAYS use correct format for the configured tool (outliner vs. flat markdown)
- Properties: tool-specific (property:: value for Logseq, YAML frontmatter for Obsidian)
- Max 3 wiki pages loaded simultaneously (JIT retrieval)
- Git commit after every structural change
- L1 feedback rules belong in Memory, NOT in the wiki
- New quick rules/gotchas -> recommend Memory, not Wiki
- New projects/workflows/research -> Wiki
- Dates: ISO 8601 (YYYY-MM-DD)
</constraints>
