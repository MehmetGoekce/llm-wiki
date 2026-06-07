# Spec: /wiki ingest — Source Processing Pipeline

## Description

The ingest command processes external sources (URLs, files, text) and distributes
extracted knowledge across wiki pages. It is the primary write path into the wiki.
A single ingest run targets 5-15 page touches (creates + updates + hub updates).

---

## Requirements

### Phase 1: Source Analysis

- REQ-010: The system SHALL accept three source types: URL (fetched via WebFetch),
  file path (read from disk), and inline text (parsed directly).
- REQ-011: The system SHALL extract entities, facts, relationships, dates, and
  decisions from the source material.
- REQ-012: The system SHALL classify extracted knowledge into exactly one of six
  categories: business, technical, content, project, learning, reference.
- REQ-013: The system SHALL evaluate each extracted fact against the L1/L2 routing
  rule (see specs/l1-l2-routing.md) and recommend Memory for L1 candidates.
- REQ-014: The system SHOULD identify when a source contains credentials or secrets
  and MUST NOT write them to wiki pages.

### Phase 2: Wiki Scan

- REQ-020: The system SHALL read `llm-wiki.yml` before any wiki operations to
  determine tool mode (logseq/obsidian), paths, and namespace configuration.
- REQ-021: The system SHALL read the Schema page to load current conventions and
  property requirements.
- REQ-022: The system SHALL glob for existing wiki pages matching extracted entities
  and topics to identify update targets.
- REQ-023: The system SHALL read existing target pages before modifying them.
  Maximum 3 pages loaded simultaneously (JIT retrieval).
- REQ-024: The system SHALL produce a page operation plan: pages to create,
  pages to update, cross-references to add, hub pages to update.

### Phase 3: Page Operations

- REQ-030: The system SHALL create new pages with ALL required properties for the
  declared page type (per Schema). Missing required properties are a spec violation.
- REQ-031: The system SHALL use the correct format for the configured tool:
  Logseq (outliner with `- ` prefix, `property:: value`) or Obsidian (flat markdown,
  YAML frontmatter).
- REQ-032: The system MUST NOT overwrite existing content blocks when updating pages.
  New facts SHALL be appended as new blocks below existing content.
- REQ-033: The system SHALL update hub pages to list any newly created child pages
  in their namespace.
- REQ-033a: For every page created or updated, the system SHALL set or refresh its
  routing line in the namespace hub's `### Index` section, formatted
  `[[Wiki/NS/Page]] -- <one-sentence description, <=120 chars> #tags` (see specs/schema.md
  and specs/query.md Phase 0). The description is the routing key consumed by two-stage
  query and MUST be terse and distinctive, not filler. A page without a routing line is
  unroutable.
- REQ-034: The system SHALL add `[[Wiki/Namespace/Page]]` cross-references between
  all affected pages. Every page touched MUST have at least 1 outgoing wiki link.
- REQ-035: The system SHALL set the `updated::` property (or YAML `updated` field)
  to today's date on every modified page.
- REQ-036: When a page mentions an entity that has its own wiki page, the system
  SHALL use `[[Wiki/...]]` link syntax instead of plain text.
- REQ-037: The system SHOULD target 5-15 page touches per ingest. Fewer than 5
  suggests insufficient cross-referencing. More than 20 suggests the ingest should
  be split.
- REQ-038: File names MUST follow tool conventions: Logseq uses triple-underscore
  separators (`Wiki___Tech___Strapi.md`), Obsidian uses directory hierarchy
  (`Wiki/Tech/Strapi.md`).
- REQ-039: Namespace depth MUST NOT exceed 3 levels
  (e.g., `Wiki/Business/Clients/Acme` is the maximum depth).

### Phase 4: Quality Gate

- REQ-040: The system SHALL verify that all new pages have ALL required properties
  for their declared type before completing the ingest.
- REQ-041: The system SHALL verify that every touched page has at least 1 outgoing
  `[[Wiki/...]]` cross-reference.
- REQ-041a: The system SHALL verify that every new or updated active page has a
  routing line in its namespace hub `### Index` (REQ-033a). A missing routing line is
  a warning (the page is unroutable until `lint --fix` backfills it).
- REQ-042: The system SHALL scan all created/updated content for credential patterns
  (`token::`, `password::`, `secret::`, `api-key::`, base64 strings of 40+ chars).
  Any match MUST block the ingest and warn the user.
- REQ-043: The system SHALL count page touches and emit a warning if the count is
  below 5 or above 20.
- REQ-044: The quality gate SHALL NOT block the ingest on page-touch count warnings
  (REQ-043). It SHALL block on credential detection (REQ-042) and missing required
  properties (REQ-040).

### Phase 5: Report

- REQ-050: The system SHALL output a summary listing: pages created (with types),
  pages updated, cross-references added, hub pages updated.
- REQ-051: The system SHALL list any warnings (low page-touch count, L1 candidates
  found, skipped items) and their reasons.
- REQ-052: The system SHOULD recommend a git commit after structural changes.

### Cross-Cutting

- REQ-060: The system MUST NOT modify any non-wiki pages (existing Logseq journals,
  personal notes, other vault content).
- REQ-061: The system SHALL use ISO 8601 date format (YYYY-MM-DD) for all date
  properties.
- REQ-062: When the configured tool is Logseq, every line of wiki content MUST start
  with `- ` (outliner block prefix). Properties MUST use `property:: value` syntax.
- REQ-063: When the configured tool is Obsidian, properties MUST be in YAML
  frontmatter. Content uses standard markdown without block prefixes.

---

## Scenarios

### Scenario 1: Ingest a URL source (happy path)

