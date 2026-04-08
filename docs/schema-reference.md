# Schema Reference

The schema is the single most important file in the system. It is the contract between you and the LLM that governs how every wiki page gets created and maintained.

Without a schema, the LLM creates inconsistent pages. One page might use `status: active`, another `state:: running`, a third has no status field at all. With a schema, every page follows the same contract, and automated quality checks become possible. It is the difference between a wiki and a pile of notes.

## Schema Location

| Wiki App | File |
|----------|------|
| Logseq | `Wiki___Schema.md` (in your pages directory) |
| Obsidian | `Wiki/Schema.md` (in your vault) |

The `/wiki` skill reads this file before every operation.

## Page Types

The schema defines five page types. Every wiki page must declare exactly one type via the `type::` property.

### 1. Entity

Represents a person, client, tool, service, or technology. Anything that has identity and persistence.

**Required Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `type::` | `entity` | Page type identifier |
| `entity-type::` | `person` \| `client` \| `tool` \| `service` \| `technology` | What kind of entity |
| `created::` | `YYYY-MM-DD` | When the page was created |
| `updated::` | `YYYY-MM-DD` | Last modification date |
| `status::` | `active` \| `inactive` \| `archived` | Current state |
| `source::` | `memory-migration` \| `ingest` \| `manual` | How the page was created |

**Example (Logseq format):**

```markdown
- type:: entity
- entity-type:: tool
- created:: 2026-03-15
- updated:: 2026-04-07
- status:: active
- source:: ingest
- ## Strapi
  - Headless CMS used for blog and content management.
  - Version: 5.39.0
  - ### Deployment
    - Runs on VPS port 1338
    - Build locally, upload dist/ to server
  - ### Cross-References
    - [[Wiki/Tech/Next-js]] -- Frontend consumer
    - [[Wiki/Reference/Workflows]] -- Publishing workflow
```

**Example (Obsidian format):**

```markdown
---
type: entity
entity-type: tool
created: 2026-03-15
updated: 2026-04-07
status: active
source: ingest
---

## Strapi

Headless CMS used for blog and content management.

Version: 5.39.0

### Deployment

- Runs on VPS port 1338
- Build locally, upload dist/ to server

### Cross-References

- [[Wiki/Tech/Next-js]] -- Frontend consumer
- [[Wiki/Reference/Workflows]] -- Publishing workflow
```

### 2. Project

Tracks a project with timeline, status, and outcomes.

**Required Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `type::` | `project` | Page type identifier |
| `status::` | `active` \| `completed` \| `on-hold` \| `cancelled` | Project state |
| `created::` | `YYYY-MM-DD` | When the page was created |
| `updated::` | `YYYY-MM-DD` | Last modification date |
| `started::` | `YYYY-MM-DD` | When the project began |

**Optional Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `completed::` | `YYYY-MM-DD` | When the project finished (if applicable) |

**Example (Logseq format):**

```markdown
- type:: project
- status:: active
- created:: 2026-03-01
- updated:: 2026-04-07
- started:: 2026-02-15
- ## Blog Series
  - Technical blog series on distributed systems.
  - ### Parts
    - Part 1: Introduction (published 2026-03-01)
    - Part 2: Architecture (published 2026-03-15)
    - Part 3: Implementation (drafting)
  - ### Metrics
    - | Part | Views | Published |
      |------|-------|-----------|
      | Part 1 | 1,200 | 2026-03-01 |
      | Part 2 | 890 | 2026-03-15 |
  - ### Cross-References
    - [[Wiki/Content/Blog]] -- Publishing channel
    - [[Wiki/Content/Newsletter]] -- Promotion
```

### 3. Knowledge

Stores synthesized knowledge on a topic. The most common page type.

**Required Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `type::` | `knowledge` | Page type identifier |
| `domain::` | `tech` \| `business` \| `content` \| `ops` | Knowledge domain |
| `created::` | `YYYY-MM-DD` | When the page was created |
| `updated::` | `YYYY-MM-DD` | Last modification date |
| `confidence::` | `high` \| `medium` \| `low` \| `stale` | How reliable the content is |

