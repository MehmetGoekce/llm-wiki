# Spec: Configuration — llm-wiki.yml Loading & Validation

## Description

Every /llm-wiki command reads `llm-wiki.yml` before doing anything else. This config
file determines tool mode (Logseq vs Obsidian), file paths, and namespace structure.
All downstream behavior depends on this file being valid.

---

## Requirements

### Config File Location

- REQ-600: The config file MUST be named `llm-wiki.yml` and located in the wiki
  root directory (the path specified as `wiki_path` in the config itself).
- REQ-601: Every /llm-wiki command (ingest, query, lint, status) MUST read the config
  file as its first operation, before any wiki page operations.
- REQ-602: If the config file does not exist, the system SHALL display an error:
  "llm-wiki.yml not found in {wiki root}. Run /llm-wiki setup to create one." and
  abort. The `setup` subcommand is exempt: it creates the file.
- REQ-670: The wiki root is resolved in this order: (1) the plugin's `wiki_path` user
  configuration, substituted into the skill as `${user_config.wiki_path}`; (2) for a
  copied skill, the absolute path written by `setup.sh` (specs/setup.md REQ-803).
- REQ-671: If the wiki root in the skill text is still the unsubstituted placeholder,
  the system SHALL abort with: "Wiki root is not configured. Set it in the llm-wiki
  plugin settings, or re-run setup.sh for a copied skill." It MUST NOT guess a wiki root.
- REQ-672: If `wiki_path` inside `llm-wiki.yml` names a different directory than the
  root the file was loaded from, the system SHALL warn once, naming both paths, and
  continue with the directory the file was loaded from.

### Required Keys

- REQ-610: The config MUST contain the key `tool` with value `logseq` or `obsidian`.
  No other values are allowed.
- REQ-611: The config MUST contain the key `wiki_path` with an absolute or
  tilde-expandable path to the wiki root directory.
- REQ-612: The config MUST contain the key `pages_dir` with a path relative to
  `wiki_path`. For Logseq this is typically `pages`. For Obsidian this is
  typically an empty string.
- REQ-613: The config MUST contain the key `namespaces` with a non-empty array
  of namespace names.

### Optional Keys

- REQ-620: The config MAY contain the key `memory_path` with a path to the L1
  memory directory. If absent, L1 Memory features (query supplementation,
  L1/L2 duplicate detection, L1 verification) are disabled.
- REQ-660: The config MAY contain the key `l1_verify_days`: a positive integer, the
  number of days after which an L1 rule with `asserts-current-behavior: true` is due
  for re-verification (see specs/l1-l2-routing.md REQ-374). Default: 90.
- REQ-661: If `l1_verify_days` is present but not a positive integer, the system SHALL
  display a warning "Invalid l1_verify_days '{value}', using 90." and continue with 90.

### Validation Rules

- REQ-630: If `tool` is not `logseq` or `obsidian`, the system SHALL display:
  "Invalid tool '{value}'. Must be 'logseq' or 'obsidian'." and abort.
- REQ-631: If `wiki_path` does not exist on disk (after tilde expansion), the
  system SHALL display: "Wiki path '{path}' does not exist." and abort.
- REQ-632: If `pages_dir` is non-empty and the resolved directory
  (`wiki_path/pages_dir`) does not exist, the system SHALL display a warning
  but continue (the directory may be created during setup).
- REQ-633: If `namespaces` is empty or missing, the system SHALL display:
  "No namespaces configured in llm-wiki.yml." and abort.
- REQ-634: Namespace names SHOULD be Title Case (e.g., `Tech`, not `tech`).
  Non-Title-Case names SHALL trigger a warning but not abort.

### Path Handling

- REQ-640: The system SHALL expand `~` to `$HOME` in `wiki_path` and
  `memory_path` before use.
- REQ-641: The system SHALL resolve `pages_dir` relative to `wiki_path`:
  `full_pages_path = wiki_path + "/" + pages_dir`.
- REQ-642: For Obsidian with empty `pages_dir`, `full_pages_path` equals
  `wiki_path`.

### Tool Mode Propagation

- REQ-650: The `tool` value determines ALL downstream format decisions:
  - Property syntax (inline vs YAML frontmatter)
  - File naming (triple-underscore vs directory hierarchy)
  - Content format (outliner blocks vs flat markdown)
  - Hub file naming (`Wiki___Namespace.md` vs `Wiki/Namespace/_index.md`)
- REQ-651: The tool mode MUST be consistent across ALL wiki operations in a
  single session. Switching tools mid-session is not supported.

---

## Scenarios

### Scenario 1: Valid Logseq config

