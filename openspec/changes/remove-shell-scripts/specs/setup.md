# Spec delta: Setup (replaces `specs/setup.md` in full)

The current spec describes `setup.sh`. With the script gone, the same output contract binds the
`setup` subcommand of the skill. Requirement numbers are kept where the meaning is kept, so links
from other specs stay valid. Marked per requirement: (unchanged), (MODIFIED), (ADDED), (REMOVED).

---

# Spec: Setup — Wiki Skeleton Creation

## Description

`/llm-wiki setup` (or `/wiki setup` in a copied skill) creates the initial pages (Schema,
Dashboard, one hub page per namespace, Access-Log), the config file `llm-wiki.yml` and, on request,
a git repository with a first commit. Claude asks the questions in the conversation, renders the
bundled templates and writes the files itself. No script is involved.

---

## Requirements

### Prerequisites

- REQ-700 (MODIFIED): Setup MUST need nothing but Claude Code with the Read, Write and Bash tools.
- REQ-701 (REMOVED): python3 is no longer required.
- REQ-702 (MODIFIED): git is needed only for git initialization and the first commit. If git is not
  available, both steps SHALL be skipped with a warning; setup continues.
- REQ-703 (unchanged): Setup MUST NOT require any package manager (npm, pip, etc.) or installed
  library.

### Step 1: Tool Selection

- REQ-710 (MODIFIED): Setup SHALL ask whether the wiki is a Logseq graph or an Obsidian vault. If
  the wiki root contains `logseq/` it SHALL suggest Logseq; if it contains `.obsidian/` it SHALL
  suggest Obsidian.
- REQ-711 (MODIFIED): On any other answer setup SHALL say which values are valid and ask again.
  Nothing is written before a valid answer.
- REQ-712 (unchanged): The tool choice determines ALL downstream behavior: file naming, property
  syntax, directory structure, template selection.

### Step 2: Wiki Root

- REQ-720 (MODIFIED): The wiki root is the configured one (config.md REQ-670). Setup MUST NOT ask
  for it and MUST NOT use another directory.
- REQ-721 (unchanged): A leading `~` SHALL be expanded to the user's home directory.
- REQ-722 (MODIFIED): If the wiki root does not exist, setup SHALL create it (`mkdir -p`) after all
  answers are valid. If the path exists and is not a directory, setup SHALL stop with an error
  naming the path and write nothing.

### Step 3: Pages Directory

- REQ-730 (unchanged): For Logseq, `pages_dir` SHALL be `pages`. For Obsidian, `pages_dir` SHALL be
  the empty string.
- REQ-731 (unchanged): A missing pages directory SHALL be created.

### Step 4: Namespaces

- REQ-740 (unchanged): Setup SHALL offer the default namespace list:
  Business, Tech, Content, Projects, People, Learning, Reference.
- REQ-741 (unchanged): The user MAY give a space-separated list of their own or accept the default.
- REQ-742 (MODIFIED): Namespace names MUST match `^[A-Za-z][A-Za-z0-9-]*$`. On any other name
  setup SHALL name the invalid entries and ask again. Title Case is recommended, not validated.
- REQ-745 (ADDED): Setup MUST validate every answer (tool, namespaces, wiki root, readable
  templates) before its first write. "Write" includes creating the wiki root, `git init` and every
  file.

### Step 5: Memory Path

- REQ-750 (MODIFIED): Setup SHALL ask for the Claude Code memory directory (L1), marked optional,
  with `~/.claude/projects/<project>/memory/` as the usual form.
- REQ-751 (unchanged): The user MAY skip it. If skipped, `memory_path` is empty in the config.
- REQ-752 (unchanged): A leading `~` SHALL be expanded.
- REQ-753 (unchanged): Setup does NOT check that the memory path exists.

### Step 6: Git Init

- REQ-760 (MODIFIED): If the wiki root has no `.git` directory, setup SHALL ask whether to
  initialize git there.