**Confidence levels explained:**

| Level | Meaning | Action |
|-------|---------|--------|
| `high` | Verified, up-to-date, reliable | None |
| `medium` | Probably correct, not recently verified | Verify on next ingest |
| `low` | Uncertain, incomplete, or based on limited sources | Flag for review |
| `stale` | Was high/medium but `updated::` is 90+ days old | Re-verify or downgrade |

**Example (Logseq format):**

```markdown
- type:: knowledge
- domain:: tech
- confidence:: high
- created:: 2026-02-01
- updated:: 2026-04-07
- ## Deployment Pipeline
  - CI/CD workflow for production deployments.
  - ### Pre-deploy Checklist
    - 1. Ensure clean git state (no uncommitted changes)
    - 2. Run test suite
    - 3. Check server RAM (stop non-essential services if needed)
  - ### Known Gotchas
    - PM2 reload does not work for npm-started processes
    - Environment variables baked in at build time, not runtime
  - ### Cross-References
    - [[Wiki/Tech/PM2]] -- Process manager
    - [[Wiki/Tech/Nginx]] -- Reverse proxy
```

### 4. Feedback

Captures lessons learned, gotchas, and operational rules. Often promoted to L1 if critical enough.

**Required Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `type::` | `feedback` | Page type identifier |
| `severity::` | `critical` \| `important` \| `nice-to-know` | How serious the lesson is |
| `created::` | `YYYY-MM-DD` | When the feedback was captured |
| `verified::` | `YYYY-MM-DD` | When the lesson was last confirmed |
| `applies-to::` | Page references | Which systems/pages this affects |

**Severity guidelines:**

| Level | Meaning | L1 Candidate? |
|-------|---------|---------------|
| `critical` | Causes data loss, downtime, or security issues | Almost always yes |
| `important` | Causes significant wasted time or incorrect output | Sometimes |
| `nice-to-know` | Minor inconvenience if forgotten | Rarely |

**Example (Logseq format):**

```markdown
- type:: feedback
- severity:: critical
- created:: 2026-03-10
- verified:: 2026-04-01
- applies-to:: [[Wiki/Tech/PM2]], [[Wiki/Tech/Deployment]]
- ## PM2 Reload Gotcha
  - `pm2 reload` does NOT work for processes started with
    `pm2 start npm --name X -- start`.
  - Must use `pm2 delete + pm2 start` instead.
  - ### Context
    - Discovered during production deploy on 2026-03-10.
    - Process appeared to reload but was serving stale code.
  - ### Cross-References
    - [[Wiki/Tech/PM2]] -- Process manager details
    - [[Wiki/Tech/Deployment]] -- Full deploy workflow
```

### 5. Hub

A namespace index page that lists all child pages within its namespace. Hub pages are structural -- they organize the wiki rather than holding knowledge.

**Required Properties:**

| Property | Values | Description |
|----------|--------|-------------|
| `type::` | `hub` | Page type identifier |
| `namespace::` | Namespace path | The namespace this hub indexes |

**Example (Logseq format):**

```markdown
- type:: hub
- namespace:: Wiki/Tech
- ## Tech Hub
  - All technical knowledge pages.
  - ### Pages
    - [[Wiki/Tech/Strapi]] -- Headless CMS
    - [[Wiki/Tech/Next-js]] -- Frontend framework
    - [[Wiki/Tech/PM2]] -- Process manager
    - [[Wiki/Tech/Nginx]] -- Reverse proxy
    - [[Wiki/Tech/Deployment]] -- Deploy pipeline
  - ### Related Hubs
    - [[Wiki/Projects]] -- Project-specific tech decisions
    - [[Wiki/Reference]] -- Workflow documentation
```

## Namespace Conventions

### Top-Level Namespaces

The default schema defines 8 top-level namespaces. Customize these to match your domain.

