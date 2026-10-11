---
name: setup
description: One-time setup for llm-wiki. Creates the wiki skeleton (Schema, Dashboard, hub pages, Access-Log) and llm-wiki.yml in the configured wiki root. Use when the user asks to set up or initialize their LLM wiki.
disable-model-invocation: true
---

# /llm-wiki:setup - Create the wiki skeleton

Wiki root: `${user_config.wiki_path}`

You set up a new LLM wiki in the wiki root above. Pages and the config file are created by a script;
you collect the answers and run it. Do not create or edit wiki pages yourself.

## Steps

1. **Check the wiki root.** If the wiki root above is not a filesystem path but an unexpanded
   placeholder (it starts with a dollar sign and a brace), stop and tell the user to set
   "Wiki root" in the llm-wiki plugin settings.

2. **Check for an existing wiki.** If `llm-wiki.yml` exists in the wiki root, report that the wiki
   is already set up, show its `tool` and `namespaces`, and stop without changing anything. Only if
   the user then asks to add missing pages, continue with the values from the existing config; the
   script skips every file that already exists.

3. **Ask the user**, in one message:
   - Tool: Logseq or Obsidian. If the wiki root contains a `logseq/` directory suggest Logseq, if it
     contains `.obsidian/` suggest Obsidian.
   - Namespaces: default `Business Tech Content Projects People Learning Reference`, or their own
     list. Names start with a letter and contain only letters, numbers and hyphens.
   - Claude Code memory directory for the L1 features (optional, usually
     `~/.claude/projects/<project>/memory/`).
   - If the wiki root is not a git repository: whether to initialize git there.

4. **Run the script** with the answers:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-wiki.sh" \
     --tool <logseq|obsidian> \
     --wiki-path "<wiki root>" \
     --namespaces "<space-separated list>" \
     --commit
   ```

   Add `--memory-path "<dir>"` if the user gave one and `--git-init` if they agreed to it. `--commit`
   commits only the files the script created, and only if the wiki root is a git repository.

   If the script exits with an error, show its message and stop. Do not work around it by writing
   files by hand.

5. **Report**: the files created and skipped (from the script output), the path of `llm-wiki.yml`,
   and the next steps: open the wiki in the chosen tool, try `/llm-wiki:wiki ingest "<a first
   source>"`, then `/llm-wiki:wiki status`.

6. **Check for a copied skill.** If the current project contains `.claude/commands/wiki.md`, tell the
   user that an older copied `/wiki` skill is installed next to the plugin and that deleting that
   file avoids running two versions. Do not delete it yourself.
