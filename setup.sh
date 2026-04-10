#!/bin/bash
set -eo pipefail

# Detect script location BEFORE any cd operations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- Prerequisites -----
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "\033[0;31mRequired: '$1' is not installed.\033[0m"
        echo "Please install $1 and try again."
        exit 1
    fi
}

check_command python3
check_command git

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}llm-wiki setup${NC}"
echo -e "${CYAN}Build Karpathy's LLM Wiki with Claude Code${NC}"
echo ""

# ----- Step 1: Tool selection -----
echo -e "${BOLD}Which note-taking tool do you use?${NC}"
echo "  1) Logseq"
echo "  2) Obsidian"
read -p "Enter choice [1/2]: " tool_choice

case $tool_choice in
    1) TOOL="logseq" ;;
    2) TOOL="obsidian" ;;
    *) echo -e "${RED}Invalid choice. Exiting.${NC}"; exit 1 ;;
esac
echo -e "${GREEN}Selected: $TOOL${NC}"
echo ""

# ----- Step 2: Wiki path -----
if [ "$TOOL" = "logseq" ]; then
    DEFAULT_PATH="$HOME/Documents/Logseq"
else
    DEFAULT_PATH="$HOME/Documents/ObsidianVault"
fi

echo -e "${BOLD}Where is your $TOOL graph/vault?${NC}"
read -p "Path [$DEFAULT_PATH]: " wiki_path
wiki_path="${wiki_path:-$DEFAULT_PATH}"

# Expand ~ to $HOME
wiki_path="${wiki_path/#\~/$HOME}"

if [ ! -d "$wiki_path" ]; then
    echo -e "${YELLOW}Directory does not exist. Create it? [y/n]${NC}"
    read -p "" create_dir
    if [ "$create_dir" = "y" ] || [ "$create_dir" = "Y" ]; then
        mkdir -p "$wiki_path"
        echo -e "${GREEN}Created: $wiki_path${NC}"
    else
        echo -e "${RED}Exiting. Please create the directory first.${NC}"
        exit 1
    fi
fi
echo ""

# ----- Step 3: Pages directory -----
if [ "$TOOL" = "logseq" ]; then
    PAGES_DIR="pages"
else
    PAGES_DIR=""
fi

pages_path="$wiki_path/$PAGES_DIR"
if [ -n "$PAGES_DIR" ] && [ ! -d "$pages_path" ]; then
    mkdir -p "$pages_path"
fi

# ----- Step 4: Namespaces -----
DEFAULT_NS="Business Tech Content Projects People Learning Reference"
echo -e "${BOLD}Which namespaces do you want?${NC}"
echo -e "Default: ${CYAN}$DEFAULT_NS${NC}"
read -p "Enter space-separated list (or press Enter for default): " custom_ns
NAMESPACES="${custom_ns:-$DEFAULT_NS}"

# Validate namespace names (no spaces within names, no special characters)
for ns in $NAMESPACES; do
    if [[ ! "$ns" =~ ^[A-Za-z][A-Za-z0-9-]*$ ]]; then
        echo -e "${RED}Invalid namespace name: '$ns'${NC}"
        echo "Namespace names must start with a letter and contain only letters, numbers, and hyphens."
        exit 1
    fi
done

echo -e "${GREEN}Namespaces: $NAMESPACES${NC}"
echo ""

# ----- Step 5: Memory path -----
echo -e "${BOLD}Where is your Claude Code memory directory?${NC}"
echo -e "(Usually: ~/.claude/projects/<project>/memory/)"
read -p "Path [skip]: " memory_path
memory_path="${memory_path/#\~/$HOME}"
echo ""

# ----- Step 6: Git init -----
if [ ! -d "$wiki_path/.git" ]; then
    echo -e "${BOLD}Initialize git in $wiki_path?${NC} [y/n]"
    read -p "" init_git
    if [ "$init_git" = "y" ] || [ "$init_git" = "Y" ]; then
        cd "$wiki_path"
        git init

        # Create .gitignore
        if [ "$TOOL" = "logseq" ]; then
            cat > .gitignore << 'GITIGNORE'
logseq/bak/
logseq/.recycle/
.DS_Store
.logseq/
GITIGNORE
        else
            cat > .gitignore << 'GITIGNORE'
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.DS_Store
.trash/
GITIGNORE
        fi
        echo -e "${GREEN}Git initialized with .gitignore${NC}"
    fi
fi
echo ""

# ----- Step 7: Set template directory -----
TEMPLATE_DIR="$SCRIPT_DIR/templates/$TOOL"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}Templates not found at $TEMPLATE_DIR${NC}"
    echo "Make sure you're running this from the llm-wiki repository."
    exit 1
fi

# ----- Step 8: Create wiki pages via Python (handles multiline templates) -----
echo -e "${BOLD}Creating wiki pages...${NC}"

TODAY=$(date +%Y-%m-%d)

python3 << PYEOF
import os

tool = "$TOOL"
pages_path = "$pages_path"
wiki_path = "$wiki_path"
template_dir = "$TEMPLATE_DIR"
namespaces = "$NAMESPACES".split()
today = "$TODAY"

def read_template(name):
    with open(os.path.join(template_dir, name)) as f:
        return f.read()

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        print(f"  Skipped (already exists): {os.path.basename(path)}")
        return False
    with open(path, 'w') as f:
        f.write(content)
    return True

