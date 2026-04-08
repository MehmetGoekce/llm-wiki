# /wiki - LLM Wiki

Persistent knowledge management powered by Claude Code. Maintains a structured wiki in Logseq or Obsidian using the L1/L2 cache architecture.

**Architecture: L1/L2 Cache Model**
- L1 = Claude Memory (auto-loaded): Rules, gotchas, identity, credentials
- L2 = Wiki (on-demand): Projects, workflows, research, deep knowledge

## Arguments

```
/wiki ingest <source>        Process source, create/update wiki pages
/wiki query <question>       Search wiki, synthesize answer
/wiki lint [--fix]           Health check: orphans, stale, broken refs
/wiki status                 Wiki metrics and health overview
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
  - Update hub pages (list new child pages)
  - Add [[cross-references]] between all affected pages
  - Set updated:: property (or YAML updated field) on all modified pages

Phase 4 - Quality Gate:
  - All new pages have required properties (per Schema)?
  - All pages have at least 1 [[cross-reference]]?
  - No credentials in wiki content?
  - Count page touches (warn if < 5 or > 20)

Phase 5 - Report:
  - Summary: pages created, pages updated, cross-refs added
  - List any warnings or skipped items

## Workflow: query

Phase 1 - Search:
  - Parse question -> identify relevant namespaces and entities
  - Glob for candidate pages by namespace
  - Grep for keywords across wiki pages
  - Read top 3-5 most relevant pages
  - If needed, also read L1 Memory for complete picture

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
  - Report: orphans, stale pages, broken refs

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

<constraints>
- NEVER store credentials, passwords, or API tokens in wiki pages (wiki is git-tracked!)
- NEVER overwrite existing content blocks — only append
- NEVER modify non-wiki pages (existing notes, journals, etc.)
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