```
GIVEN llm-wiki.yml is configured with tool: logseq and wiki_path: /tmp/test-wiki
AND the wiki has a Schema page and a Wiki/Tech hub page
AND no page exists for "Redis"
WHEN the user runs /wiki ingest "https://redis.io/docs/about/"
THEN the system SHALL create a new page Wiki___Tech___Redis.md
AND the page SHALL have properties: type:: entity, entity-type:: technology,
    created:: [today], updated:: [today], status:: active, source:: ingest
AND the page SHALL contain extracted facts about Redis from the URL
AND the page SHALL have at least 1 [[Wiki/Tech]] cross-reference
AND the Wiki___Tech.md hub `### Index` SHALL gain a routing line:
    "[[Wiki/Tech/Redis]] -- In-memory data store, cache + pub/sub #redis"
AND the report SHALL show: 1 page created, 1 hub updated, N cross-refs added
```

### Scenario 2: Ingest updates existing page (append-only)

```
GIVEN a page Wiki___Tech___Strapi.md exists with content "Headless CMS for Node.js"
AND the page has updated:: 2026-03-01
WHEN the user runs /wiki ingest "Strapi 5 uses documentId for PUT, not numeric id"
THEN the system SHALL append a new block to the existing page
AND the original content "Headless CMS for Node.js" SHALL still be present unchanged
AND updated:: SHALL be changed to [today]
AND the report SHALL show: 1 page updated
```

### Scenario 3: Credential detected in source — ingest blocked

```
GIVEN the user provides source text containing "api-key:: sk-abc123def456ghi789"
WHEN the system reaches Phase 4 (Quality Gate)
THEN the ingest SHALL be blocked
AND the system SHALL warn: "Credential pattern detected. Move to L1 memory, not wiki."
AND no wiki pages SHALL be created or modified
```

### Scenario 4: L1 candidate detected — recommend memory

```
GIVEN the user provides source text "PM2 reload does not work with npm start"
WHEN the system evaluates L1/L2 routing in Phase 1
THEN the system SHALL identify this as an L1 candidate (operational gotcha)
AND the system SHALL recommend: "This looks like an L1 rule. Consider saving to
    Memory instead of Wiki."
AND the system SHALL still proceed with wiki ingest if the user confirms
```

### Scenario 5: Page touch count below minimum

```
GIVEN a simple source with one fact about an existing page
WHEN the ingest completes with only 2 page touches
THEN the system SHALL emit a warning: "Only 2 page touches (target: 5-15).
    Consider adding cross-references to related pages."
AND the ingest SHALL complete successfully (warning, not blocking)
```

### Scenario 6: Page touch count above maximum

```
GIVEN a complex source spanning 25 different topics
WHEN the ingest plan identifies 25 page operations
THEN the system SHALL emit a warning: "25 page touches exceeds target (5-15).
    Consider splitting this ingest into multiple runs."
AND the ingest SHALL complete successfully (warning, not blocking)
```

### Scenario 7: Hub page missing for new namespace child

```
GIVEN a hub page Wiki___Projects.md exists
AND no page Wiki___Projects___NewProject.md exists
WHEN the user ingests information about "NewProject"
THEN the system SHALL create Wiki___Projects___NewProject.md with required properties
AND the system SHALL append [[Wiki/Projects/NewProject]] to Wiki___Projects.md
```

### Scenario 8: Obsidian mode — YAML frontmatter format

```
GIVEN llm-wiki.yml is configured with tool: obsidian and wiki_path: /tmp/test-wiki
WHEN the user ingests a new technology "Milvus"
THEN the system SHALL create Wiki/Tech/Milvus.md
AND the file SHALL start with YAML frontmatter:
    ---
    type: entity
    entity-type: technology
    created: [today]
    updated: [today]
    status: active
    source: ingest
    ---
AND the content SHALL use standard markdown without "- " block prefixes
```

### Scenario 9: Max 3 pages loaded simultaneously

```
GIVEN an ingest source references 8 existing wiki pages
WHEN Phase 2 identifies all 8 as update targets
THEN the system SHALL read at most 3 pages at a time
AND process them in batches: read 3, update 3, read next 3, update next 2
AND all 8 pages SHALL be correctly updated after the ingest completes
```

### Scenario 10: Namespace depth violation

```
GIVEN a source describes an entity "Contact" under Wiki/Business/Clients/Acme
WHEN the ingest would create Wiki/Business/Clients/Acme/Contact (depth 4)
THEN the system SHALL NOT create the 4-level page
AND the system SHALL instead add "Contact" as a section within the
    Wiki/Business/Clients/Acme page
AND the report SHALL note: "Namespace depth limit (3) reached, content merged
    into parent page"
```

---

## Acceptance Criteria

- [ ] All 5 phases execute in order (Analysis, Scan, Operations, Quality Gate, Report)
- [ ] URL, file path, and inline text sources all work
- [ ] New pages have ALL required properties per Schema
- [ ] Existing pages are never overwritten — only appended to
- [ ] Hub pages list all child pages after ingest
- [ ] Every created/updated active page has a routing line in its hub `### Index`
- [ ] Every touched page has at least 1 cross-reference
- [ ] Credential patterns block the ingest
- [ ] Page touch warnings are emitted but do not block
- [ ] Works correctly in both Logseq and Obsidian modes
- [ ] Max 3 pages loaded simultaneously during processing
- [ ] Namespace depth never exceeds 3 levels
- [ ] All dates use ISO 8601 format

---

## Dependencies

- `llm-wiki.yml` must exist and be valid
- Schema page must exist in the wiki
- specs/l1-l2-routing.md defines the L1/L2 routing decision logic used in Phase 1