- REQ-761 (MODIFIED): On yes: run `git -C <root> init`, then write the tool-specific `.gitignore`
  unless a `.gitignore` already exists. A `.gitignore` written here counts as a created file
  (REQ-810).
- REQ-762 (unchanged): Logseq `.gitignore`, one entry per line in this order: `logseq/bak/`,
  `logseq/.recycle/`, `.DS_Store`, `.logseq/`.
- REQ-763 (unchanged): Obsidian `.gitignore`, in this order: `.obsidian/workspace.json`,
  `.obsidian/workspace-mobile.json`, `.DS_Store`, `.trash/`.
- REQ-764 (unchanged): On no: skip git initialization entirely.
- REQ-765 (unchanged): If `.git` already exists, skip this step without asking.

### Step 7: Templates

- REQ-770 (MODIFIED): Templates SHALL be read from `${CLAUDE_PLUGIN_ROOT}/templates/<tool>/`
  (`Schema.md`, `Dashboard.md`, `Hub.md`, `Access-Log.md`). In a copied skill the placeholder is
  replaced by the path of the repository clone (REQ-807).
- REQ-771 (MODIFIED): If a template cannot be read, setup SHALL stop with an error naming the path
  it tried and write nothing. If the path still contains the literal `${CLAUDE_PLUGIN_ROOT}`, the
  message SHALL say that a copied skill needs the clone path substituted (README).

### Step 8: Page Creation

- REQ-780 (MODIFIED): Setup SHALL render each template by literal replacement of its placeholders
  and write the result with the Write tool.
- REQ-780a (ADDED): Apart from the placeholders, the written file MUST be identical to the
  template: same characters, line breaks, indentation (including tab characters) and trailing
  newline. Setup MUST NOT reformat, translate, shorten or complete template text.
- REQ-781 (MODIFIED): Placeholder values:
  - `{{DATE}}`: today as `YYYY-MM-DD`, taken once from `date +%Y-%m-%d` and used for every file.
  - `{{NAMESPACES}}`: `Wiki/<ns>` for each namespace in the given order, joined by `, `.
  - `{{NAMESPACE}}`: the namespace name of the hub page being written.
  - `{{NAMESPACE_LINKS}}`: one line per namespace, `<prefix>[[Wiki/<ns>]]`, joined by a single
    newline with no newline after the last line. The prefix is a tab followed by `- ` for Logseq
    and `- ` for Obsidian.
- REQ-782 (unchanged): Setup SHALL create, in this order: the Schema page, the Dashboard page, one
  hub page per namespace in the given order, and the Access-Log page under the Reference namespace.
- REQ-783 (MODIFIED): Logseq: all pages flat in `pages/`, named `Wiki___<name>.md`, where every `/`
  in the page name becomes `___` (`pages/Wiki___Schema.md`, `pages/Wiki___Tech.md`,
  `pages/Wiki___Reference___Access-Log.md`).
- REQ-784 (MODIFIED): Obsidian: `Wiki/Schema.md`, `Wiki/Dashboard.md`, `Wiki/<ns>/_index.md` per
  namespace, `Wiki/Reference/Access-Log.md`.
- REQ-785 (unchanged): Parent directories SHALL be created as needed.
- REQ-786 (MODIFIED): Setup MUST NOT overwrite an existing file. It SHALL check every target path
  for existence before writing and skip the ones that exist. Relying on the Write tool to refuse is
  not sufficient.
- REQ-787 (ADDED): Setup SHALL report one line per target: `Created: <label>` or
  `Skipped (already exists): <label>`. The label is `Wiki/<name>` for Logseq pages, the relative
  path for Obsidian pages, and `llm-wiki.yml` for the config.

### Step 9: Config File

- REQ-790 (MODIFIED): Setup SHALL create `llm-wiki.yml` in the wiki root as the last file. An
  existing `llm-wiki.yml` is never replaced (plugin.md REQ-865 handles a configured wiki).
