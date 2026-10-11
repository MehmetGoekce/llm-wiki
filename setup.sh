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
wiki_path="$(cd "$wiki_path" && pwd)"
echo ""

# ----- Step 3: Namespaces -----
DEFAULT_NS="Business Tech Content Projects People Learning Reference"
echo -e "${BOLD}Which namespaces do you want?${NC}"
echo -e "Default: ${CYAN}$DEFAULT_NS${NC}"
read -p "Enter space-separated list (or press Enter for default): " custom_ns
NAMESPACES="${custom_ns:-$DEFAULT_NS}"
echo -e "${GREEN}Namespaces: $NAMESPACES${NC}"
echo ""

# ----- Step 4: Memory path -----
echo -e "${BOLD}Where is your Claude Code memory directory?${NC}"
echo -e "(Usually: ~/.claude/projects/<project>/memory/)"
read -p "Path [skip]: " memory_path
if [ "$memory_path" = "skip" ]; then
    memory_path=""
fi
echo ""

# ----- Step 5: Git init -----
INIT_ARGS=(--tool "$TOOL" --wiki-path "$wiki_path" --namespaces "$NAMESPACES" --commit)
if [ -n "$memory_path" ]; then
    INIT_ARGS+=(--memory-path "$memory_path")
fi

if [ ! -d "$wiki_path/.git" ]; then
    echo -e "${BOLD}Initialize git in $wiki_path?${NC} [y/n]"
    read -p "" init_git
    if [ "$init_git" = "y" ] || [ "$init_git" = "Y" ]; then
        INIT_ARGS+=(--git-init)
    fi
fi
echo ""

# ----- Step 6: Existing config -----
CONFIG_FILE="$wiki_path/llm-wiki.yml"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}llm-wiki.yml already exists. Overwrite? [y/n]${NC}"
    read -p "" overwrite_config
    if [ "$overwrite_config" = "y" ] || [ "$overwrite_config" = "Y" ]; then
        rm "$CONFIG_FILE"
    else
        echo -e "  Keeping existing config."
    fi
fi

# ----- Step 7: Create pages, config and initial commit -----
echo -e "${BOLD}Creating wiki pages...${NC}"
"$SCRIPT_DIR/scripts/init-wiki.sh" "${INIT_ARGS[@]}" | sed 's/^/  /'

# ----- Step 8: Install /wiki skill -----
echo ""
echo -e "${BOLD}Install /wiki skill for Claude Code?${NC}"
echo "Recommended instead: install the llm-wiki plugin (see README), which updates itself."
echo "This step copies the skill to one project's .claude/commands/ directory; the copy does not update."
read -p "Project path (or 'skip'): " project_path

if [ "$project_path" != "skip" ] && [ -n "$project_path" ]; then
    project_path="${project_path/#\~/$HOME}"
    COMMANDS_DIR="$project_path/.claude/commands"
    mkdir -p "$COMMANDS_DIR"

    # The skill names the wiki root as a plugin option; a copied skill gets the path written in.
    python3 - "$SCRIPT_DIR/skills/wiki/SKILL.md" "$COMMANDS_DIR/wiki.md" "$wiki_path" << 'PYEOF'
import sys

source, target, wiki_path = sys.argv[1:4]
with open(source) as f:
    skill = f.read()
with open(target, "w") as f:
    f.write(skill.replace("${user_config.wiki_path}", wiki_path))
PYEOF

    if grep -q '\${user_config\.' "$COMMANDS_DIR/wiki.md"; then
        echo -e "${YELLOW}Warning: $COMMANDS_DIR/wiki.md still contains a plugin placeholder.${NC}"
    fi
    echo -e "${GREEN}Installed /wiki skill to $COMMANDS_DIR/wiki.md${NC}"
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
echo -e "  4. For automatic updates, install the plugin: ${CYAN}claude plugin marketplace add MehmetGoekce/llm-wiki${NC}"
echo ""
echo -e "Documentation: ${CYAN}https://github.com/MehmetGoekce/llm-wiki${NC}"
