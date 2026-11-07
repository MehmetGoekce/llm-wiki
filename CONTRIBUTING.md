# Contributing to llm-wiki

Thanks for your interest in contributing! This project is young and contributions are welcome.

## Ways to contribute

- **Bug reports** — Something broken in the plugin or in `/llm-wiki setup`? Wiki pages not formatting correctly? Open an issue.
- **Feature requests** — Ideas for new `/llm-wiki` commands, lint rules, or template improvements? Open an issue.
- **Templates** — Better Schema designs, new page types, or improved hub pages.
- **Tool support** — Improvements to Logseq or Obsidian templates, or support for new tools.
- **Documentation** — Fixes, clarifications, or new guides.

## Getting started

1. Fork the repo
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/llm-wiki.git`
3. Create a branch: `git checkout -b my-change`
4. Make your changes
5. Test in both Logseq and Obsidian mode (see below)
6. Commit and push
7. Open a Pull Request

## Testing your changes

Run the plugin from your clone and set up a throwaway wiki in both modes:

```bash
claude plugin validate . --strict
claude --plugin-dir .          # Wiki root: an empty test directory; then /llm-wiki setup, /llm-wiki status
```

When you change the setup workflow or a template, compare the result with the previous release. Check out the last release tag in a second worktree, set up one wiki with each version using the same answers, and run `diff -r` on the two directories. Only the `wiki_path` line of `llm-wiki.yml` may differ, unless your change is meant to alter the output.

The repository must stay free of executable files: no file may start with `#!`, and every file must be Markdown, plain text, JSON, YAML or a PNG/JPEG/GIF/WebP/ICO image. Anthropic's plugin directory refuses anything else from accounts that are not a Verified organization.

The skill is `SKILL.md` in the repository root; the plugin must not have a `skills/` directory, or Claude Code stops treating the root file as the plugin's single skill and the command is no longer `/llm-wiki`. It refers to the wiki location as `${user_config.wiki_path}`; keep that placeholder to the one `Wiki root:` line, because the README tells users of a copied skill to replace every occurrence.

## Guidelines

- Keep it simple. This tool should be understandable in 5 minutes.
- Templates must work in both Logseq and Obsidian (or clearly marked as tool-specific).
- No dependencies and no scripts. The skill uses Claude Code's own tools; `git` is the only optional external tool.
- Config file is always `llm-wiki.yml`.
- English for code, docs, and commit messages.

## Commit messages

Format: `type: short description`

Types: `feat`, `fix`, `docs`, `templates`, `examples`

Example: `feat: add /llm-wiki export command for PDF generation`

## Releasing (maintainer)

1. Add the release to `CHANGELOG.md`.
2. Set `version` in `.claude-plugin/plugin.json` to the same version. Plugin users stay on the old version until this value changes.
3. Run `claude plugin validate . --strict`, and check that no tracked file starts with `#!` (this must print nothing):
   `for f in $(git ls-files); do [ "$(head -c2 "$f")" = '#!' ] && echo "$f"; done`
4. Merge, tag the merge commit, create the GitHub release from the tag.

## Questions?

Open an issue or start a discussion. No question is too small.