if tool == "logseq":
    # Schema
    ns_list = ", ".join(f"Wiki/{ns}" for ns in namespaces)
    schema = read_template("Schema.md")
    schema = schema.replace("{{NAMESPACES}}", ns_list)
    schema = schema.replace("{{DATE}}", today)
    if write_file(os.path.join(pages_path, "Wiki___Schema.md"), schema):
        print(f"  Created: Wiki/Schema")

    # Dashboard
    ns_links = "\n".join(f"\t- [[Wiki/{ns}]]" for ns in namespaces)
    dashboard = read_template("Dashboard.md")
    dashboard = dashboard.replace("{{NAMESPACE_LINKS}}", ns_links)
    dashboard = dashboard.replace("{{DATE}}", today)
    if write_file(os.path.join(pages_path, "Wiki___Dashboard.md"), dashboard):
        print(f"  Created: Wiki/Dashboard")

    # Hub pages
    hub_tpl = read_template("Hub.md")
    for ns in namespaces:
        hub = hub_tpl.replace("{{NAMESPACE}}", ns).replace("{{DATE}}", today)
        if write_file(os.path.join(pages_path, f"Wiki___{ns}.md"), hub):
            print(f"  Created: Wiki/{ns}")

else:
    wiki_dir = os.path.join(wiki_path, "Wiki")
    os.makedirs(wiki_dir, exist_ok=True)

    # Schema
    ns_list = ", ".join(f"Wiki/{ns}" for ns in namespaces)
    schema = read_template("Schema.md")
    schema = schema.replace("{{NAMESPACES}}", ns_list)
    schema = schema.replace("{{DATE}}", today)
    if write_file(os.path.join(wiki_dir, "Schema.md"), schema):
        print(f"  Created: Wiki/Schema.md")

    # Dashboard
    ns_links = "\n".join(f"- [[Wiki/{ns}]]" for ns in namespaces)
    dashboard = read_template("Dashboard.md")
    dashboard = dashboard.replace("{{NAMESPACE_LINKS}}", ns_links)
    dashboard = dashboard.replace("{{DATE}}", today)
    if write_file(os.path.join(wiki_dir, "Dashboard.md"), dashboard):
        print(f"  Created: Wiki/Dashboard.md")

    # Hub pages
    hub_tpl = read_template("Hub.md")
    for ns in namespaces:
        ns_dir = os.path.join(wiki_dir, ns)
        os.makedirs(ns_dir, exist_ok=True)
        hub = hub_tpl.replace("{{NAMESPACE}}", ns).replace("{{DATE}}", today)
        if write_file(os.path.join(ns_dir, "_index.md"), hub):
            print(f"  Created: Wiki/{ns}/_index.md")

PYEOF

# ----- Step 9: Create llm-wiki.yml -----
CONFIG_FILE="$wiki_path/llm-wiki.yml"

write_config() {
    cat > "$CONFIG_FILE" << YAML
# llm-wiki configuration
# Generated by setup.sh on $(date +%Y-%m-%d)

tool: $TOOL
wiki_path: $wiki_path
pages_dir: $PAGES_DIR
memory_path: ${memory_path:-""}

namespaces:
$(for ns in $NAMESPACES; do echo "  - $ns"; done)
YAML
    echo -e "  ${GREEN}Created: llm-wiki.yml${NC}"
}

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}llm-wiki.yml already exists. Overwrite? [y/n]${NC}"
    read -p "" overwrite_config
    if [ "$overwrite_config" = "y" ] || [ "$overwrite_config" = "Y" ]; then
        write_config
    else
        echo -e "  Keeping existing config."
    fi
else
    write_config
fi

# ----- Step 10: Install /wiki skill -----
echo ""
echo -e "${BOLD}Install /wiki skill for Claude Code?${NC}"
echo "This copies wiki.md to your project's .claude/commands/ directory."
read -p "Project path (or 'skip'): " project_path

if [ "$project_path" != "skip" ] && [ -n "$project_path" ]; then
    project_path="${project_path/#\~/$HOME}"
    COMMANDS_DIR="$project_path/.claude/commands"
    mkdir -p "$COMMANDS_DIR"
    cp "$SCRIPT_DIR/wiki.md" "$COMMANDS_DIR/wiki.md"

    # Patch config path into skill
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "s|<CONFIG_PATH>|$CONFIG_FILE|g" "$COMMANDS_DIR/wiki.md"
    else
        sed -i "s|<CONFIG_PATH>|$CONFIG_FILE|g" "$COMMANDS_DIR/wiki.md"
    fi
    echo -e "${GREEN}Installed /wiki skill to $COMMANDS_DIR/wiki.md${NC}"
fi

# ----- Step 11: Initial commit -----
if [ -d "$wiki_path/.git" ]; then
    echo ""
    cd "$wiki_path"
    git add -A
    git commit -m "wiki: initial setup via llm-wiki

Schema, Dashboard, and hub pages for $(echo $NAMESPACES | wc -w | tr -d ' ') namespaces.
Tool: $TOOL

Generated by https://github.com/MehmetGoekce/llm-wiki" 2>/dev/null || true
    echo -e "${GREEN}Initial commit created.${NC}"
fi

# ----- Done -----
echo ""
echo -e "${CYAN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "Your wiki is at: ${BOLD}$wiki_path${NC}"
echo -e "Config file:     ${BOLD}$CONFIG_FILE${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Open your wiki in $TOOL"
echo -e "  2. In Claude Code, try: ${CYAN}/wiki ingest \"your first source\"${NC}"
echo -e "  3. Run ${CYAN}/wiki status${NC} to see your wiki metrics"
echo ""
echo -e "Documentation: ${CYAN}https://github.com/MehmetGoekce/llm-wiki${NC}"
