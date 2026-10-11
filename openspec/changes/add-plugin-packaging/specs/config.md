# Spec delta: `specs/config.md`

## MODIFIED Requirements

- REQ-602 (was: error "llm-wiki.yml not found. Run setup.sh to create one."):
  If the config file does not exist, the system SHALL display the error
  "llm-wiki.yml not found in {wiki root}. Run /llm-wiki:setup (plugin) or setup.sh to create one."
  and abort.

## ADDED Requirements

- REQ-670: The wiki root is resolved in this order: (1) the plugin's `wiki_path` user
  configuration, substituted into the skill as `${user_config.wiki_path}`; (2) for a copied skill,
  the absolute path written by `setup.sh` (setup.md REQ-803).
- REQ-671: If the skill text still contains the unsubstituted string `${user_config.wiki_path}`,
  the system SHALL abort with: "Wiki root is not configured. Set it in the llm-wiki plugin
  settings, or re-run setup.sh for a copied skill." It MUST NOT guess a wiki root.
- REQ-672: If `wiki_path` inside `llm-wiki.yml` names a different directory than the root the file
  was loaded from, the system SHALL warn once, naming both paths, and continue with the directory
  the file was loaded from.

## Scenarios

### ADDED Scenario 10: Wiki directory was moved

```
GIVEN the plugin's wiki_path is ~/notes/wiki
AND ~/notes/wiki/llm-wiki.yml contains wiki_path: ~/Documents/OldWiki
WHEN the user runs /wiki status
THEN the system SHALL warn that the two paths differ
AND report on ~/notes/wiki
```

### ADDED Scenario 11: Copied skill without substitution

```
GIVEN skills/wiki/SKILL.md was copied by hand to .claude/commands/wiki.md
AND no plugin is installed
WHEN the user runs /wiki lint
THEN the system SHALL abort with the REQ-671 message
AND SHALL NOT read or write any wiki page
```
