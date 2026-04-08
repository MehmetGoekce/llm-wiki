# Logseq vs. Obsidian

llm-wiki supports both Logseq and Obsidian as the wiki UI layer. This document explains the differences, helps you choose, and provides migration paths if you switch later.

## Why Both?

The LLM wiki pattern is fundamentally about structured markdown files with cross-references. Both Logseq and Obsidian operate on local markdown files, render `[[wikilinks]]`, and provide graph views. The *pattern* is the same -- the *format* differs.

Supporting both means you can use whichever tool fits your workflow. If you prefer outliner-style editing and block-level granularity, use Logseq. If you prefer flat markdown and a rich plugin ecosystem, use Obsidian. The wiki's value is in the knowledge, not the renderer.

## Feature Comparison

| Feature | Logseq | Obsidian |
|---------|--------|----------|
| **Data format** | Outliner (every line is `- ` prefixed) | Flat markdown |
| **Properties** | `property:: value` (inline) | YAML frontmatter |
| **File structure** | Flat directory, namespaces in filename (`Wiki___Tech___Strapi.md`) | Nested directories (`Wiki/Tech/Strapi.md`) |
| **Links** | `[[Wiki/Tech/Strapi]]` | `[[Wiki/Tech/Strapi]]` |
| **Backlinks** | Built-in, automatic | Built-in, automatic |
| **Graph view** | Yes | Yes |
| **Block references** | Native (every block has a UUID) | Via plugin or block-id |
| **Plugin ecosystem** | Growing, smaller | Massive, 1000+ plugins |
| **Mobile app** | Yes (beta quality) | Yes (solid) |
| **Sync** | Logseq Sync or git | Obsidian Sync, git, or any file sync |
| **License** | AGPL-3.0 (open source) | Proprietary (free for personal use) |
| **Local-first** | Yes, always | Yes, always |
| **Pricing** | Free (Sync is paid) | Free for personal, paid for commercial |

## When to Choose Logseq

Logseq is the better choice when:

**The LLM does most of the writing.** Logseq's outliner format means every block (line) is independently addressable. When the LLM appends new content to a page, it adds new blocks without touching existing ones. In flat markdown, appending content requires understanding the document structure -- where does the new paragraph go? After which heading? The outliner format makes this unambiguous.

**You want block-level granularity.** In Logseq, you can reference, embed, and link to individual blocks. This is powerful for a wiki where specific facts need to be cited across multiple pages.

**You value open source.** Logseq is AGPL-3.0 licensed. You can audit the code, contribute, and know that your tool will not disappear behind a paywall. For a knowledge base that might contain sensitive information, the ability to verify what the software does matters.

**You prefer a daily journal workflow.** Logseq's journal pages are first-class. If you like capturing thoughts in a daily log and then extracting wiki-worthy knowledge via `/wiki ingest`, Logseq's journal integration makes this natural.

## When to Choose Obsidian

Obsidian is the better choice when:

**You do a lot of manual editing.** Flat markdown is more natural to write by hand. No `- ` prefix on every line, standard heading syntax, and YAML frontmatter that most developers already know. If you split your time between LLM-generated and hand-written content, Obsidian's format is less friction.

**You need specific plugins.** Obsidian's plugin ecosystem is massive. Dataview for database-like queries, Kanban for project boards, Calendar for timeline views, Templater for advanced templates. If your workflow depends on specific functionality, Obsidian probably has a plugin for it.

**You want polished mobile editing.** Obsidian's mobile app is more mature. If you frequently edit wiki pages from your phone, this matters.

**You prefer nested directories.** Obsidian stores files in a directory hierarchy that mirrors the namespace structure: `Wiki/Tech/Strapi.md`. This makes browsing the wiki in any file manager intuitive. Logseq's flat directory with triple-underscore filenames (`Wiki___Tech___Strapi.md`) is less readable at the filesystem level.

**Your team uses Obsidian.** If you are introducing the wiki pattern to a team and they already use Obsidian, the lower switching cost wins.

## Format Differences in Detail

### Properties

**Logseq** uses inline property syntax on the first lines of the page:

```markdown
- type:: knowledge
- domain:: tech
- confidence:: high
- created:: 2026-03-15
- updated:: 2026-04-07
- ## Topic Title
  - Content goes here as indented blocks.
```

**Obsidian** uses YAML frontmatter:

```markdown
---
type: knowledge
domain: tech
confidence: high
created: 2026-03-15
updated: 2026-04-07
---

## Topic Title

Content goes here as regular markdown.
```

### Content Structure

**Logseq** -- every line is a block, hierarchy via indentation:

```markdown
- ## Deployment Pipeline
  - CI/CD workflow for production.
  - ### Steps
    - 1. Run test suite
    - 2. Build production bundle
    - 3. Upload to server
    - 4. Restart process manager
  - ### Known Issues
    - Process manager reload does not work for npm-started processes.
    - Must delete and re-start instead.
  - ### Cross-References
    - [[Wiki/Tech/PM2]] -- Process manager
    - [[Wiki/Tech/Nginx]] -- Reverse proxy
```