| Namespace | Purpose | Typical Page Types |
|-----------|---------|-------------------|
| `Wiki/Business` | Clients, services, business strategy | Entity, Knowledge |
| `Wiki/Tech` | Tools, frameworks, infrastructure | Entity, Knowledge, Feedback |
| `Wiki/Content` | Blog, newsletter, social media | Knowledge, Project |
| `Wiki/Projects` | Active and completed projects | Project |
| `Wiki/People` | People you work with | Entity |
| `Wiki/Learning` | Courses, books, research | Knowledge |
| `Wiki/Reference` | Workflows, templates, checklists | Knowledge |
| `Wiki/Careers` | Job applications, opportunities | Project |

### Naming Rules

| Rule | Example |
|------|---------|
| Title Case | `Wiki/Tech/Strapi` (not `Wiki/tech/strapi`) |
| Hyphens for multi-word | `Wiki/Projects/Blog-Series` (not `Blog_Series`) |
| Max depth: 3 levels | `Wiki/Business/Clients/Acme` is the deepest allowed |
| Hub at each level | `Wiki/Tech` is the hub for all `Wiki/Tech/*` pages |

### File Names on Disk

| Wiki App | Convention | Example |
|----------|-----------|---------|
| Logseq | Triple-underscore separator | `Wiki___Tech___Strapi.md` |
| Obsidian | Directory structure | `Wiki/Tech/Strapi.md` |

## Cross-Reference Rules

Cross-references are what make a wiki a wiki, not just a folder of notes.

### Requirements

1. **Every page must have at least 1 outgoing link.** A page with zero `[[Wiki/...]]` links is isolated and will be flagged by lint.
2. **Hub pages must list ALL child pages.** If `Wiki/Tech/Strapi` exists, it must appear in the `Wiki/Tech` hub page.
3. **Mention an entity with a page? Link to it.** If you reference Strapi in a deployment page, use `[[Wiki/Tech/Strapi]]`, not just "Strapi".
4. **Backlinks are automatic** in both Logseq and Obsidian. You only need to create links in one direction.

### Link Syntax

| Type | Syntax | When to use |
|------|--------|-------------|
| Wiki internal | `[[Wiki/Tech/Strapi]]` | Referencing another wiki page |
| Tag | `#strapi` | Lightweight categorization |
| External | `[Strapi Docs](https://docs.strapi.io)` | URLs outside the wiki |

### Cross-Reference Section

Every non-hub page should end with a `### Cross-References` section listing its most important links. This makes the page's relationships explicit and scannable.

```markdown
- ### Cross-References
  - [[Wiki/Tech/Strapi]] -- CMS backend
  - [[Wiki/Tech/Next-js]] -- Frontend framework
  - [[Wiki/Reference/Workflows]] -- Publishing process
```

## Lint Rules

The `/wiki lint` command checks these rules automatically. Run with `--fix` to auto-repair where possible.

### 1. Orphan Detection

**What:** Pages with 0 incoming `[[links]]` from other pages.

**Why:** An orphan page is invisible -- nobody will find it by browsing the wiki. It suggests the page is either misplaced, miscategorized, or missing from its hub.

**Exception:** Hub pages are exempt. They are entry points by definition.

**Auto-fix:** Add the orphan to its namespace's hub page.

### 2. Stale Detection

**What:** Pages where `updated::` is older than 90 days AND `confidence::` is still `high`.

**Why:** Knowledge decays. A page marked "high confidence" but untouched for 3 months is probably overdue for review. The confidence level should be downgraded to `stale` to signal that it needs verification.

**Auto-fix:** Downgrade `confidence::` from `high` to `stale`.

### 3. Missing Properties

**What:** Pages that lack one or more required properties for their declared `type::`.

**Why:** Missing properties break consistency. A `project` page without `status::` cannot be filtered by status. A `knowledge` page without `confidence::` cannot be assessed for reliability.

**Auto-fix:** None -- requires human judgment to fill in correct values. Lint reports the missing properties.

### 4. Broken References

**What:** `[[Wiki/...]]` links that point to pages that do not exist.

**Why:** Broken links are false promises. They suggest knowledge exists when it does not. They also indicate that a page was deleted or renamed without updating references.

**Auto-fix:** Create stub pages for broken links with the appropriate type and a "To be filled via /wiki ingest" placeholder.

### 5. Hub Completeness

