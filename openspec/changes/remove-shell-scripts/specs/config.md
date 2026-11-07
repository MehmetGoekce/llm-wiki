# Spec delta: Config (`specs/config.md`)

## MODIFIED Requirements

- REQ-670: The wiki root is resolved in this order: (1) the plugin's `wiki_path` user
  configuration, substituted into the skill as `${user_config.wiki_path}`; (2) for a copied skill,
  the absolute path the user wrote in place of the placeholder (specs/setup.md REQ-807).
- REQ-671: If the wiki root in the skill text is still the unsubstituted placeholder, the system
  SHALL abort with: "Wiki root is not configured. Set it in the llm-wiki plugin settings, or
  replace the placeholder in a copied skill (see README)." It MUST NOT guess a wiki root.

## MODIFIED Acceptance Criteria

- [ ] Wiki root comes from the plugin option or the path written into a copied skill, never guessed

## MODIFIED Dependencies

- The `setup` subcommand creates this config file (specs/setup.md REQ-790-792)
