# Spec delta: Plugin packaging (new spec `specs/plugin.md`)

## Description

llm-wiki is distributed as a Claude Code plugin from its own repository, which also serves as the
marketplace. The plugin provides the wiki skill, a setup skill, and the init script both setup
paths share.

---

## ADDED Requirements

### Manifest

- REQ-830: The repository MUST contain `.claude-plugin/plugin.json` with `name` set to `llm-wiki`.
- REQ-831: The manifest MUST set `version`, `description`, `author.name`, `license` and
  `repository`.
- REQ-832: `version` in the manifest MUST equal the topmost released version in `CHANGELOG.md`.
- REQ-833: `claude plugin validate . --strict` MUST pass on the repository root before a release
  is tagged.
- REQ-834: The plugin root MUST NOT contain a `CLAUDE.md`.

### Marketplace

- REQ-840: The repository MUST contain `.claude-plugin/marketplace.json` with `name`, `owner.name`
  and one plugin entry named `llm-wiki` whose `source` is the repository root.
- REQ-841: The entry `name` MUST equal the manifest `name`.
- REQ-842: The marketplace entry MUST NOT declare components (`skills`, `commands`, `hooks`); the
  manifest and the standard layout are the only component sources.

### User configuration

- REQ-850: The manifest MUST declare exactly one `userConfig` option, `wiki_path`, of type
  `directory`, marked `required`.
- REQ-851: `userConfig` MUST NOT duplicate any key of `llm-wiki.yml` other than the wiki root
  (see config.md REQ-600).
- REQ-852: `userConfig` options MUST NOT use the `options` field while Claude Code versions before
  v2.1.271 are supported.

### Skills

- REQ-860: The wiki skill MUST live at `skills/wiki/SKILL.md` with frontmatter keys `name: wiki`
  and `description`.
- REQ-861: The wiki skill MUST name the config file as `${user_config.wiki_path}/llm-wiki.yml`
  and MUST NOT rely on inferring the wiki root from context.
- REQ-862: The setup skill MUST live at `skills/setup/SKILL.md` with frontmatter keys
  `name: setup` and `description`.
- REQ-863: The setup skill SHALL ask for tool, namespaces (with the default list), memory path
  (optional) and git initialization, then run `scripts/init-wiki.sh` with those values and
  `--wiki-path` set to the configured `wiki_path`.
- REQ-864: The setup skill MUST NOT create or edit wiki pages itself; page creation is the init
  script's job.
- REQ-865: If `llm-wiki.yml` already exists at `wiki_path`, the setup skill SHALL report that the
  wiki is already set up and make no changes unless the user asks to add missing pages.
- REQ-866: If the current project contains `.claude/commands/wiki.md`, the setup skill SHOULD warn
  that a copied skill and the plugin are both installed and name the file to delete.
- REQ-867: Skills MUST reference bundled files through `${CLAUDE_PLUGIN_ROOT}` in the skill body
  and MUST NOT assume the variable exists in the Bash tool's environment.

### Init script

- REQ-870: `scripts/init-wiki.sh` MUST run without prompting; all input arrives as flags.
- REQ-871: Required flags: `--tool` (`logseq` or `obsidian`) and `--wiki-path`. Optional:
  `--namespaces`, `--memory-path`, `--git-init`, `--commit`.
- REQ-872: Without `--namespaces` the script SHALL use the default list of setup.md REQ-740.
- REQ-873: The script SHALL create the pages and the config file as specified in setup.md
  REQ-780-792, and MUST NOT overwrite an existing page or an existing `llm-wiki.yml`.
- REQ-874: The script SHALL print one line per created or skipped file and exit 0 on success.
- REQ-875: On an invalid flag value, a missing required flag or a missing template directory the
  script SHALL print the reason to stderr and exit 1 before creating any file.
- REQ-876: The script MUST locate templates relative to its own location, not the working
  directory.
- REQ-877: The script MUST require only bash, python3 and, for `--git-init`/`--commit`, git.

### State

- REQ-880: The plugin MUST NOT write to `${CLAUDE_PLUGIN_ROOT}`. All state lives in the wiki
  directory.

---

## Scenarios

### Scenario 1: Fresh install through the plugin

```
GIVEN Claude Code with no llm-wiki installed
AND an empty directory ~/notes/wiki
WHEN the user adds the marketplace from MehmetGoekce/llm-wiki
AND installs llm-wiki and enters ~/notes/wiki as "Wiki root"
AND runs /llm-wiki:setup, choosing Obsidian, default namespaces, no memory path, git init
THEN ~/notes/wiki SHALL contain llm-wiki.yml with tool: obsidian
AND Wiki/Schema.md, Wiki/Dashboard.md, Wiki/Reference/Access-Log.md and 7 hub pages
AND a git repository with one commit
AND /llm-wiki:wiki status SHALL report the wiki without asking where it is
```

### Scenario 2: Plugin on an existing wiki

```
GIVEN a wiki created by setup.sh v1.5.1 at ~/Documents/Logseq
WHEN the user installs the plugin and enters ~/Documents/Logseq as "Wiki root"
AND runs /llm-wiki:setup
THEN the skill SHALL report that the wiki is already set up
AND no file in the wiki SHALL change
```

### Scenario 3: Use from an unrelated project

```
GIVEN the plugin is installed with wiki_path ~/notes/wiki
AND Claude Code runs in ~/code/some-project, which has no .claude/commands/wiki.md
WHEN the user runs /llm-wiki:wiki query "deployment checklist"
THEN the skill SHALL read ~/notes/wiki/llm-wiki.yml as its first operation
AND answer from the wiki
```

### Scenario 4: Init script rejects bad input

```
GIVEN an empty directory /tmp/w
WHEN init-wiki.sh --tool notion --wiki-path /tmp/w is run
THEN it SHALL print an error naming the invalid tool to stderr
AND exit 1
AND /tmp/w SHALL still be empty
```

### Scenario 5: Init script is idempotent

```
GIVEN init-wiki.sh --tool logseq --wiki-path /tmp/w has completed
WHEN the same command runs again
THEN every page SHALL be reported as skipped
AND llm-wiki.yml SHALL be unchanged
AND the exit code SHALL be 0
```

### Scenario 6: Release without version bump

```
GIVEN CHANGELOG.md lists 1.6.1 as the topmost release
AND plugin.json still says "version": "1.6.0"
WHEN the release checklist is run
THEN the REQ-832 check SHALL fail and the release SHALL NOT be tagged
```