```
GIVEN llm-wiki.yml contains:
    tool: logseq
    wiki_path: /home/user/Documents/Logseq
    pages_dir: pages
    memory_path: ~/.claude/projects/myproject/memory/
    namespaces:
      - Business
      - Tech
      - Projects
AND /home/user/Documents/Logseq/pages/ exists on disk
WHEN any /llm-wiki command starts
THEN the system SHALL load the config successfully
AND set tool mode to Logseq (outliner format, triple-underscore files)
AND resolve pages path to /home/user/Documents/Logseq/pages/
```

### Scenario 2: Valid Obsidian config

```
GIVEN llm-wiki.yml contains:
    tool: obsidian
    wiki_path: ~/Documents/ObsidianVault
    pages_dir: ""
    namespaces:
      - Business
      - Tech
AND ~/Documents/ObsidianVault/ exists on disk
WHEN any /llm-wiki command starts
THEN the system SHALL load the config successfully
AND set tool mode to Obsidian (flat markdown, directory hierarchy)
AND resolve pages path to /home/user/Documents/ObsidianVault/
```

### Scenario 3: Config file missing

```
GIVEN no llm-wiki.yml file exists in the wiki root
WHEN the user runs /llm-wiki ingest "some source"
THEN the system SHALL display: "llm-wiki.yml not found in {wiki root}. Run
    /llm-wiki setup to create one."
AND abort without modifying any files
```

### Scenario 4: Invalid tool value

```
GIVEN llm-wiki.yml contains tool: notion
WHEN the user runs any /llm-wiki command
THEN the system SHALL display: "Invalid tool 'notion'. Must be 'logseq' or 'obsidian'."
AND abort without modifying any files
```

### Scenario 5: Wiki path does not exist

```
GIVEN llm-wiki.yml contains wiki_path: /home/user/nonexistent/path
AND that path does not exist on disk
WHEN the user runs any /llm-wiki command
THEN the system SHALL display: "Wiki path '/home/user/nonexistent/path' does not exist."
AND abort without modifying any files
```

### Scenario 6: Empty namespaces

```
GIVEN llm-wiki.yml contains namespaces: []
WHEN the user runs any /llm-wiki command
THEN the system SHALL display: "No namespaces configured in llm-wiki.yml."
AND abort
```

### Scenario 7: Memory path missing — features degraded

```
GIVEN llm-wiki.yml has no memory_path key
WHEN the user runs /llm-wiki query "some question"
THEN the system SHALL proceed without L1 Memory consultation
AND NOT display an error (memory_path is optional)
AND the answer SHALL be based on wiki pages only
```

### Scenario 7b: L1 verification window

```
GIVEN llm-wiki.yml contains l1_verify_days: 30
WHEN the user runs /llm-wiki lint
THEN Rule 12 SHALL treat an asserts-current-behavior rule verified 31 days ago as due
```

### Scenario 8: Tilde expansion in paths

```
GIVEN llm-wiki.yml contains:
    wiki_path: ~/Documents/MyWiki
    memory_path: ~/.claude/projects/x/memory/
AND the user's HOME is /home/user
WHEN the system loads the config
THEN wiki_path SHALL resolve to /home/user/Documents/MyWiki
AND memory_path SHALL resolve to /home/user/.claude/projects/x/memory/
```

### Scenario 10: Wiki directory was moved

```
GIVEN the plugin's wiki_path is ~/notes/wiki
AND ~/notes/wiki/llm-wiki.yml contains wiki_path: ~/Documents/OldWiki
WHEN the user runs /llm-wiki status
THEN the system SHALL warn that the two paths differ
AND report on ~/notes/wiki
```

### Scenario 11: Copied skill without substitution

```
GIVEN SKILL.md was copied by hand to .claude/commands/wiki.md
AND no plugin is installed
WHEN the user runs /llm-wiki lint
THEN the system SHALL abort with the REQ-671 message
AND SHALL NOT read or write any wiki page
```

---

## Acceptance Criteria

- [ ] Config read as first operation of every /llm-wiki command
- [ ] Missing config file produces clear error naming the wiki root and both setup paths
- [ ] Wiki root comes from the plugin option or the path written by setup.sh, never guessed
- [ ] tool value strictly validated (logseq or obsidian only)
- [ ] wiki_path validated (must exist on disk)
- [ ] namespaces validated (must be non-empty)
- [ ] memory_path is optional (features degrade gracefully)
- [ ] l1_verify_days defaults to 90; invalid values warn and fall back to 90
- [ ] Tilde expansion works in all path fields
- [ ] Tool mode propagates to all downstream operations
- [ ] Invalid config values produce clear, specific error messages

---

## Dependencies

- `scripts/init-wiki.sh` creates this config file, called by setup.sh or `/llm-wiki setup`
  (see specs/setup.md, specs/plugin.md)
- All other specs (ingest, query, lint) depend on config being loaded first
