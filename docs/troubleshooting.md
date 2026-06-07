# Troubleshooting

Common issues and fixes. If your problem is not listed here, open a [GitHub issue](https://github.com/MehmetGoekce/llm-wiki/issues/new/choose).

## Setup

### `setup.sh: python3: command not found`

**Cause:** Python 3 is not installed or not in your `PATH`. The setup script uses Python 3 to render page templates.

**Fix:**

- **macOS:** `brew install python3`
- **Ubuntu/Debian:** `sudo apt install python3`
- **Fedora:** `sudo dnf install python3`
- **Windows:** Install from [python.org](https://www.python.org/downloads/) and check "Add python.exe to PATH" during install.

Verify with `python3 --version`. The script requires Python 3.6 or newer (any version from the last ~8 years works).

### `setup.sh: git: command not found`

**Cause:** Git is not installed. Needed for the optional `git init` step and to clone the repo in the first place.

**Fix:**

- **macOS:** Comes with Xcode Command Line Tools — run `xcode-select --install`.
- **Ubuntu/Debian:** `sudo apt install git`
- **Fedora:** `sudo dnf install git`
- **Windows:** Install [Git for Windows](https://git-scm.com/download/win).

### `setup.sh` fails during template rendering

**Cause:** Usually one of three things:

1. The destination directory is not writable.
2. The template directory is missing (corrupted clone or wrong working directory).
3. A pre-existing file blocks template output.

**Fix:**

- Confirm you ran `./setup.sh` from inside the cloned `llm-wiki` directory, not from elsewhere.
- Check the path you entered is writable: `touch ~/Documents/Logseq/test.txt && rm ~/Documents/Logseq/test.txt`.
- If pre-existing pages block the render, setup will skip them. Delete the skipped pages manually if you want them regenerated.
- Re-clone the repo if `templates/` looks empty or partial.

### The script exits at "Which note-taking tool do you use?"

**Cause:** Something other than `1` or `2` was entered. The script exits immediately on invalid input rather than re-prompting.

**Fix:** Re-run `./setup.sh` and enter exactly `1` (Logseq) or `2` (Obsidian). If you prefer non-interactive runs (e.g., CI or testing):

```bash
echo -e "1\n~/test-wiki\ny\n\nskip\ny\nskip" | ./setup.sh
```

See `CONTRIBUTING.md` for the full stdin sequence.

## Wiki App Integration

### New pages don't appear in the Logseq graph

**Cause:** Logseq watches the `pages/` directory but only re-indexes under specific conditions. New files created while Logseq is running may not show up until you reload.

**Fix:**

1. In Logseq: `File → Reindex` (or `Cmd/Ctrl + Shift + R`).
2. Confirm the file path is correct. Logseq pages live in `<graph-root>/pages/` and must use the `Wiki___Namespace___Page.md` triple-underscore naming.
3. Check `journals/` is not accidentally being used — journals have a different format and will not render as regular wiki pages.

### Obsidian shows YAML frontmatter as a code block instead of Properties

**Cause:** Older Obsidian versions (before 1.4, released mid-2023) do not support the Properties feature. The frontmatter still works, but renders as literal text.

**Fix:**

- Update Obsidian to the latest version.
- In Settings → Editor, ensure "Properties in document" is enabled.
- If you deliberately disable Properties, the wiki still works — the LLM reads the YAML, and nothing breaks. The display is just uglier.

### Cross-references `[[Wiki/Tech/Strapi]]` aren't clickable

**Cause:** Wrong file-naming convention for the tool.

**Fix:**

- **Logseq** expects triple-underscore flat files: `Wiki___Tech___Strapi.md`. `[[Wiki/Tech/Strapi]]` resolves because Logseq treats `/` and `___` as equivalent path separators.
- **Obsidian** expects directory hierarchy: `Wiki/Tech/Strapi.md`. The file literally lives inside `Wiki/Tech/`.

If you mix conventions (e.g., triple-underscore files inside an Obsidian vault), links break. Check that `setup.sh` configured the correct tool — run it again and pick the tool matching your current vault.

## Claude Code Integration

### `/wiki` commands aren't available in Claude Code

**Cause:** The skill was not installed into your project. `setup.sh` offers to copy it but it is optional.

**Fix:**

1. Confirm `.claude/commands/wiki.md` exists in your project directory.
2. If missing, re-run `./setup.sh` and answer `y` at the "Install wiki skill in a project?" step, then provide the project path.
3. Alternatively, copy manually:
   ```bash
   cp wiki.md ~/your-project/.claude/commands/wiki.md
   ```
4. In `wiki.md`, verify the `<CONFIG_PATH>` placeholder has been replaced with the absolute path to your `llm-wiki.yml`.

Restart Claude Code for the skill to be picked up.

### `/wiki ingest` runs forever or times out

**Cause:** Source is too large, or the wiki has grown past the batch limit and Claude is trying to load too many pages at once.

**Fix:**

- Split large sources. A 10,000-word document should be ingested in 2-3 passes, not one.
- The ingest pipeline has a 3-page batch limit — if your wiki has hundreds of pages and many are relevant to the source, processing takes proportionally longer.
- If Claude Code hits a context limit mid-ingest, it will stop and report. Re-run the same ingest — Claude's append-only discipline prevents duplicates.

### `/wiki ingest` blocks with a credential-leak warning but the content has no credentials

**Cause:** False positive from lint rule #6. The credential-leak regex includes base64-like patterns (`[A-Za-z0-9+/]{40,}`), which also match innocent long strings — long URLs, hashes, or technical identifiers.

**Fix:**

1. Review the flagged content. If it is a genuine credential, move it to L1 (memory) and strip it from the source before re-ingesting.
2. If it is a false positive (e.g., a commit SHA or a long URL), you have two options:
   - Edit the source to break the pattern (e.g., add a space or truncate).
   - Temporarily disable the base64 pattern in `llm-wiki.yml` → `lint.credential_patterns`. Re-enable it after the ingest.

Never commit around the lint by force. The false positive rate is low, and genuine credential leaks have serious consequences.

## Wiki Growth

### The wiki has grown past 200 pages and feels unmanageable

**Cause:** Natural friction at scale. Past ~200 pages, flat namespaces get noisy, hub pages grow long, and the mental model of "what is where" breaks down. Retrieval also gets imprecise if it relies on grep-over-everything.

**Fix:**

- **Two-stage routing handles retrieval precision automatically.** Since v1.2.0, `/wiki query` reads the hub `### Index` routing lines first and opens only the 3 best-matching pages, rather than grepping every page. Keep each routing line's description terse and distinctive — that is what keeps routing sharp as the wiki grows.
- **Run `/wiki prune` periodically (default every 6 months).** It evicts cold pages — no read in N months — from the live hub index into `### Archive`, so routing stays focused on the pages you actually use. Eviction never deletes or moves files; demoted pages stay greppable and are re-promoted automatically if queried again.
- **Split namespaces.** If `Wiki/Tech/` has 50+ pages, consider splitting into `Wiki/Tech/Infrastructure/`, `Wiki/Tech/Languages/`, etc. Namespaces can go 3 levels deep.
- **Run `/wiki lint --fix`.** Beyond stale detection (90+ days), it now also fixes index drift — backfilling missing routing lines and tidying archived pages left in the live index.
- **Audit L1/L2.** If you find yourself querying the same L2 page every session, promote the essential part to L1.

The wiki scales, but like any knowledge system, it requires periodic gardening — now mostly automated by `/wiki prune` and `/wiki lint --fix`.

### `/wiki lint` keeps flagging the same orphan pages

**Cause:** Pages that have no incoming links are flagged as orphans. If the same pages appear every run, they are genuinely unlinked.

**Fix:**

- Add the page to the appropriate hub page (e.g., `Wiki/Tech` hub should list all `Wiki/Tech/*` pages).
- Add cross-references from related pages — if `Wiki/Projects/X` mentions `Wiki/Tech/Y`, make sure it uses `[[Wiki/Tech/Y]]` syntax.
- Run `/wiki lint --fix` — it auto-adds missing hub entries where obvious.

If a page is genuinely isolated and cannot be linked from anywhere, it may be a sign the page is misplaced (wrong namespace) or should be deleted.
