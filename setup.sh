#!/bin/bash
set -e

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

# ----- Step 7: Detect script location -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/$TOOL"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}Templates not found at $TEMPLATE_DIR${NC}"
    echo "Make sure you're running this from the llm-wiki repository."
    exit 1
fi

# ----- Step 8: Create Schema -----
echo -e "${BOLD}Creating wiki pages...${NC}"

# Build namespace list for templates
if [ "$TOOL" = "logseq" ]; then
    # Logseq: Schema page
    SCHEMA_FILE="$pages_path/Wiki___Schema.md"
    NS_LIST=""
    for ns in $NAMESPACES; do
        NS_LIST="$NS_LIST\n\t- Wiki/$ns"
    done
    sed "s|{{NAMESPACES}}|$(echo -e "$NS_LIST")|g" "$TEMPLATE_DIR/Schema.md" > "$SCHEMA_FILE"
    echo -e "  ${GREEN}Created: Wiki/Schema${NC}"

    # Dashboard
    DASHBOARD_FILE="$pages_path/Wiki___Dashboard.md"
    NS_LINKS=""
    for ns in $NAMESPACES; do
        NS_LINKS="$NS_LINKS\n\t- [[Wiki/$ns]]"
    done
    sed "s|{{NAMESPACE_LINKS}}|$(echo -e "$NS_LINKS")|g" "$TEMPLATE_DIR/Dashboard.md" > "$DASHBOARD_FILE"
    echo -e "  ${GREEN}Created: Wiki/Dashboard${NC}"

    # Hub pages for each namespace
    for ns in $NAMESPACES; do
        HUB_FILE="$pages_path/Wiki___${ns}.md"
        sed "s|{{NAMESPACE}}|$ns|g" "$TEMPLATE_DIR/Hub.md" > "$HUB_FILE"
        echo -e "  ${GREEN}Created: Wiki/$ns${NC}"
    done

else
    # Obsidian: folder hierarchy
    WIKI_DIR="$wiki_path/Wiki"
    mkdir -p "$WIKI_DIR"

    # Schema
    NS_LIST=""
    for ns in $NAMESPACES; do
        NS_LIST="$NS_LIST\n- Wiki/$ns"
    done
    sed "s|{{NAMESPACES}}|$(echo -e "$NS_LIST")|g" "$TEMPLATE_DIR/Schema.md" > "$WIKI_DIR/Schema.md"
    echo -e "  ${GREEN}Created: Wiki/Schema.md${NC}"

    # Dashboard
    NS_LINKS=""
    for ns in $NAMESPACES; do
        NS_LINKS="$NS_LINKS\n- [[Wiki/$ns]]"
    done
    sed "s|{{NAMESPACE_LINKS}}|$(echo -e "$NS_LINKS")|g" "$TEMPLATE_DIR/Dashboard.md" > "$WIKI_DIR/Dashboard.md"
    echo -e "  ${GREEN}Created: Wiki/Dashboard.md${NC}"

    # Hub pages
    for ns in $NAMESPACES; do
        NS_DIR="$WIKI_DIR/$ns"
        mkdir -p "$NS_DIR"
        sed "s|{{NAMESPACE}}|$ns|g" "$TEMPLATE_DIR/Hub.md" > "$NS_DIR/_index.md"
        echo -e "  ${GREEN}Created: Wiki/$ns/_index.md${NC}"
    done
fi

# ----- Step 9: Create config.yml -----
CONFIG_FILE="$wiki_path/llm-wiki.yml"
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
