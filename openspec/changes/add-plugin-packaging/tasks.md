# Tasks: add-plugin-packaging

Ordered so that every step leaves `setup.sh` working. One commit per numbered group.

## 1. Extract the init script (no user-visible change)

- [x] 1.1 Create `scripts/init-wiki.sh` from `setup.sh` steps 3 and 6-9, flags per plugin.md
      REQ-871. Validate all input before the first write (REQ-875).
- [x] 1.2 Reduce `setup.sh` to prompts plus one call to the init script. Keep the config overwrite
      prompt (setup.md REQ-790).
- [x] 1.3 Verify setup.md Scenario 11 (same output from both paths) for Logseq and Obsidian.
- [x] 1.4 Verify plugin.md Scenarios 4 and 5.

## 2. Move the skill

- [x] 2.1 `git mv wiki.md skills/wiki/SKILL.md`; add frontmatter (`name`, `description`,
      `argument-hint`).
- [x] 2.2 Change the Configuration section to read `${user_config.wiki_path}/llm-wiki.yml`; add the
      abort rule of config.md REQ-671 and the mismatch warning of REQ-672.
- [x] 2.3 Leave a root `wiki.md` pointer file (design D1), to be removed in v1.7.0.
- [x] 2.4 Update `setup.sh` step 10: new source path, real placeholder, post-copy check
      (setup.md REQ-802, 803, 805, 806).
- [x] 2.5 Verify setup.md Scenario 1 and config.md Scenario 11.

## 3. Add the plugin

- [x] 3.1 Add `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (design.md).
- [x] 3.2 Write `skills/setup/SKILL.md` (plugin.md REQ-862-867).
- [x] 3.3 `claude plugin validate . --strict` passes.

## 4. Test as an installed plugin

- [ ] 4.1 `claude plugin marketplace add ./` from a clone, install, run plugin.md Scenarios 1-3
      in both tool modes.
      Done so far (v2.1.296): marketplace add and install from the local clone in a separate
      profile (`claude plugin details` lists skills `setup`, `wiki`); Scenarios 1-3 run headless
      with `--plugin-dir` in Obsidian mode. Open: the same three scenarios in Logseq mode, and an
      install from `MehmetGoekce/llm-wiki` on GitHub, which is only possible after the merge (6.2).
- [x] 4.2 Check whether the `directory` option accepts a path that does not exist yet.
      Result: `claude plugin configure --values-stdin` accepts it; the init script creates the
      directory. The interactive dialog was not tested.
- [x] 4.3 Check whether a project-level settings file can override `wiki_path`.
      Result: no. The settings reference lists `pluginConfigs` as "User or managed". Recorded in
      `docs/faq.md` with the copied skill as the way to run a second wiki.
- [x] 4.4 Record the tested Claude Code version for the README (2.1.296).

## 5. Specs and docs

- [x] 5.1 Apply the deltas: add `openspec/specs/plugin.md`, update `setup.md` and `config.md`.
- [x] 5.2 `openspec/project.md`: spec table row for plugin.md, new requirement and scenario
      totals, "Runtime" line, repository layout. `openspec/AGENTS.md`: file map.
- [x] 5.3 README: Quick Start leads with the plugin; clone path as second option; one sentence on
      `/llm-wiki:wiki` vs `/wiki`; migration note for copied-skill users.
- [x] 5.4 `docs/troubleshooting.md`: replace the `<CONFIG_PATH>` entry with the REQ-671 message
      and its two fixes. `docs/faq.md`: plugin vs copy, several wikis.
- [x] 5.5 `CONTRIBUTING.md`: test commands for the init script; release checklist gains the
      version bump and the validate step (plugin.md REQ-832, 833).
- [x] 5.6 `CHANGELOG.md`: 1.6.0 entry with Added / Changed / Fixed (the no-op `sed`) / Migration.

## 6. Release (after merge, maintainer)

- [ ] 6.1 Tag `v1.6.0` on the merge commit, GitHub release from the tag.
- [ ] 6.2 Install from `MehmetGoekce/llm-wiki` on a clean profile and run plugin.md Scenario 1.
- [ ] 6.3 Move this change to `openspec/changes/archive/`.
