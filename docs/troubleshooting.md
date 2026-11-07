# Troubleshooting

Common issues and fixes. If your problem is not listed here, open a [GitHub issue](https://github.com/MehmetGoekce/llm-wiki/issues/new/choose).

## Setup

### "This is a copied skill and the clone path is not filled in"

**Cause:** `/wiki setup` in a copied skill reads the page templates from the llm-wiki clone, and the copy still contains the placeholder `${CLAUDE_PLUGIN_ROOT}` instead of the clone's path.

**Fix:** Replace `${CLAUDE_PLUGIN_ROOT}` in `.claude/commands/wiki.md` with the absolute path of your clone (README, "Without the plugin"), then run `/wiki setup` again. If the clone was moved or deleted, clone it again and use the new path.

### Setup stops with a template path

**Cause:** A template under `templates/logseq/` or `templates/obsidian/` could not be read. With the plugin this points to a broken plugin cache; with a copied skill, to a wrong clone path or an incomplete clone.

**Fix:**

- **Plugin:** `claude plugin update llm-wiki@mehmetgoekce`, or uninstall and install it again.
- **Copied skill:** check the path in the error message, and clone the repository again if `templates/` is empty or partial.

### Setup says git steps are skipped

**Cause:** Git is not installed. It is needed only to initialize the wiki repository and make the first commit; the pages and `llm-wiki.yml` are created anyway.

**Fix:** Install git (macOS: `xcode-select --install`, Ubuntu/Debian: `sudo apt install git`, Fedora: `sudo dnf install git`, Windows: [Git for Windows](https://git-scm.com/download/win)), then run `git init` in the wiki root and commit the created files yourself.

### Some pages were reported as "Skipped (already exists)"

**Cause:** Setup never overwrites a file. Pages from an earlier run, or your own pages with the same name, are left as they are.

**Fix:** Nothing to fix if the existing pages are what you want. To regenerate one from its template, delete it and run setup again.

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

If you mix conventions (e.g., triple-underscore files inside an Obsidian vault), links break. Check that `tool` in `llm-wiki.yml` matches your app. If it does not, correct the value; pages already created in the wrong format have to be renamed or moved by hand.

## Claude Code Integration

### `/llm-wiki` commands aren't available in Claude Code

**Cause:** Neither the plugin nor a copied skill is installed.

**Fix (plugin):**

1. Run `claude plugin list` and check that `llm-wiki@mehmetgoekce` is listed as enabled. If not, install it as described in the README.
2. The plugin's command is `/llm-wiki <subcommand>`, for example `/llm-wiki ingest ...`. In v1.6.0 it was `/llm-wiki:wiki ingest ...`; a copied skill is `/wiki ingest ...`.

**Fix (copied skill):**

1. Confirm `.claude/commands/wiki.md` exists in your project directory.
2. If missing, copy it again as described in the README ("Without the plugin"). The copy is invoked as `/wiki`.

Restart Claude Code for the skill to be picked up.

### "Wiki root is not configured"

**Cause:** The skill does not know where your wiki is. With the plugin, the "Wiki root" option is unset. With a copied skill, the placeholder was not replaced.

**Fix:**

- **Plugin:** run `/plugin configure llm-wiki@mehmetgoekce` in Claude Code and enter your wiki directory, then restart Claude Code.
- **Copied skill:** open `.claude/commands/wiki.md` and replace `${user_config.wiki_path}` with the absolute path of your wiki directory (README, "Without the plugin").

### "llm-wiki.yml not found in ..."

**Cause:** The wiki root is set, but no wiki has been created there yet, or the wiki was moved.

**Fix:** Run `/llm-wiki setup` (or `/wiki setup` with a copied skill) to create it. If you moved the wiki, point the plugin's "Wiki root" option at the new location.

### `/llm-wiki ingest` runs forever or times out

**Cause:** Source is too large, or the wiki has grown past the batch limit and Claude is trying to load too many pages at once.

**Fix:**

- Split large sources. A 10,000-word document should be ingested in 2-3 passes, not one.
- The ingest pipeline has a 3-page batch limit — if your wiki has hundreds of pages and many are relevant to the source, processing takes proportionally longer.
- If Claude Code hits a context limit mid-ingest, it will stop and report. Re-run the same ingest — Claude reads target pages before writing and never deletes content, so a re-run does not duplicate blocks.

### `/llm-wiki ingest` blocks with a credential-leak warning but the content has no credentials

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

- **Two-stage routing handles retrieval precision automatically.** Since v1.2.0, `/llm-wiki query` reads the hub `### Index` routing lines first and opens only the 3 best-matching pages, rather than grepping every page. Keep each routing line's description terse and distinctive — that is what keeps routing sharp as the wiki grows.
- **Run `/llm-wiki prune` periodically (default every 6 months).** It evicts cold pages — no read in N months — from the live hub index into `### Archive`, so routing stays focused on the pages you actually use. Eviction never deletes or moves files; demoted pages stay greppable and are re-promoted automatically if queried again.
- **Split namespaces.** If `Wiki/Tech/` has 50+ pages, consider splitting into `Wiki/Tech/Infrastructure/`, `Wiki/Tech/Languages/`, etc. Namespaces can go 3 levels deep.
- **Run `/llm-wiki lint --fix`.** Beyond stale detection (90+ days), it now also fixes index drift — backfilling missing routing lines and tidying archived pages left in the live index.
- **Audit L1/L2.** If you find yourself querying the same L2 page every session, promote the essential part to L1.

The wiki scales, but like any knowledge system, it requires periodic gardening — now mostly automated by `/llm-wiki prune` and `/llm-wiki lint --fix`.

### `/llm-wiki lint` keeps flagging the same orphan pages

**Cause:** Pages that have no incoming links are flagged as orphans. If the same pages appear every run, they are genuinely unlinked.

**Fix:**

- Add the page to the appropriate hub page (e.g., `Wiki/Tech` hub should list all `Wiki/Tech/*` pages).
- Add cross-references from related pages — if `Wiki/Projects/X` mentions `Wiki/Tech/Y`, make sure it uses `[[Wiki/Tech/Y]]` syntax.
- Run `/llm-wiki lint --fix` — it auto-adds missing hub entries where obvious.

If a page is genuinely isolated and cannot be linked from anywhere, it may be a sign the page is misplaced (wrong namespace) or should be deleted.
