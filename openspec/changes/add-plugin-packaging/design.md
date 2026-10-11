# Design: Plugin packaging

Sources: Claude Code docs, "Plugin manifest reference" and "Create a marketplace"
(code.claude.com/docs/en/plugins-reference, /plugin-marketplaces), read 2026-10-11. The manifests
below were validated with `claude plugin validate . --strict` on Claude Code v2.1.296.

## Target layout

```text
llm-wiki/
├── .claude-plugin/
│   ├── plugin.json          # new
│   └── marketplace.json     # new
├── skills/
│   ├── wiki/
│   │   └── SKILL.md         # moved from wiki.md, plus frontmatter
│   └── setup/
│       └── SKILL.md         # new
├── scripts/
│   └── init-wiki.sh         # new, extracted from setup.sh steps 3 and 6-9
├── hooks/                   # reserved, not created by this change
├── templates/               # unchanged
├── setup.sh                 # interactive front end, calls scripts/init-wiki.sh
├── docs/  examples/  diagrams/  openspec/     # unchanged
└── README.md  CHANGELOG.md  config.example.yml
```

## Manifests

`.claude-plugin/plugin.json`:

```json
{
  "name": "llm-wiki",
  "displayName": "LLM Wiki",
  "version": "1.6.0",
  "description": "Persistent L1/L2 knowledge base in Logseq or Obsidian: ingest, query, prune, lint, status",
  "author": { "name": "Mehmet Goekce", "url": "https://github.com/MehmetGoekce" },
  "homepage": "https://github.com/MehmetGoekce/llm-wiki",
  "repository": "https://github.com/MehmetGoekce/llm-wiki",
  "license": "MIT",
  "keywords": ["knowledge-base", "wiki", "logseq", "obsidian", "memory"],
  "userConfig": {
    "wiki_path": {
      "type": "directory",
      "title": "Wiki root",
      "description": "Logseq graph or Obsidian vault that holds (or will hold) llm-wiki.yml",
      "required": true
    }
  }
}
```

`.claude-plugin/marketplace.json`:

```json
{
  "name": "mehmetgoekce",
  "description": "Plugins by Mehmet Goekce",
  "owner": { "name": "Mehmet Goekce" },
  "plugins": [
    {
      "name": "llm-wiki",
      "source": "./",
      "description": "Persistent L1/L2 knowledge base in Logseq or Obsidian"
    }
  ]
}
```

## Decisions

### D1: Plugin root is the repository root

| Option | For | Against |
|--------|-----|---------|
| **A. Repo root is the plugin** (`"source": "./"`) | Only `wiki.md` moves. `templates/`, `setup.sh` and every path in the docs stay where they are. | The whole repo, including `docs/`, `openspec/` and a 300 KB screenshot, is copied into each user's plugin cache. |
| B. Plugin in `plugins/llm-wiki/` | The cache holds only what runs. Room for a second plugin. | `templates/` and the skill move one level down; `setup.sh`, CONTRIBUTING and several docs need path changes. More churn for a repo that ships one plugin. |

**Chosen: A.** The repo is under 1 MB and ships one plugin. Moving to B later is possible without
changing the install id, because users address the plugin by entry name, not by path.

Consequence: links to `wiki.md` on `main` break. Mitigation: for v1.6.x a root `wiki.md` remains as
a five-line pointer to `skills/wiki/SKILL.md`; it is removed in v1.7.0. A plugin root must not
contain a `CLAUDE.md` (the validator warns), which the repo does not have.

### D2: The wiki root comes from `userConfig`, everything else from `llm-wiki.yml`

| Option | For | Against |
|--------|-----|---------|
| **A. `userConfig.wiki_path`** | Claude Code prompts for it on enable and substitutes `${user_config.wiki_path}` into the skill body. Explicit, no guessing. | One value per settings scope (proposal open question 2). |
| B. Search upward from the working directory for `llm-wiki.yml` | No configuration. | The wiki is usually not an ancestor of the project the user works in. |
| C. Environment variable | Works for the copied-skill path too. | The user edits shell config by hand; exactly the step a plugin should remove. |
| D. Duplicate all config keys in `userConfig` | Configurable from `/config`. | Two sources of truth; contradicts config.md REQ-600. |

**Chosen: A.** `userConfig` holds a pointer and nothing else. `tool`, `pages_dir`, `namespaces`,
`memory_path` and `l1_verify_days` stay in `llm-wiki.yml`, so a wiki directory remains
self-describing and portable.

The option avoids the `options` field, which would exclude Claude Code versions before v2.1.271.

For the copied-skill path, `setup.sh` replaces the literal string `${user_config.wiki_path}` in the
copy with the absolute wiki path. This is the step REQ-803 always described; it now has a
placeholder to act on.

### D3: One init script, two front ends

`setup.sh` mixes prompting with page creation. The setup skill cannot drive `read -p` prompts, and
re-implementing page creation as prompt instructions would make the result depend on the model.

`scripts/init-wiki.sh` takes everything as flags and prompts for nothing:

```text
init-wiki.sh --tool logseq|obsidian --wiki-path <dir> [--namespaces "A B C"]
             [--memory-path <dir>] [--git-init] [--commit]
```

It validates input, renders the templates with python3, writes `llm-wiki.yml`, and never overwrites
an existing page or config (existing behavior, setup.md REQ-786). Exit code 0 on success, 1 on
invalid input, with one line per created or skipped file on stdout.

- `setup.sh` keeps its prompts and calls the script with the answers.
- The setup skill asks the same questions in conversation and runs
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-wiki.sh" ...`. The variable is substituted in the skill
  body when the skill loads; it is not present in the Bash tool's environment, so the skill must
  use the substituted path literally.

### D4: Two skills, namespaced

| Skill | Invocation | Content |
|-------|------------|---------|
| `skills/wiki/SKILL.md` | `/llm-wiki:wiki <ingest\|query\|prune\|lint\|status\|import>` | The current `wiki.md`, unchanged below the frontmatter except for the config line. |
| `skills/setup/SKILL.md` | `/llm-wiki:setup` | Ask tool, namespaces, memory path, git; run `init-wiki.sh`; report. |

Setup is a separate skill so that the 28 KB wiki skill is not loaded for a one-time task, and the
setup instructions are not loaded on every ingest.

Specs and docs keep writing `/wiki ingest` etc. as the generic command name. README states once
that plugin users type `/llm-wiki:wiki` and copied-skill users type `/wiki`.

### D5: `plugin.json` carries the release version

Setting `version` pins users to that version until it changes, so a release that forgets the bump
ships nothing to plugin users. The release checklist gains two steps: bump `version` in
`plugin.json` to the CHANGELOG version, and run `claude plugin validate . --strict`. The marketplace
entry carries no version; the manifest's value would override it anyway.

## Risks

| Risk | Mitigation |
|------|------------|
| A release without a `version` bump reaches no plugin user | Checklist step (D5); lint-style check in a later change. |
| `directory`-typed option rejects a path that does not exist yet, blocking first-time setup | Verify in task 4.2. Fallback: type `string`, with the setup skill creating the directory. |
| Users run both the plugin and an old copied `/wiki` and get two different versions | README migration note; `/llm-wiki:setup` warns when it finds `.claude/commands/wiki.md` in the current project. |
| The plugin cache copy of the repo makes `${CLAUDE_PLUGIN_ROOT}` change on every update | Nothing is written there. State lives in the wiki directory only. |
