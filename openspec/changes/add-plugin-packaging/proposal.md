# Change: Package llm-wiki as a Claude Code plugin

- **Change ID:** `add-plugin-packaging`
- **Status:** Proposed
- **Target release:** v1.6.0 (minor: new install path, no behavior change in the wiki workflows)
- **Affected specs:** new `specs/plugin.md`; deltas to `specs/setup.md` and `specs/config.md`

## Why

Installing llm-wiki today means `git clone`, running `setup.sh`, and letting it copy `wiki.md`
into one project's `.claude/commands/`. That has three costs:

1. **No update path.** A new release reaches a user only if they pull the repo and copy `wiki.md`
   again. Most installs stay on the version they were cloned at.
2. **One project per install.** The skill is copied per project; a second project needs a second
   copy that drifts from the first.
3. **The skill does not know where the wiki is.** `setup.sh` patches a `<CONFIG_PATH>` placeholder
   into the copied skill (setup.md REQ-803), but `wiki.md` contains no such placeholder. The `sed`
   call is a no-op, and the skill only says "read `llm-wiki.yml` from the wiki root directory".
   It works when Claude can infer the root from context and fails otherwise
   (`docs/troubleshooting.md` already carries an entry for this).

A Claude Code plugin solves all three: one install command, updates through the marketplace, a
user-level install that works in every project, and a `userConfig` value that gives the skill the
wiki root explicitly.

## What changes

- The repository becomes a **plugin and its own marketplace**: `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` at the repo root.
- `wiki.md` moves to `skills/wiki/SKILL.md` and gains skill frontmatter. Plugin users invoke it as
  `/llm-wiki:wiki <subcommand>`.
- A second skill, `skills/setup/SKILL.md` (`/llm-wiki:setup`), creates the wiki skeleton from inside
  Claude Code.
- The page-creation and config-writing logic of `setup.sh` moves into a non-interactive script,
  `scripts/init-wiki.sh`. Both `setup.sh` and the setup skill call it, so there is one
  implementation with two front ends.
- The plugin declares one `userConfig` option, `wiki_path`. The skill reads
  `${user_config.wiki_path}/llm-wiki.yml`. `llm-wiki.yml` stays the single source of truth for
  everything else.
- `setup.sh` keeps working as the install path without a plugin. Its skill-copy step now
  substitutes a placeholder that exists.
- README Quick Start leads with the plugin install; the clone path moves to a second section.

## What does not change

- The wiki workflows (ingest, query, prune, lint, status, import), the schema, the Access-Log format
  and the L1 frontmatter. The skill body is moved, not rewritten.
- The zero-dependency constraint: bash, python3, git.
- Logseq and Obsidian parity.

## Out of scope (separate changes)

- A `SessionStart` hook that reports due L1 claims (the roadmap item from v1.4.0). This change only
  reserves `hooks/` in the layout.
- A deterministic lint script.
- Splitting the skill into a short `SKILL.md` plus per-workflow reference files.
- Submission to Anthropic's plugin directory. It should follow once the hook and the lint script
  exist; the directory listing fields in `plugin.json` are left out until then.
- Removing `setup.sh`.

## Impact

| Who | Effect |
|-----|--------|
| New users | `claude plugin marketplace add MehmetGoekce/llm-wiki`, `claude plugin install llm-wiki@mehmetgoekce`, then `/llm-wiki:setup`. |
| Existing users (copied `wiki.md`) | Nothing breaks. Their copy keeps working as `/wiki`. To move to the plugin: install it, point `wiki_path` at the existing wiki, delete the copied `.claude/commands/wiki.md`. |
| Contributors | `wiki.md` is now `skills/wiki/SKILL.md`. Releases bump `version` in `plugin.json` together with `CHANGELOG.md`. |
| Links from outside | Links to `wiki.md` on `main` break. Mitigation in design.md, decision D1. |

## Decided

- **Marketplace name: `mehmetgoekce`** (2026-10-11). It is the part after `@` in the install id
  and cannot be renamed without breaking existing installs. It matches the GitHub owner and leaves
  room for further plugins.

## Open questions for the maintainer

1. **Minimum Claude Code version.** The manifest passes `claude plugin validate --strict` on
   v2.1.296. The lowest version that supports a `directory`-typed `userConfig` option has not been
   determined; README should state the version the release was tested on.
2. **Several wikis on one machine.** `userConfig` holds one `wiki_path`. Whether a project-level
   settings file can override it per project needs a test before the README promises it.