- REQ-791 (MODIFIED): The config SHALL have exactly this form, with a trailing newline. An empty
  value is written as the key and colon with nothing after it (`pages_dir:`). v1.7.1 wrote a
  trailing space there; both parse as an empty value.

  ```
  # llm-wiki configuration
  # Generated by llm-wiki on <DATE>

  tool: <logseq|obsidian>
  wiki_path: <absolute wiki root, no trailing slash>
  pages_dir: <pages_dir>
  memory_path: <memory path or empty>

  namespaces:
    - <namespace 1>
    - <namespace n>
  ```
- REQ-792 (unchanged): The header comment carries the generation date.

### Step 10: Install without the plugin

- REQ-800 to REQ-806 (REMOVED): there is no installer that copies the skill.
- REQ-807 (ADDED): The README SHALL describe the install without the plugin: copy `SKILL.md` to
  `<project>/.claude/commands/wiki.md`; replace every `${user_config.wiki_path}` with the absolute
  wiki root and every `${CLAUDE_PLUGIN_ROOT}` with the absolute path of the clone; run
  `/wiki setup`. It SHALL say that the copy does not update itself and that the plugin is the
  recommended path.

### Step 11: First Commit

- REQ-810 (MODIFIED): If the wiki root is a git repository (initialized in Step 6 or before) and
  this run created at least one file, setup SHALL stage exactly the created files by path
  (`git -C <root> add -- <paths>`) and commit them. It MUST NOT stage anything else.
- REQ-811 (MODIFIED): The commit message SHALL be:

  ```
  wiki: initial setup via llm-wiki

  Schema, Dashboard, and hub pages for <N> namespaces.
  Tool: <tool>

  Generated by https://github.com/MehmetGoekce/llm-wiki
  ```
- REQ-812 (unchanged): A failed commit SHALL NOT abort setup; it SHALL warn and leave the files
  uncommitted.

### Report

- REQ-820 (MODIFIED): Setup SHALL end with the created and skipped files, the path of
  `llm-wiki.yml`, and the next steps: open the wiki in the chosen tool, run
  `/llm-wiki ingest "<a first source>"`, run `/llm-wiki status`.
- REQ-821 (REMOVED): merged into REQ-820; the plugin install hint was specific to `setup.sh`.

---

## Scenarios

### Scenario 1: Logseq, new directory, defaults

```
GIVEN the plugin is installed with wiki root ~/Documents/TestWiki, which does not exist
WHEN the user runs /llm-wiki setup and answers Logseq, default namespaces,
     memory path ~/.claude/projects/test/memory/, git init yes
THEN ~/Documents/TestWiki/pages/ SHALL contain 10 pages: Schema, Dashboard, Access-Log
     and 7 hub pages
AND llm-wiki.yml SHALL contain tool: logseq, pages_dir: pages and the memory path
AND .gitignore SHALL have the four Logseq entries
AND git log SHALL show one commit with the 12 created files
```

### Scenario 2: Obsidian, existing vault with git

```
GIVEN ~/Documents/ObsidianVault/ exists with .obsidian/ and .git/
AND the vault has an uncommitted change in Notes/todo.md
WHEN the user runs /llm-wiki setup, accepts the suggested Obsidian, default namespaces,
     no memory path
THEN setup SHALL NOT ask about git
AND create Wiki/Schema.md, Wiki/Dashboard.md, Wiki/Reference/Access-Log.md,
    7 Wiki/<ns>/_index.md files and llm-wiki.yml with an empty memory_path
AND commit exactly those 11 files
AND Notes/todo.md SHALL still be uncommitted
```

### Scenario 3: Wiki root is a file

```
GIVEN the configured wiki root ~/wiki.txt is a regular file
WHEN the user runs /llm-wiki setup and answers all questions
THEN setup SHALL stop with an error naming ~/wiki.txt
AND nothing SHALL be written
```

### Scenario 4: Invalid tool answer

