# Design: remove-shell-scripts

## Context

`init-wiki.sh` does four things: validate the input, render four templates with python3 string
replacement, write `llm-wiki.yml`, and optionally run `git init` and commit the created files. None
of it needs a script. The rendering is plain literal substitution; the variables are a date and
namespace names restricted to `[A-Za-z][A-Za-z0-9-]*`, so no escaping is involved.

## D1: Claude writes the files with Read and Write, not with inline shell or python

**Decision.** The setup subcommand reads each template with the Read tool, substitutes the
placeholders, and writes the target with the Write tool. Bash is used only for `date +%Y-%m-%d`,
for the existence checks, and for `git`.

**Alternatives considered.**

- *Inline `sed`/`cat` commands in `SKILL.md`.* Deterministic, but `sed -i` and multi-line
  replacements (`{{NAMESPACE_LINKS}}`) differ between GNU and BSD `sed`, and the Logseq link prefix
  contains a tab, which is fragile inside a quoted shell argument written by a model.
- *An inline `python3 -c` program in `SKILL.md`.* Byte-exact, but it is the deleted script moved
  into a Markdown file. That keeps the letter of the directory policy and breaks its intent; a
  reviewer would be right to refuse it. Rejected.

**Risk.** A model may "improve" template text while copying it, or drop the trailing newline or
the tab. Mitigation: the requirements (setup.md REQ-780a) forbid any change besides the four
placeholders, and the parity test (tasks.md 3) compares every created file byte for byte with the
output of `init-wiki.sh` v1.7.1, in both tool modes, before the release.

## D2: Delete `setup.sh` instead of moving it

**Decision.** `setup.sh` is deleted. The README describes the copied-skill install as three manual
steps.

**Alternative considered.** A second repository (`llm-wiki-installer`) that holds `setup.sh` and
`init-wiki.sh`. It keeps the clone path but adds a second release process and a second place where
the setup rules live, which is the drift problem `init-wiki.sh` was created to solve in v1.6.0.
The plugin has been the recommended path since v1.6.0, and the copied skill already depends on a
local clone. Rejected.

**Copied skill.** A copy needs two substitutions: `${user_config.wiki_path}` (wiki root) and
`${CLAUDE_PLUGIN_ROOT}` (path of the clone, so that `/wiki setup` finds `templates/`). The README
gives one `sed` command per platform as a convenience; the user runs it, it is not shipped as a
file. config.md REQ-671 already stops the skill when the first placeholder is left in place; a new
check in the setup subcommand stops it when the templates cannot be read (setup.md REQ-771).

## D3: The reference for "same output" is `init-wiki.sh` at tag v1.7.1

The specs keep the output contract (file names, contents, config format, commit message) and
state it without the script. For verification, the script is not needed in the working tree: the
parity test runs it from a checkout of tag v1.7.1 (`git worktree add`), which holds the matching
templates. After the release the specs alone define the output.

## D4: Validation happens in the conversation, before the first write

The script exited 1 on invalid input. The subcommand asks again instead: an unknown tool or an
invalid namespace name is named, and the question is repeated. The guarantee that matters stays
the same: nothing is written until all answers are valid (setup.md REQ-742, REQ-745).

## D5: Overwrite protection is checked explicitly

The Write tool on its own refuses to overwrite only files that were not read in the session, which
is not a guarantee the skill can rely on. Before writing, the subcommand lists which targets exist
(one `test -e` per path, or one `ls` of the target directories) and skips them, as the script did.
It reports each file as created or skipped (setup.md REQ-786, REQ-787).

## D6: Manifest fields stay

`documentationUrl`, `supportUrl` and `privacyPolicyUrl` are documented directory listing fields
(plugins reference, "Directory listing fields"), and `claude plugin validate . --strict` passes on
v2.1.319. The October warnings came from an earlier validator. If the portal reports them again
for v1.8.0, they are removed in a patch release.
