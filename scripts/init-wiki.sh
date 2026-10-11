#!/bin/bash
# Creates the wiki skeleton (Schema, Dashboard, hub pages, Access-Log) and llm-wiki.yml.
# Non-interactive: all input arrives as flags. Called by setup.sh and by the setup skill.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NS="Business Tech Content Projects People Learning Reference"

usage() {
    cat << 'USAGE'
Usage: init-wiki.sh --tool logseq|obsidian --wiki-path <dir> [options]

Options:
  --namespaces "A B C"   Space-separated namespace list (default: Business Tech Content
                         Projects People Learning Reference)
  --memory-path <dir>    Claude Code memory directory (L1), written to llm-wiki.yml
  --git-init             Run git init and write a .gitignore if the wiki has no .git
  --commit               Commit the created files if the wiki is a git repository
  -h, --help             Show this help

Existing pages and an existing llm-wiki.yml are never overwritten.
USAGE
}

fail() {
    echo "init-wiki.sh: $1" >&2
    exit 1
}

TOOL=""
WIKI_PATH=""
NAMESPACES=""
MEMORY_PATH=""
GIT_INIT=0
COMMIT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --tool|--wiki-path|--namespaces|--memory-path)
            [ $# -ge 2 ] || fail "$1 needs a value"
            case "$1" in
                --tool) TOOL="$2" ;;
                --wiki-path) WIKI_PATH="$2" ;;
                --namespaces) NAMESPACES="$2" ;;
                --memory-path) MEMORY_PATH="$2" ;;
            esac
            shift 2 ;;
        --git-init) GIT_INIT=1; shift ;;
        --commit) COMMIT=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) fail "unknown argument '$1' (see --help)" ;;
    esac
done

# ----- Validate everything before the first write -----
[ -n "$TOOL" ] || fail "--tool is required (logseq or obsidian)"
[ -n "$WIKI_PATH" ] || fail "--wiki-path is required"

case "$TOOL" in
    logseq) PAGES_DIR="pages" ;;
    obsidian) PAGES_DIR="" ;;
    *) fail "invalid tool '$TOOL' (expected logseq or obsidian)" ;;
esac

NAMESPACES="${NAMESPACES:-$DEFAULT_NS}"
for ns in $NAMESPACES; do
    if [[ ! "$ns" =~ ^[A-Za-z][A-Za-z0-9-]*$ ]]; then
        fail "invalid namespace name '$ns' (start with a letter; letters, numbers and hyphens only)"
    fi
done

WIKI_PATH="${WIKI_PATH/#\~/$HOME}"
MEMORY_PATH="${MEMORY_PATH/#\~/$HOME}"

if [ -e "$WIKI_PATH" ] && [ ! -d "$WIKI_PATH" ]; then
    fail "wiki path '$WIKI_PATH' exists and is not a directory"
fi

command -v python3 > /dev/null 2>&1 || fail "python3 is not installed"

TEMPLATE_DIR="$SCRIPT_DIR/../templates/$TOOL"
[ -d "$TEMPLATE_DIR" ] || fail "templates not found at $TEMPLATE_DIR"

HAVE_GIT=1
if ! command -v git > /dev/null 2>&1; then
    HAVE_GIT=0
    if [ "$GIT_INIT" = 1 ] || [ "$COMMIT" = 1 ]; then
        echo "Warning: git is not installed, skipping git steps." >&2
    fi
fi

# ----- Create -----
mkdir -p "$WIKI_PATH"
WIKI_PATH="$(cd "$WIKI_PATH" && pwd)"
TODAY=$(date +%Y-%m-%d)
CREATED_LIST="$(mktemp)"
trap 'rm -f "$CREATED_LIST"' EXIT

if [ "$GIT_INIT" = 1 ] && [ "$HAVE_GIT" = 1 ] && [ ! -d "$WIKI_PATH/.git" ]; then
    git -C "$WIKI_PATH" init --quiet
    echo "Initialized git repository"
    if [ ! -e "$WIKI_PATH/.gitignore" ]; then
        if [ "$TOOL" = "logseq" ]; then
            cat > "$WIKI_PATH/.gitignore" << 'GITIGNORE'
