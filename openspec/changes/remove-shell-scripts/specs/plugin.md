# Spec delta: Plugin packaging (`specs/plugin.md`)

## Description (MODIFIED)

llm-wiki is distributed as a Claude Code plugin from its own repository, which also serves as the
marketplace. The plugin is a single root skill, invoked as `/llm-wiki <subcommand>`, plus the page
templates the `setup` subcommand renders. It contains no executable files.

---

## ADDED Requirements

### Directory file policy

- REQ-835: Every tracked file MUST be Markdown, plain text, JSON, YAML, or a PNG, JPEG, GIF, WebP
  or ICO image, saved as UTF-8 without NUL bytes where it is text. `LICENSE` and `.gitignore` count
  as plain text.
- REQ-836: No tracked file MAY start with `#!`, and the repository MUST NOT contain package manager
  configuration files (`package.json`, `pnpm-workspace.yaml`, `requirements.txt` and the like).
- REQ-837: `SKILL.md` MUST NOT embed a program for the Bash tool to run in place of a removed
  script (for example a `python3 -c` or heredoc program). Single commands (`git`, `date`, `test`,
  `ls`, `mkdir`) are allowed.

Reason: Anthropic's plugin directory accepts other files only from Verified organizations
(refusal of v1.7.1 on 2026-11-07).

## MODIFIED Requirements

### Skill

- REQ-863: The `setup` subcommand SHALL ask for tool, namespaces (with the default list), memory
  path (optional) and git initialization, then create the wiki skeleton in the configured
  `wiki_path` as specified in setup.md.
- REQ-864: The `setup` subcommand SHALL create pages and the config only as specified in setup.md
  REQ-780-792 and MUST NOT create or edit any other wiki page.
- REQ-867: The skill MUST reference bundled files (the templates) through `${CLAUDE_PLUGIN_ROOT}`
  in the skill body and MUST NOT assume the variable exists in the Bash tool's environment.

### Manifest

- REQ-831: The manifest MUST set `version`, `description`, `author.name`, `license` and
  `repository`, and MUST NOT contain fields the plugin directory reports as unrecognized.

## REMOVED Requirements

### Init script

- REQ-870 to REQ-877: `scripts/init-wiki.sh` is deleted. Its output contract moved to setup.md
  (REQ-745, REQ-780a, REQ-781-791, REQ-810-811).

---

## Scenarios

### Scenario 1: Fresh install through the plugin (MODIFIED: unchanged text, setup no longer runs a script)

### Scenario 4: Init script rejects bad input (REMOVED, replaced by setup.md Scenarios 3, 4, 10)

### Scenario 5: Init script is idempotent (REMOVED, replaced by setup.md Scenario 7)

### Scenario 7: Directory file policy (ADDED)

```
GIVEN the repository at the release commit
WHEN every tracked file is checked for its type, its first two bytes and its encoding
THEN no file SHALL start with "#!"
AND every file SHALL be Markdown, text, JSON, YAML or an allowed image
AND every text file SHALL be UTF-8 without NUL bytes
```

---

## Acceptance Criteria (MODIFIED)

- [ ] `claude plugin validate . --strict` passes on the repository root
- [ ] Manifest version equals the topmost CHANGELOG release; no unrecognized manifest fields
- [ ] Plugin installs from the repository as `llm-wiki@mehmetgoekce` with the single skill `llm-wiki`
- [ ] `/llm-wiki <subcommand>` reaches the skill with its arguments; no `skills/` directory exists
- [ ] The skill reads the config from the configured wiki root without asking
- [ ] `/llm-wiki setup` creates exactly the files of setup.md, byte-identical to v1.7.1
- [ ] No executable or shebang file in the repository (Scenario 7)
- [ ] Nothing is written to the plugin directory

## Dependencies (MODIFIED)

- specs/setup.md defines the pages and config file the `setup` subcommand creates
- specs/config.md defines how the wiki root and `llm-wiki.yml` are resolved
- Claude Code plugin manifest and marketplace format (code.claude.com/docs/en/plugins-reference)
