# Security Policy

## Supported versions

Only the latest release receives fixes. The plugin directory and the marketplace in this repository follow `main`.

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Report it privately through GitHub: [Report a vulnerability](https://github.com/MehmetGoekce/llm-wiki/security/advisories/new). The report is visible only to the maintainer.

Helpful to include:

- the version or commit you tested
- the subcommand involved (`setup`, `ingest`, `query`, `prune`, `lint`, `status`, `import`) or the script
- steps to reproduce, and what happened to which files

## What to expect

llm-wiki is maintained by one person. I aim to acknowledge a report within seven days and to say whether I can reproduce it. A fix ships as a patch release, and the advisory is published once the fix is out.

## Scope

In scope: the skill instructions in `SKILL.md`, `setup.sh`, and the scripts in `scripts/`. Examples: an instruction that makes Claude write outside the configured wiki or memory directory, a script that mishandles a path, or a way to get credentials written into wiki pages.

Out of scope: Claude Code itself, Logseq, Obsidian, and the content of your own wiki.