```
WHEN the user answers "Notion" to the tool question
THEN setup SHALL name Logseq and Obsidian as the valid answers and ask again
AND nothing SHALL be written
```

### Scenario 5: git not installed

```
GIVEN git is not on PATH
WHEN the user runs /llm-wiki setup on a new directory
THEN setup SHALL warn that git steps are skipped
AND create all pages and llm-wiki.yml
AND create no .gitignore
```

### Scenario 6: Templates missing in a copied skill

```
GIVEN a copied skill in which ${CLAUDE_PLUGIN_ROOT} was not replaced
WHEN the user runs /wiki setup
THEN setup SHALL stop before writing
AND say that the clone path has to be substituted, pointing to the README
```

### Scenario 7: Second run adds nothing

```
GIVEN setup completed for a Logseq wiki, and the user deleted llm-wiki.yml afterwards
WHEN the user runs /llm-wiki setup again with the same answers
THEN every page SHALL be reported as "Skipped (already exists)"
AND llm-wiki.yml SHALL be reported as created
AND no page SHALL change
```

### Scenario 8: Custom namespaces

```
WHEN the user enters "Engineering Sales Support" for namespaces
THEN setup SHALL create 3 hub pages:
    - Wiki___Engineering.md (Logseq) or Wiki/Engineering/_index.md (Obsidian)
    - Wiki___Sales.md or Wiki/Sales/_index.md
    - Wiki___Support.md or Wiki/Support/_index.md
AND the Schema page SHALL list "Wiki/Engineering, Wiki/Sales, Wiki/Support"
AND llm-wiki.yml SHALL list these 3 namespaces
AND the Access-Log page SHALL still be created under Wiki/Reference, although Reference is not
    in the list
```

### Scenario 9: Git init declined

```
GIVEN the wiki root has no .git/
WHEN the user declines git initialization
THEN no .git directory and no .gitignore SHALL be created
AND no commit SHALL be attempted
```

### Scenario 10: Invalid namespace

```
WHEN the user enters "Tech 2024-Archive my_notes" for namespaces
THEN setup SHALL name "2024-Archive" and "my_notes" as invalid and ask again
AND nothing SHALL be written
```

### Scenario 11: Same output as init-wiki.sh v1.7.1

```
GIVEN two empty directories A and B
WHEN scripts/init-wiki.sh from a checkout of tag v1.7.1 is run for A with --tool <t> and namespaces N
AND /llm-wiki setup is run for B with tool <t>, namespaces N, no memory path, no git, on the same day
THEN the file lists of A and B SHALL be identical
AND every file SHALL be byte-identical, except in llm-wiki.yml the wiki_path line and the
    trailing space after an empty value (REQ-791)
(run for t = logseq and t = obsidian, N = default and N = "Engineering Sales Support")
```

---

## Acceptance Criteria

- [ ] Needs only Claude Code; git optional, no python3, no package manager
- [ ] Tool choice determines all downstream behavior; Logseq/Obsidian suggested from the directory
- [ ] No write before all answers are valid; invalid answers are asked again
- [ ] Created files byte-identical to init-wiki.sh v1.7.1 (Scenario 11, both tools)
- [ ] Logseq: flat files with triple-underscore naming; Obsidian: `Wiki/<ns>/_index.md` hubs
- [ ] Existing files never overwritten; one created/skipped line per target
- [ ] Config has the exact form of REQ-791
- [ ] Git init optional, tool-specific .gitignore, commit holds only created files
- [ ] README documents the install without the plugin

---

## Dependencies

- Templates: `templates/logseq/{Schema,Hub,Dashboard,Access-Log}.md` and
  `templates/obsidian/{Schema,Hub,Dashboard,Access-Log}.md`
- specs/plugin.md defines the `setup` subcommand (REQ-863-866)
- specs/config.md defines the wiki root resolution and the format of `llm-wiki.yml`
- specs/schema.md defines what the generated Schema page contains