**Obsidian** -- standard markdown:

```markdown
## Deployment Pipeline

CI/CD workflow for production.

### Steps

1. Run test suite
2. Build production bundle
3. Upload to server
4. Restart process manager

### Known Issues

- Process manager reload does not work for npm-started processes.
- Must delete and re-start instead.

### Cross-References

- [[Wiki/Tech/PM2]] -- Process manager
- [[Wiki/Tech/Nginx]] -- Reverse proxy
```

### Tables

**Logseq** -- tables are inside blocks:

```markdown
- ### Metrics
  - | Metric | Value | As of |
    |--------|-------|-------|
    | Users | 240 | 2026-04-01 |
    | Growth | 12% MoM | 2026-04-01 |
```

**Obsidian** -- standard markdown tables:

```markdown
### Metrics

| Metric | Value | As of |
|--------|-------|-------|
| Users | 240 | 2026-04-01 |
| Growth | 12% MoM | 2026-04-01 |
```

### File Names and Namespaces

**Logseq** uses a flat pages directory with triple-underscore separators:

```
pages/
  Wiki___Schema.md
  Wiki___Tech.md               (hub)
  Wiki___Tech___Strapi.md
  Wiki___Tech___Next-js.md
  Wiki___Tech___PM2.md
  Wiki___Projects.md            (hub)
  Wiki___Projects___Blog-Series.md
```

**Obsidian** uses nested directories:

```
Wiki/
  Schema.md
  Tech/
    Tech.md                     (hub, or _index.md)
    Strapi.md
    Next-js.md
    PM2.md
  Projects/
    Projects.md                 (hub)
    Blog-Series.md
```

## Migration Paths

### Logseq to Obsidian

If you started with Logseq and want to switch to Obsidian:

**Step 1 -- Convert properties.** Replace inline `property:: value` with YAML frontmatter.

```
Before (Logseq):
- type:: knowledge
- domain:: tech

After (Obsidian):
---
type: knowledge
domain: tech
---
```

**Step 2 -- Remove outliner prefixes.** Strip the `- ` prefix from content lines. Keep it for actual bullet points.

**Step 3 -- Restructure files.** Move from flat directory with triple-underscore names to nested directories.

```
Before: pages/Wiki___Tech___Strapi.md
After:  Wiki/Tech/Strapi.md
```

**Step 4 -- Update links.** Links stay the same (`[[Wiki/Tech/Strapi]]`) -- both apps use identical syntax.

**Step 5 -- Validate.** Run `/wiki lint` to catch any broken references or missing properties.

**Automation:** The `./migrate.sh logseq-to-obsidian` script handles steps 1-3 automatically. Review the output and run lint to verify.

### Obsidian to Logseq

If you started with Obsidian and want to switch to Logseq:

**Step 1 -- Convert properties.** Replace YAML frontmatter with inline `property:: value` syntax.

**Step 2 -- Add outliner prefixes.** Every line must start with `- `. Indentation creates hierarchy.

**Step 3 -- Flatten files.** Move from nested directories to flat directory with triple-underscore names.

```
Before: Wiki/Tech/Strapi.md
After:  pages/Wiki___Tech___Strapi.md
```

**Step 4 -- Update links.** Links stay the same.

**Step 5 -- Validate.** Run `/wiki lint`.

**Automation:** The `./migrate.sh obsidian-to-logseq` script handles steps 1-3 automatically.

## Dual-Format Support in the Schema

The schema itself is wiki-app-agnostic at the conceptual level. The same 5 page types, 8 namespaces, and 9 lint rules apply regardless of whether you use Logseq or Obsidian. The only differences are in serialization:

| Schema Concept | Logseq Serialization | Obsidian Serialization |
|----------------|---------------------|----------------------|
| Page type declaration | `- type:: knowledge` | `type: knowledge` (frontmatter) |
| Date property | `- updated:: 2026-04-07` | `updated: 2026-04-07` (frontmatter) |
| Section heading | `- ## Section` | `## Section` |
| Cross-reference | `- [[Wiki/Tech/Strapi]]` | `[[Wiki/Tech/Strapi]]` |
| Content block | `- Some text here` | `Some text here` |

The `/wiki` skill reads `config.yml` to determine which format to use and adjusts its output accordingly. The schema rules (required properties, lint checks, L1/L2 boundary) are enforced identically in both formats.

## Recommendation

If you are starting fresh and have no preference:

- **Solo use, LLM does most writing** --> Logseq
- **Solo use, you write as much as the LLM** --> Obsidian
- **Team use** --> Obsidian (lower learning curve, bigger ecosystem)
- **Privacy-critical** --> Logseq (fully open source, auditable)
- **Mobile-heavy** --> Obsidian (more mature mobile app)

Either way, you can migrate later. The knowledge is in the content and the cross-references, not in the file format.