logseq/bak/
logseq/.recycle/
.DS_Store
.logseq/
GITIGNORE
        else
            cat > "$WIKI_PATH/.gitignore" << 'GITIGNORE'
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.DS_Store
.trash/
GITIGNORE
        fi
        echo ".gitignore" >> "$CREATED_LIST"
        echo "Created: .gitignore"
    fi
fi

python3 - "$TOOL" "$WIKI_PATH" "$PAGES_DIR" "$TEMPLATE_DIR" "$NAMESPACES" "$MEMORY_PATH" "$TODAY" "$CREATED_LIST" << 'PYEOF'
import os
import sys

tool, wiki_path, pages_dir, template_dir, ns_arg, memory_path, today, created_list = sys.argv[1:9]
namespaces = ns_arg.split()


def read_template(name):
    with open(os.path.join(template_dir, name)) as f:
        return f.read()


def write_file(target, content):
    rel_path, label = target
    path = os.path.join(wiki_path, rel_path)
    if os.path.exists(path):
        print(f"Skipped (already exists): {label}")
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    with open(created_list, "a") as f:
        f.write(rel_path + "\n")
    print(f"Created: {label}")


if tool == "logseq":
    def page(name):
        return os.path.join(pages_dir, "Wiki___" + name.replace("/", "___") + ".md"), "Wiki/" + name

    hub = page
    link_prefix = "\t- "
else:
    def page(name):
        return os.path.join("Wiki", name + ".md"), "Wiki/" + name + ".md"

    def hub(ns):
        return os.path.join("Wiki", ns, "_index.md"), f"Wiki/{ns}/_index.md"

    link_prefix = "- "

schema = read_template("Schema.md")
schema = schema.replace("{{NAMESPACES}}", ", ".join(f"Wiki/{ns}" for ns in namespaces))
write_file(page("Schema"), schema.replace("{{DATE}}", today))

dashboard = read_template("Dashboard.md")
dashboard = dashboard.replace("{{NAMESPACE_LINKS}}", "\n".join(f"{link_prefix}[[Wiki/{ns}]]" for ns in namespaces))
write_file(page("Dashboard"), dashboard.replace("{{DATE}}", today))

hub_tpl = read_template("Hub.md")
for ns in namespaces:
    write_file(hub(ns), hub_tpl.replace("{{NAMESPACE}}", ns).replace("{{DATE}}", today))

# Access-Log: append-only LRU signal for /llm-wiki prune
write_file(page("Reference/Access-Log"), read_template("Access-Log.md").replace("{{DATE}}", today))

config = [
    "# llm-wiki configuration",
    f"# Generated by llm-wiki on {today}",
    "",
    f"tool: {tool}",
    f"wiki_path: {wiki_path}",
    f"pages_dir: {pages_dir}",
    f"memory_path: {memory_path}",
    "",
    "namespaces:",
]
config += [f"  - {ns}" for ns in namespaces]
write_file(("llm-wiki.yml", "llm-wiki.yml"), "\n".join(config) + "\n")
PYEOF

if [ "$COMMIT" = 1 ] && [ "$HAVE_GIT" = 1 ] && [ -d "$WIKI_PATH/.git" ] && [ -s "$CREATED_LIST" ]; then
    NS_COUNT=$(echo $NAMESPACES | wc -w | tr -d ' ')
    # Stage only what this run created; an existing vault may hold unrelated changes.
    if (cd "$WIKI_PATH" && git add --pathspec-from-file="$CREATED_LIST" \
        && git commit --quiet -m "wiki: initial setup via llm-wiki

Schema, Dashboard, and hub pages for $NS_COUNT namespaces.
Tool: $TOOL

Generated by https://github.com/MehmetGoekce/llm-wiki") > /dev/null 2>&1; then
        echo "Committed: initial wiki setup"
    else
        echo "Warning: git commit failed, files are left uncommitted." >&2
    fi
fi
