# Spec: setup.sh — Interactive Installer

## Description

The setup script is the entry point for users who install without the plugin. It
asks for tool, wiki path, namespaces, memory path and git, then calls
`scripts/init-wiki.sh` (specs/plugin.md REQ-870-877) to create the initial pages
(Schema, Dashboard, Hub pages, Access-Log) and the config file, and optionally copies
the /wiki skill into one Claude Code project. It requires only bash, python3, and git.

The requirements for page creation, config generation, git init and the initial commit
(Steps 3 and 6-9, 11) bind the init script; `setup.sh` collects the answers and passes
them on.

---

## Requirements

### Prerequisites

- REQ-700: The system MUST require bash (any version supporting `read -p`).
- REQ-701: The system MUST require python3. If python3 is not available, the
  system SHALL display an error and exit.
- REQ-702: The system MUST require git for the optional git init step.
  If git is not available, git-related steps SHALL be skipped with a warning.
- REQ-703: The system MUST NOT require any package manager (npm, pip, etc.)
  or any installed libraries beyond the standard library.

### Step 1: Tool Selection

- REQ-710: The system SHALL prompt the user to choose between Logseq (1) and
  Obsidian (2).
- REQ-711: If the user enters a value other than 1 or 2, the system SHALL
  display an error and exit.
- REQ-712: The tool choice determines ALL downstream behavior: file naming,
  property syntax, directory structure, template selection.

### Step 2: Wiki Path

- REQ-720: The system SHALL prompt for the wiki/vault root path with a
  tool-specific default (`~/Documents/Logseq` or `~/Documents/ObsidianVault`).
- REQ-721: The system SHALL expand `~` to `$HOME` in the provided path.
- REQ-722: If the path does not exist, the system SHALL ask "Create it? [y/n]".
  On "y": create with `mkdir -p`. On "n": exit with error.

### Step 3: Pages Directory

- REQ-730: For Logseq, `pages_dir` SHALL be set to `pages`.
  For Obsidian, `pages_dir` SHALL be set to empty string.
- REQ-731: If the pages directory does not exist, the system SHALL create it
  with `mkdir -p`.

### Step 4: Namespaces

- REQ-740: The system SHALL offer a default namespace list:
  Business, Tech, Content, Projects, People, Learning, Reference.
- REQ-741: The user MAY enter a custom space-separated list or press Enter
  to accept defaults.
- REQ-742: Namespace names MUST start with a letter and contain only letters,
  numbers and hyphens. On any other name the system SHALL display an error and
  exit before creating pages. Title Case is recommended, not validated.

### Step 5: Memory Path

- REQ-750: The system SHALL prompt for the Claude Code memory directory path.
- REQ-751: The user MAY skip this step by pressing Enter or entering "skip". If
  skipped, `memory_path` is empty in the generated config.
- REQ-752: The system SHALL expand `~` to `$HOME` in the provided path.
- REQ-753: The system does NOT validate that the memory path exists (it may
  be created later by Claude Code).

### Step 6: Git Init

- REQ-760: If the wiki directory does not have a `.git` directory, the system
  SHALL ask "Initialize git? [y/n]".
- REQ-761: On "y": run `git init`, create tool-specific `.gitignore`.
- REQ-762: Logseq `.gitignore` SHALL include: `logseq/bak/`, `logseq/.recycle/`,
  `.DS_Store`, `.logseq/`.
- REQ-763: Obsidian `.gitignore` SHALL include: `.obsidian/workspace.json`,
  `.obsidian/workspace-mobile.json`, `.DS_Store`, `.trash/`.
- REQ-764: On "n": skip git initialization entirely.
- REQ-765: If `.git` already exists, skip this step silently.

### Step 7: Template Validation

- REQ-770: The system SHALL locate the template directory at
  `templates/$TOOL/` relative to the repository, independent of the working
  directory (specs/plugin.md REQ-876).
- REQ-771: If the template directory does not exist, the system SHALL display
  an error and exit.

### Step 8: Page Creation (Python Template Rendering)

- REQ-780: `setup.sh` SHALL call `scripts/init-wiki.sh` with the collected
  answers. The init script SHALL use python3 to render templates with variable
  substitution.
- REQ-781: Template variables: `{{DATE}}` (today, YYYY-MM-DD),
  `{{NAMESPACES}}` (comma-separated list), `{{NAMESPACE}}` (single name),
  `{{NAMESPACE_LINKS}}` (formatted link list, used by the Dashboard).
