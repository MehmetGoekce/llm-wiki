# Contributing to llm-wiki

Thanks for your interest in contributing! This project is young and contributions are welcome.

## Ways to contribute

- **Bug reports** — Something broken in the plugin or `setup.sh`? Wiki pages not formatting correctly? Open an issue.
- **Feature requests** — Ideas for new `/llm-wiki` commands, lint rules, or template improvements? Open an issue.
- **Templates** — Better Schema designs, new page types, or improved hub pages.
- **Tool support** — Improvements to Logseq or Obsidian templates, or support for new tools.
- **Documentation** — Fixes, clarifications, or new guides.

## Getting started

1. Fork the repo
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/llm-wiki.git`
3. Create a branch: `git checkout -b my-change`
4. Make your changes
5. Test with `./setup.sh` (both Logseq and Obsidian modes)
6. Commit and push
7. Open a Pull Request

## Testing your changes

Before submitting a PR, test both modes:

```bash
# Logseq mode
echo -e "1\n/tmp/test-logseq\ny\n\nskip\ny\nskip" | ./setup.sh

# Obsidian mode
echo -e "2\n/tmp/test-obsidian\ny\n\nskip\ny\nskip" | ./setup.sh

# Verify output
ls /tmp/test-logseq/pages/Wiki___*.md
ls /tmp/test-obsidian/Wiki/
```

Clean up test directories after:
```bash
rm -rf /tmp/test-logseq /tmp/test-obsidian
```

`setup.sh` only asks the questions. Pages and config are created by `scripts/init-wiki.sh`, which you can test without prompts:

```bash
scripts/init-wiki.sh --tool logseq --wiki-path /tmp/test-init
scripts/init-wiki.sh --tool logseq --wiki-path /tmp/test-init   # second run: everything skipped
scripts/init-wiki.sh --tool notion --wiki-path /tmp/test-bad    # exits 1, creates nothing
```

To test the plugin itself without installing it:

```bash
claude plugin validate . --strict
claude --plugin-dir .          # then /llm-wiki setup, /llm-wiki status
```

The skill is `SKILL.md` in the repository root; the plugin must not have a `skills/` directory, or Claude Code stops treating the root file as the plugin's single skill and the command is no longer `/llm-wiki`. It refers to the wiki location as `${user_config.wiki_path}`; keep that placeholder to the one `Wiki root:` line, because `setup.sh` replaces every occurrence in a copied skill.

## Guidelines

- Keep it simple. This tool should be understandable in 5 minutes.
- Templates must work in both Logseq and Obsidian (or clearly marked as tool-specific).
- No dependencies beyond `bash`, `python3`, and `git`. The setup script must run everywhere.
- Config file is always `llm-wiki.yml`.
- English for code, docs, and commit messages.

## Commit messages

Format: `type: short description`

Types: `feat`, `fix`, `docs`, `templates`, `examples`

Example: `feat: add /llm-wiki export command for PDF generation`

## Releasing (maintainer)

1. Add the release to `CHANGELOG.md`.
2. Set `version` in `.claude-plugin/plugin.json` to the same version. Plugin users stay on the old version until this value changes.
3. Run `claude plugin validate . --strict`.
4. Merge, tag the merge commit, create the GitHub release from the tag.

## Questions?

Open an issue or start a discussion. No question is too small.