**What:** Hub pages that are missing child pages from their namespace.

**Why:** Hubs are the navigational backbone. If a page exists in `Wiki/Tech/` but is not listed in the `Wiki/Tech` hub, it is effectively hidden from browsing.

**Auto-fix:** Add missing children to the hub page.

### 6. Credential Leak

**What:** Wiki pages containing patterns that look like credentials: `token::`, `password::`, `secret::`, `api-key::`, or long base64 strings.

**Why:** Wiki pages are typically git-tracked. Credentials in git history are a security incident. They belong in L1 memory, which is git-excluded.

**Auto-fix:** None -- credentials must be manually moved to L1. Lint flags the page and pattern.

**Severity:** Always `critical`.

### 7. Empty Pages

**What:** Pages that have properties but no actual content below the properties.

**Why:** A page with only `type:: knowledge` and `domain:: tech` has no value. It was probably created as a stub and forgotten.

**Auto-fix:** None -- but lint flags them as candidates for either filling via ingest or deletion.

### 8. Cross-Reference Minimum

**What:** Pages with fewer than 1 outgoing `[[Wiki/...]]` link.

**Why:** An isolated page is a disconnected thought. The power of a wiki comes from connections. Even a stub page should link to its namespace hub.

**Auto-fix:** Add a link to the namespace hub page.

### 9. L1/L2 Duplicates

**What:** Information that appears in both L1 memory files and L2 wiki pages.

**Why:** Duplicates mean one copy will eventually go stale, leading to contradictory knowledge. The LLM might get one version from L1 and a different version from L2.

**Auto-fix:** None -- requires human decision on which location is authoritative. Lint reports the overlap.

## L1/L2 Boundary Rules

The schema explicitly defines what belongs where:

### L1 (Claude Code Memory) -- Auto-loaded

- Operational rules and gotchas (things that prevent mistakes)
- User identity and preferences (name, address, communication style)
- Credentials and secrets (API tokens, passwords)
- Tool-specific quirks that apply every session

### L2 (Wiki) -- On-demand

- Project details and timelines
- Workflow documentation
- Research and learning notes
- Business intelligence and strategy
- Historical decisions and rationale

### The Routing Test

Ask: **"If the LLM does not know this right now, what happens?"**

| Answer | Layer |
|--------|-------|
| Data loss, security issue, or production incident | **L1** (critical) |
| Embarrassing output (wrong name, wrong address) | **L1** (important) |
| Incorrect but easily correctable answer | **L2** |
| Missing context, needs to ask a follow-up | **L2** |

## Content Format Rules

### Logseq Format

```
- Every line is a block, prefixed with "- "
- Indentation creates hierarchy (2-space or tab)
  - Like this child block
- Properties use inline syntax: property:: value
- Headings go inside blocks: - ## Section Name
- Code blocks use fenced syntax inside blocks:
  - ```bash
    echo "hello"
    ```
- Tables work inside blocks:
  - | Column 1 | Column 2 |
    |----------|----------|
    | Value 1  | Value 2  |
```

### Obsidian Format

```markdown
---
type: knowledge
domain: tech
confidence: high
created: 2026-03-15
updated: 2026-04-07
---

## Section Name

Regular markdown paragraphs.

- Bullet points as needed
- No "- " prefix requirement on every line

### Subsection

Code blocks, tables, and all standard markdown features work as expected.

| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |
```

### Key Differences

| Feature | Logseq | Obsidian |
|---------|--------|----------|
| Properties | `property:: value` (inline) | YAML frontmatter |
| Every line prefixed | Yes (`- `) | No |
| Headings | Inside blocks (`- ## Heading`) | Standard markdown (`## Heading`) |
| Hierarchy | Indentation-based | Heading-based |
| Tables | Inside block context | Standard markdown |

### Universal Rules (Both Formats)

- Dates: ISO 8601 (`YYYY-MM-DD`)
- Links: `[[Wiki/Namespace/Page]]` syntax
- External links: `[Text](URL)` syntax
- Tags: `#tag` for lightweight categorization
- No credentials in wiki content (ever)
- Append only -- never overwrite existing content during ingest
