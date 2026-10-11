# Spec delta: `specs/setup.md`

`setup.sh` stays the install path for users without the plugin. Its prompts are unchanged. Page
creation and config writing move to `scripts/init-wiki.sh` (plugin.md REQ-870-877).

## MODIFIED Requirements

- REQ-770 (was: locate templates at `$SCRIPT_DIR/templates/$TOOL/`):
  The system SHALL delegate template lookup to `scripts/init-wiki.sh` (plugin.md REQ-876).
- REQ-780 (was: use python3 to render templates):
  The system SHALL call `scripts/init-wiki.sh` with the collected answers. Template rendering
  rules REQ-781-786 now bind the init script.
- REQ-790 (was: create `llm-wiki.yml` in the wiki root):
  Config creation is performed by the init script. `setup.sh` keeps the overwrite prompt: if
  `llm-wiki.yml` exists it SHALL ask before replacing it, and on "y" remove the file before calling
  the init script.
- REQ-802 (was: copy `wiki.md` to `$project/.claude/commands/wiki.md`):
  If installing: copy `skills/wiki/SKILL.md` to `$project/.claude/commands/wiki.md`, creating the
  directory if needed.
- REQ-803 (was: patch the `<CONFIG_PATH>` placeholder):
  The system SHALL replace every occurrence of the literal string `${user_config.wiki_path}` in the
  copied file with the absolute wiki path.
- REQ-821 (was: next steps include open wiki, first ingest, status):
  The next steps SHALL additionally name the plugin install as the way to receive updates.

## ADDED Requirements

- REQ-805: Before the skill-copy prompt (REQ-800) the system SHALL print one line stating that
  the plugin is the recommended install path and that the copy does not update itself.
- REQ-806: After copying, the system SHALL verify that the copied file no longer contains
  `${user_config.` and SHALL print a warning if it does.

## Scenarios

### MODIFIED Scenario 1: Happy path — Logseq, new directory, defaults

The step "Copy wiki.md to ~/myproject/.claude/commands/wiki.md with patched config path" becomes:

```
    - Copy skills/wiki/SKILL.md to ~/myproject/.claude/commands/wiki.md
    - The copy SHALL contain the absolute path ~/Documents/TestWiki/llm-wiki.yml (expanded)
      and no "${user_config." string
```

### ADDED Scenario 11: setup.sh and the init script produce the same wiki

```
GIVEN two empty directories A and B
WHEN setup.sh is run for A with Logseq, default namespaces, no memory path, no git
AND init-wiki.sh --tool logseq --wiki-path B is run
THEN the file lists of A and B SHALL be identical
AND file contents SHALL differ only in the wiki_path line of llm-wiki.yml
```
