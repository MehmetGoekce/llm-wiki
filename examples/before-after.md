# Before & After: Wiki Page Synthesis

This example shows how `llm-wiki ingest` transforms a raw placeholder page into a
well-structured, cross-referenced wiki page.

---

## Example: "Newsletter" topic

### BEFORE (placeholder page, no synthesis)

#### Logseq format

```markdown
- type:: knowledge
- created:: 2025-03-10
- updated:: 2025-03-10
- ## Newsletter
	- We send a newsletter.
```

#### Obsidian format

```markdown
---
type: knowledge
created: 2025-03-10
updated: 2025-03-10
---

# Newsletter

We send a newsletter.
```

---

### AFTER (synthesized by `llm-wiki ingest`)

#### Logseq format

```markdown
- type:: knowledge
- domain:: content
- created:: 2025-03-10
- updated:: 2025-06-15
- confidence:: high
- ## Newsletter
	- Monthly email newsletter sent to subscribers with project updates, technical insights, and community highlights.
- ## Workflow
	- Draft content in [[Wiki/Content/Writing-Process]] using the standard template
	- Review with at least one team member before sending
	- Send via the newsletter platform on the first Monday of each month
	- Archive the issue in [[Wiki/Content/Newsletter-Archive]]
- ## Audience
	- Primary: existing clients and partners
	- Secondary: developer community and tech leads
	- Current subscriber count tracked in [[Wiki/Business/Metrics]]
- ## Tools
	- [[Wiki/Tech/Email-Platform]] -- delivery and analytics
	- [[Wiki/Tech/Markdown-Editor]] -- drafting and formatting
- ## Lessons Learned
	- Plain-text subject lines outperform emoji-heavy ones (tested Q1 2025)
	- Sending on Monday mornings yields ~20% higher open rates than Fridays
	- See [[Wiki/Reference/Newsletter-Gotchas]] for common pitfalls
```

#### Obsidian format

```markdown
---
type: knowledge
domain: content
created: 2025-03-10
updated: 2025-06-15
confidence: high
---

# Newsletter

Monthly email newsletter sent to subscribers with project updates, technical
insights, and community highlights.

## Workflow

- Draft content in [[Wiki/Content/Writing-Process]] using the standard template
- Review with at least one team member before sending
- Send via the newsletter platform on the first Monday of each month
- Archive the issue in [[Wiki/Content/Newsletter-Archive]]

## Audience

- Primary: existing clients and partners
- Secondary: developer community and tech leads
- Current subscriber count tracked in [[Wiki/Business/Metrics]]

## Tools

- [[Wiki/Tech/Email-Platform]] -- delivery and analytics
- [[Wiki/Tech/Markdown-Editor]] -- drafting and formatting

## Lessons Learned

- Plain-text subject lines outperform emoji-heavy ones (tested Q1 2025)
- Sending on Monday mornings yields ~20% higher open rates than Fridays
- See [[Wiki/Reference/Newsletter-Gotchas]] for common pitfalls
```

---

## What changed?

| Aspect              | Before                | After                                    |
|---------------------|-----------------------|------------------------------------------|
| Properties          | Missing `domain`, `confidence` | All required properties present  |
| Content depth       | 1 vague sentence      | Workflow, audience, tools, lessons        |
| Cross-references    | 0 links               | 6 `[[Wiki/...]]` links                   |
| Actionable insight  | None                  | Timing tips, testing results              |
| Hub page updated    | No                    | Yes (`[[Wiki/Content]]` now lists this page) |
