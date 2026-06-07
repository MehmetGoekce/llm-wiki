# Frequently Asked Questions

Questions that come up when evaluating whether llm-wiki is the right tool for you.

## What does llm-wiki actually do that a plain Logseq or Obsidian setup doesn't?

A plain Logseq or Obsidian setup is a manual knowledge base. You decide what to capture, you write the pages, you maintain the links, and you fix the inconsistencies. The quality of the wiki degrades as your effort drops.

llm-wiki turns Claude Code into the wiki maintainer. You feed it raw sources (URLs, files, chat transcripts), and it extracts entities, creates or updates 5-15 pages per ingest, adds cross-references between them, and enforces a schema so every page follows the same structure. A `/wiki lint` command continuously checks for broken links, stale content, missing properties, and credential leaks.

The wiki app (Logseq or Obsidian) is still where you *read* the knowledge. The difference is who does the writing.

## Do I need a paid Claude plan?

Yes. llm-wiki assumes you are using [Claude Code](https://claude.ai/code), which requires an Anthropic account and a paid plan (Pro or higher). All `/wiki` commands run through Claude Code — there are no external API calls, no vector databases, no separate ingest servers.

Claude Code itself is the only dependency. There is no additional cost for llm-wiki beyond your existing Claude plan.

## Why two layers (L1 and L2)? Isn't one enough?

If everything lives in one place, you face a dilemma: either the LLM loads the entire wiki into every session (blowing up the context window) or it queries the wiki per question (too slow for simple rules like "always use ISO 8601 dates").

Splitting knowledge into L1 (auto-loaded, always present) and L2 (on-demand) solves this. Operational rules and gotchas live in L1. Deep project knowledge lives in L2. The LLM has instant access to both, but the context window stays lean.

It feels overengineered at first. After a week of use, the boundary becomes second nature. See [docs/l1-l2-architecture.md](l1-l2-architecture.md) for the full rationale.

## Logseq or Obsidian — which should I choose?

If you already use one, stick with it. llm-wiki supports both equally, and migration between them is not trivial (different file-naming conventions).

If you are starting fresh, the short version:

- **Logseq** for LLM-heavy workflows. Outliner format means every line is an addressable block, so the LLM can append without disturbing existing structure.
- **Obsidian** for human-heavy workflows. Flat markdown is nicer to read and edit by hand, and the plugin ecosystem is huge.

See [docs/logseq-vs-obsidian.md](logseq-vs-obsidian.md) for the full comparison.

## Can I ingest my existing notes?

Yes, but not with a single command yet. For now:

1. Run `./setup.sh` to create the schema and namespace structure in a fresh wiki location.
2. Use `/wiki ingest <path-to-existing-note>` to process notes one at a time. The LLM extracts entities, fits them into your schema, and creates cross-references.
3. Iterate — Claude will ask clarifying questions for ambiguous content.

Bulk migration tooling is on the roadmap. For now, ingesting 20-50 notes manually is the common path.

## Can I use this with ChatGPT or Gemini instead of Claude?

Not currently. The `/wiki` commands rely on Claude Code's skill system and memory architecture. The ingest pipeline, lint rules, and query synthesis are specified against Claude's behavior.

Porting to other CLI-based LLM coding tools is on the roadmap but requires significant work — not just the command layer, but the L1 memory semantics and the append-only page discipline.

## What is the difference between this and Karpathy's original gist?

Karpathy's gist is a concept essay. It describes *what* an LLM wiki should do (ingest, query, lint) and why it matters. It does not specify tools, file formats, schemas, or workflows.

llm-wiki is an implementation. It picks Claude Code as the LLM, Logseq or Obsidian as the wiki UI, defines a concrete schema with 5 page types, specifies 11 lint rules with auto-fix behavior, and adds the L1/L2 cache layer — with two-stage hub-index routing and LRU eviction — that the gist does not mention. Setup takes 5 minutes with `./setup.sh`; the gist is 100% design, 0% code.

If you want the pure concept, read the gist. If you want a working system, use llm-wiki.

## At what wiki size does this become worth the overhead?

The schema and lint rules feel like overhead at under 20 pages — you could maintain 20 notes by hand. Past 50 pages, the structure starts paying for itself. Past 200, maintaining the wiki without automation is essentially impossible — which is what the two-stage hub-index routing (keeps retrieval precise) and `/wiki prune` (evicts cold pages from the index) are for.

The useful mental model: set up llm-wiki when you expect to cross 50 pages within 6 months. Below that threshold, plain notes are fine.

## How do I prevent credentials from ending up in the wiki?

Credentials must live in L1 (Claude Code memory), never in L2 (the wiki). The wiki is typically git-tracked, which means anything in L2 could be published accidentally.

Three layers of protection:

1. **Schema rule.** The schema explicitly states credentials go in L1 only.
2. **Lint rule #6 (credential-leak).** `/wiki lint` scans every page for `token::`, `password::`, `secret::`, `api-key::`, and base64 patterns. Critical severity — blocks commits.
3. **Ingest quality gate.** Phase 4 of the ingest pipeline aborts before writing if credentials are detected in the extracted content.

If a credential slips through despite this, `/wiki lint --fix` will flag it and refuse to auto-repair (so it does not remove it silently). You remove it manually, rotate the credential, and move the reference to L1.

## How do I commit the wiki to GitHub safely?

Three checks before your first push:

1. **Run `/wiki lint` and confirm zero credential warnings.** Critical severity issues must be resolved first.
2. **Verify your memory directory is in `.gitignore`.** The Claude Code `memory/` path (typically `~/.claude/projects/*/memory/`) must be excluded — it contains credentials and personal data.
3. **Review the first commit diff manually.** One-time sanity check that no API tokens or personal notes made it into tracked files.

After the first push, the L1/L2 boundary enforces itself. The lint runs catch drift before it reaches GitHub.

## Where do I report bugs or request features?

[GitHub Issues](https://github.com/MehmetGoekce/llm-wiki/issues) — there are templates for bug reports and feature requests. Security issues: see [SECURITY.md](../SECURITY.md).
