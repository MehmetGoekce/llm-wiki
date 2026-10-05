# AI Agent Instructions — llm-wiki

## Role

You are implementing or extending the llm-wiki system. This is an open-source project
that provides a structured knowledge management system for LLM assistants.

## Before Writing Code

1. Read `openspec/project.md` for architecture, constraints, and tech stack
2. Read the relevant `openspec/specs/*.md` file for the feature you are working on
3. Understand ALL SHALL/MUST requirements before making changes
4. Review BDD scenarios — these are your acceptance criteria

## Key Architectural Rules

- **Tool-agnostic:** Every feature MUST work in both Logseq and Obsidian modes
- **Zero dependencies:** Only bash, python3, and git. No npm, no pip, no Docker
- **No deletion:** New facts are appended. A fact that supersedes a stated state rewrites
  that block in place; the old wording moves, dated, into its collapsed History child
  (ingest.md REQ-032, REQ-032a/b)
- **L1/L2 separation:** Credentials in L1 only. Wiki (L2) is git-tracked
- **JIT retrieval:** Max 3 wiki pages loaded at once

## Format Rules

- **Logseq:** Every line prefixed with `- `, properties as `property:: value`
- **Obsidian:** Standard markdown, properties as YAML frontmatter
- **Both:** `[[Wiki/Namespace/Page]]` link syntax, ISO 8601 dates

## Implementation Rules

- Each feature branch maps to one spec file
- Commit messages reference the spec: `feat: implement ingest phase 3 (ingest.md REQ-030-039)`
- SHALL/MUST requirements are non-negotiable
- SHOULD requirements: implement unless there is a documented reason not to
- Test both Logseq and Obsidian modes before merging

## Testing

- No test framework (zero-dependency constraint)
- Manual verification via setup.sh with test directories
- BDD scenarios from specs serve as manual test scripts
- Each scenario describes: precondition, action, expected result
- Verify both tool modes for every change

## File Map

| File | Purpose |
|------|---------|
| `wiki.md` | /wiki skill definition (the prompt Claude Code executes) |
| `setup.sh` | Interactive installer |
| `config.example.yml` | Configuration template |
| `docs/` | Architecture docs, schema reference |
| `templates/logseq/` | Logseq page templates (Schema, Hub, Dashboard) |
| `templates/obsidian/` | Obsidian page templates |
| `examples/` | Before/after examples, L1 memory samples |
| `diagrams/` | Mermaid architecture diagrams |