- REQ-782: The system SHALL create these pages:
  - Schema page (from `Schema.md` template)
  - Dashboard page (from `Dashboard.md` template)
  - One Hub page per namespace (from `Hub.md` template)
  - Access-Log page under the Reference namespace (from `Access-Log.md` template)
- REQ-783: For Logseq: all pages created flat in `pages/` directory with
  triple-underscore naming (`Wiki___Schema.md`, `Wiki___Tech.md`, etc.).
- REQ-784: For Obsidian: Schema and Dashboard in `Wiki/` directory.
  Hub pages in `Wiki/<Namespace>/_index.md` with directory creation.
- REQ-785: The system SHALL create parent directories as needed (`mkdir -p`).
- REQ-786: The system SHALL NOT overwrite existing pages. If a page already
  exists, the system SHOULD skip it with a warning.

### Step 9: Config File Generation

- REQ-790: The system SHALL create `llm-wiki.yml` in the wiki root directory.
  The init script never overwrites an existing config. If one exists, `setup.sh`
  SHALL ask before replacing it and, on "y", remove it before calling the init
  script.
- REQ-791: The config SHALL include all required keys: tool, wiki_path,
  pages_dir, namespaces. And memory_path if provided.
- REQ-792: The config SHALL include a header comment with generation date.

### Step 10: Skill Installation

- REQ-800: The system SHALL ask if the user wants to install the /wiki skill
  for Claude Code.
- REQ-801: The user MAY enter a project path or "skip" to decline.
- REQ-802: If installing: copy `skills/wiki/SKILL.md` to
  `$project/.claude/commands/wiki.md`, creating the directory if needed.
- REQ-803: The system SHALL replace every occurrence of the literal string
  `${user_config.wiki_path}` in the copied file with the absolute wiki path.
- REQ-804: The replacement MUST behave identically on macOS and Linux and MUST
  be safe for paths containing characters that are special to `sed`.
- REQ-805: Before the skill-copy prompt the system SHALL print that the plugin
  is the recommended install path and that the copy does not update itself.
- REQ-806: After copying, the system SHALL verify that the copied file no
  longer contains `${user_config.` and SHALL print a warning if it does.

### Step 11: Initial Git Commit

- REQ-810: If git was initialized (Step 6) or `.git` already existed, the
  system SHALL create an initial commit with the files this run created. It
  MUST NOT stage other changes present in the wiki directory.
- REQ-811: The commit message SHALL include: tool name, namespace count,
  and a link to the GitHub repository.
- REQ-812: A failed commit SHALL NOT abort the setup; the system SHALL print a
  warning and leave the files uncommitted.

### Final Summary

- REQ-820: The system SHALL display a summary showing: wiki path, config
  file path, and 3 suggested next steps.
- REQ-821: The next steps SHALL include: open wiki in tool, try first ingest,
  run status command, and the plugin install as the way to receive updates.

---

## Scenarios

### Scenario 1: Happy path — Logseq, new directory, defaults

```
GIVEN python3 and git are available
WHEN the user runs ./setup.sh and:
    - Selects "1" (Logseq)
    - Enters "~/Documents/TestWiki" (does not exist)
    - Confirms "y" to create directory
    - Presses Enter for default namespaces
    - Enters "~/.claude/projects/test/memory/" for memory path
    - Confirms "y" for git init
    - Enters "~/myproject" for skill installation
THEN the system SHALL:
    - Create ~/Documents/TestWiki/pages/
    - Create 10 pages: Schema, Dashboard, Access-Log, 7 hub pages (one per default namespace)
    - Create llm-wiki.yml with all settings
    - Initialize git with .gitignore
    - Copy skills/wiki/SKILL.md to ~/myproject/.claude/commands/wiki.md
    - The copy SHALL contain the absolute path of ~/Documents/TestWiki as wiki root
      and no "${user_config." string
    - Create initial git commit
    - Display summary with next steps
```

### Scenario 2: Happy path — Obsidian, existing vault

