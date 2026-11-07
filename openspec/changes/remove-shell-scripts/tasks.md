# Tasks: remove-shell-scripts

Ordered so that the parity test (group 3) runs before anything is deleted. One commit per numbered
group. Nothing reaches `main` before the PR is merged by the maintainer.

## 0. Before implementation (maintainer)

- [ ] 0.1 Decide the version number (proposal.md, Open questions 1).
- [ ] 0.2 Read the exact list of unrecognized manifest fields in the portal's Review tab
      ("Other findings from the automatic checks") (proposal.md, Open questions 2).

## 1. Rewrite the setup subcommand

- [ ] 1.1 `SKILL.md`, Workflow: setup. Replace the opening paragraph and Phase 3 with the steps of
      setup.md: validate all answers (REQ-745), read the date once, check which targets exist
      (REQ-786), create the root and `git init` if chosen, render and write the four templates and
      the config in REQ-782 order, commit the created files by path (REQ-810, 811).
- [ ] 1.2 State the placeholder values of REQ-781 and the config form of REQ-791 literally in the
      skill, including the tab in the Logseq link prefix and the trailing space after empty
      `pages_dir:` / `memory_path:`.
- [ ] 1.3 Add the template-missing message of REQ-771.
- [ ] 1.4 `SKILL.md` lines 57-60: replace "written in by `setup.sh`" and "re-run setup.sh" with the
      wording of config.md REQ-671.
- [ ] 1.5 Check REQ-837: `SKILL.md` contains no embedded program.

## 2. Docs

- [ ] 2.1 README: replace the `./setup.sh` section with the manual copy of setup.md REQ-807
      (one `sed` example for GNU and one for BSD/macOS, shown, not shipped as a file).
- [ ] 2.2 `docs/faq.md` (lines 42, 94, 100), `docs/troubleshooting.md` (python3 entry removed;
      new entry for REQ-771).
- [ ] 2.3 `CONTRIBUTING.md`: test instructions use the parity test instead of `./setup.sh` and
      the init script; dependency rule now "git optional, nothing else"; release checklist gains
      the file-policy check of plugin.md Scenario 7.
- [ ] 2.4 `SECURITY.md`, `.github/SECURITY.md`: scope is `SKILL.md` and the templates.
      `.github/ISSUE_TEMPLATE/bug_report.md` ("plugin / copied skill"),
      `.github/ISSUE_TEMPLATE/feature_request.md` (drop the `setup.sh` box),
      `.github/PULL_REQUEST_TEMPLATE.md` (dependency line).
- [ ] 2.5 `openspec/project.md` (Distribution, Dependencies, Constraints, spec table counts),
      `openspec/AGENTS.md` (zero-dependency rule, Testing, File Map).

## 3. Parity test (before deleting the scripts)

- [ ] 3.1 For each of the four cases of setup.md Scenario 11 (logseq/obsidian x default/custom
      namespaces): run `init-wiki.sh` from the working tree into `A`, run `/llm-wiki setup` with
      `--plugin-dir .` into `B`, then `diff -r A B`. Only the `wiki_path` line may differ.
- [ ] 3.2 Run setup.md Scenarios 2 (uncommitted change stays unstaged), 4, 7 and 10 once each.
- [ ] 3.3 Record the Claude Code version and the results below.

## 4. Remove and clean up

- [ ] 4.1 `.claude-plugin/plugin.json`: remove the fields from 0.2.
- [ ] 4.2 `git rm setup.sh scripts/init-wiki.sh`.
- [ ] 4.3 Run plugin.md Scenario 7 over `git ls-files`: no `#!`, allowed types only, UTF-8, no
      NUL. If the portal later objects to `diagrams/*.mmd`, move each diagram into a fenced
      `mermaid` block in a `.md` file.
- [ ] 4.4 `claude plugin validate . --strict` passes.

## 5. Specs and release notes

- [ ] 5.1 Apply the deltas: replace `openspec/specs/setup.md`, update `plugin.md` and
      `config.md`.
- [ ] 5.2 `CHANGELOG.md`: fold `[Unreleased]` into the new version. Remove the claim that the
      manifest links are "shown on the directory listing". Sections: Changed (setup without
      script), Removed (`setup.sh`, `scripts/init-wiki.sh`, manifest fields), Migration (clone
      users: plugin or manual copy).
- [ ] 5.3 `plugin.json` `version` equals the CHANGELOG version (REQ-832).

## 6. Release and directory (after merge, maintainer)

- [ ] 6.1 Merge the PR. The push to `main` triggers a new directory check.
- [ ] 6.2 Tag on the merge commit, GitHub release from the tag (CLAUDE.md release steps).
- [ ] 6.3 Portal: check that the new version passes "Directory policy". If "Plugin not fully
      checked" appears again, use "Check for new commits".
- [ ] 6.4 After approval, publish in the portal (approval does not publish).
- [ ] 6.5 Move this change to `openspec/changes/archive/`.

## Results

(filled in during group 3)
