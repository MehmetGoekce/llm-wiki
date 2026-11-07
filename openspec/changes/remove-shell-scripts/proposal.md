# Change: Remove the shell scripts from the plugin

- **Change ID:** `remove-shell-scripts`
- **Status:** Proposed (2026-11-07)
- **Release:** v1.8.0 (minor: the setup subcommand creates the same wiki by a different route;
  `setup.sh` is removed). See Open questions 1.
- **Affected specs:** `specs/plugin.md` (Skill, Init script), `specs/setup.md` (rewritten for the
  setup subcommand), `specs/config.md` (REQ-670, REQ-671)

## Why

Anthropic's plugin directory refused v1.7.1 (commit `11538c1`) on 2026-11-07:

> Files outside the allowed types accepted only from Verified organizations. [...] Remove each file
> that, whatever its name, isn't Markdown, text, JSON, YAML, or a PNG, JPEG, GIF, WebP, or ICO
> image, each that starts with `#!`, and each package manager configuration file [...]

The account that submitted llm-wiki is not a Verified organization. The plugin source is the
repository root, so every tracked file is part of the plugin. Two files break the rule, both
because they start with `#!`:

| File | Role today |
|------|-----------|
| `scripts/init-wiki.sh` | Creates pages, config, `.gitignore` and the first commit. `SKILL.md` runs it in `/llm-wiki setup` Phase 3. |
| `setup.sh` | Interactive installer for installs without the plugin; asks questions, calls the init script, can copy the skill into a project. |

Every other tracked file is Markdown, JSON, YAML, PNG, `LICENSE`, `.gitignore` or plain-text
Mermaid (`diagrams/*.mmd`), all UTF-8 without NUL bytes.

The same check reported "Unrecognized field in plugin.json" three times. The fields are listing
metadata added after v1.7.1 was tagged (`[Unreleased]` in the CHANGELOG).

## What changes

- **`/llm-wiki setup` creates the wiki itself.** The skill reads the templates from
  `${CLAUDE_PLUGIN_ROOT}/templates/<tool>/`, substitutes the placeholders and writes each file with
  the Write tool. `git init` and the first commit run as plain `git` commands through Bash. The
  result is byte-identical to what `init-wiki.sh` v1.7.1 creates (design.md D1, D3).
- **`scripts/init-wiki.sh` and `setup.sh` are deleted.** No replacement script in this repository
  (design.md D2).
- **Install without the plugin** becomes a documented manual step in the README: copy `SKILL.md` to
  `<project>/.claude/commands/wiki.md`, replace the two placeholders, run `/wiki setup`.
- **Manifest cleanup:** the fields the directory does not recognize are removed from
  `.claude-plugin/plugin.json`, and the `[Unreleased]` line that says they are "shown on the
  directory listing" is corrected.
- Specs, README, CONTRIBUTING, FAQ, troubleshooting, security policy and issue/PR templates stop
  referring to the scripts.

## What does not change

- The wiki a setup produces: file names, file contents, `llm-wiki.yml`, `.gitignore`, the commit
  message and the rule that only created files are committed.
- The setup questions and their defaults, the existing-config check (plugin.md REQ-865) and the
  copied-skill warning (REQ-866).
- All other subcommands (ingest, query, lint, prune, status, import), the schema, the Access-Log
  format and the templates.
- Logseq and Obsidian parity.
- Existing installs: plugin users get the change as an update; a copied `/wiki` skill keeps working
  as it is.

## Out of scope

- Applying for Verified organization status. If it is granted later, scripts could come back; that
  would be a separate change.
- Moving `setup.sh` into a separate installer repository (design.md D2, rejected alternative).
- The untracked `openspec/changes/add-learn/` change.

## Impact

| Who | Effect |
|-----|--------|
| Plugin users | None visible. `/llm-wiki setup` asks the same questions and creates the same files. |
| Users of a copied `/wiki` skill | Nothing breaks. A new copy is made by hand (README) instead of by `setup.sh`. |
| Users who ran `./setup.sh` from a clone | The script is gone. Install the plugin, or copy the skill by hand. |
| Contributors | No script to test against; setup is verified with the parity test (tasks.md 3). The zero-dependency rule shrinks to: git optional, nothing else. |
| Directory submission | The merge to `main` pushes a new commit, which the directory checks again. |

## Open questions for the maintainer

1. **Version number.** Removing `setup.sh` removes a documented install path. Strict SemVer reads
   that as breaking (2.0.0). Proposed is 1.8.0: the plugin's interface (`/llm-wiki` subcommands,
   `userConfig`, `llm-wiki.yml`, wiki format) is unchanged, and v1.7.0 already handled a removed
   entry point as a minor release with a Migration section.
2. **Which three fields are unrecognized.** Candidates: `documentationUrl`, `supportUrl`,
   `privacyPolicyUrl`, `displayName`. The exact list is under "Other findings from the automatic
   checks" in the portal's Review tab and is needed before tasks.md 4.1.