```
GIVEN ~/Documents/ObsidianVault/ already exists with .obsidian/ directory
WHEN the user runs ./setup.sh and:
    - Selects "2" (Obsidian)
    - Enters "~/Documents/ObsidianVault"
    - Presses Enter for default namespaces
    - Skips memory path
    - git already initialized (.git exists)
    - Skips skill installation
THEN the system SHALL:
    - Create Wiki/ directory inside the vault
    - Create Schema.md and Dashboard.md in Wiki/, Access-Log.md in Wiki/Reference/
    - Create 7 namespace directories with _index.md hub pages
    - Create llm-wiki.yml (no memory_path)
    - Skip git init (already exists)
    - Create git commit with new files
    - Display summary
```

### Scenario 3: Directory does not exist — user declines creation

```
GIVEN the user enters wiki path "/nonexistent/path"
AND the path does not exist
WHEN the system asks "Create it? [y/n]"
AND the user enters "n"
THEN the system SHALL display an error message
AND exit with code 1
AND no files SHALL be created anywhere
```

### Scenario 4: Invalid tool selection

```
WHEN the user enters "3" for tool selection
THEN the system SHALL display: "Invalid choice"
AND exit with code 1
```

### Scenario 5: python3 not available

```
GIVEN python3 is not installed or not in PATH
WHEN setup.sh reaches the template rendering step
THEN the system SHALL fail with a python3-related error
AND no wiki pages SHALL be created
```

### Scenario 6: Template directory missing

```
GIVEN the templates/logseq/ directory does not exist
    (e.g., setup.sh run from wrong location)
WHEN setup.sh reaches template validation
THEN the system SHALL display an error about missing templates
AND exit with code 1
```

### Scenario 7: Skill installation skipped

```
WHEN the user enters "skip" for the skill installation prompt
THEN the system SHALL NOT copy wiki.md anywhere
AND SHALL NOT modify any files outside the wiki directory
AND SHALL continue to the git commit step
```

### Scenario 8: Custom namespaces

```
WHEN the user enters "Engineering Sales Support" for namespaces
THEN the system SHALL create 3 hub pages:
    - Wiki___Engineering.md (Logseq) or Wiki/Engineering/_index.md (Obsidian)
    - Wiki___Sales.md or Wiki/Sales/_index.md
    - Wiki___Support.md or Wiki/Support/_index.md
AND the Schema page SHALL list these 3 namespaces
AND llm-wiki.yml SHALL contain these 3 namespaces
```

### Scenario 9: Git init skipped

```
GIVEN the wiki directory has no .git/
WHEN the system asks "Initialize git? [y/n]"
AND the user enters "n"
THEN no .git directory SHALL be created
AND no .gitignore SHALL be created
AND the final commit step SHALL be skipped
```

### Scenario 10: Existing pages not overwritten

```
GIVEN ~/Documents/Logseq/pages/Wiki___Schema.md already exists
    from a previous setup run
WHEN setup.sh runs template rendering
THEN the existing Schema page SHOULD NOT be overwritten
AND the system SHOULD display: "Wiki___Schema.md already exists, skipping"
```

### Scenario 11: setup.sh and the init script produce the same wiki

```
GIVEN two empty directories A and B
WHEN setup.sh is run for A with Logseq, default namespaces, no memory path, no git
AND init-wiki.sh --tool logseq --wiki-path B is run
THEN the file lists of A and B SHALL be identical
AND file contents SHALL differ only in the wiki_path line of llm-wiki.yml
```

---

## Acceptance Criteria

- [ ] Only requires bash, python3, git (no package managers, no libraries)
- [ ] Tool selection (1/2) determines all downstream behavior
- [ ] Tilde expansion works in all path inputs
- [ ] Missing directories created with user confirmation
- [ ] Default namespaces offered, custom list accepted
- [ ] Template rendering creates Schema, Dashboard, and all Hub pages
- [ ] Logseq: flat files with triple-underscore naming
- [ ] Obsidian: directory hierarchy with _index.md hub files
- [ ] Config file generated with all required keys
- [ ] Skill installation optional; the copy carries the wiki root and no plugin placeholder
- [ ] Git init optional, tool-specific .gitignore
- [ ] Existing pages not silently overwritten
- [ ] Clear error messages for all failure modes
- [ ] Final summary with actionable next steps

---

## Dependencies

- Templates must exist: `templates/logseq/{Schema,Hub,Dashboard,Access-Log}.md` and
  `templates/obsidian/{Schema,Hub,Dashboard,Access-Log}.md`
- specs/plugin.md defines `scripts/init-wiki.sh`, which performs page creation
- specs/config.md defines the format of the generated `llm-wiki.yml`
- specs/schema.md defines what the generated Schema page contains
