#!/bin/bash
set -e

# Knowledge Search Skill Installer
REPO="hohre12/knowledge-search-skill"
BRANCH="main"

echo "📦 Knowledge Search Skill Installation..."
echo ""

# 1. Select installation targets
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Select Installation Target(s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v gum &> /dev/null; then
    # Use gum for OpenClaw-style UI
    SELECTIONS=$(gum choose --no-limit \
        "OpenClaw (~/.openclaw/skills/)" \
        "OpenCode (~/.config/opencode/skills/)" \
        "Claude Code CLI (~/.claude/skills/)" \
        < /dev/tty)
    
    INSTALL_OPENCLAW=0
    INSTALL_OPENCODE=0
    INSTALL_CLAUDE=0
    
    # Parse selections
    while IFS= read -r line; do
        case "$line" in
            *"OpenClaw"*) INSTALL_OPENCLAW=1 ;;
            *"OpenCode"*) INSTALL_OPENCODE=1 ;;
            *"Claude"*) INSTALL_CLAUDE=1 ;;
        esac
    done <<< "$SELECTIONS"
    
elif command -v whiptail &> /dev/null; then
    # Use whiptail for interactive checkbox
    SELECTIONS=$(whiptail --title "Knowledge Search Installation" \
        --checklist "Select installation targets (Space to select, Enter to confirm):" 15 70 3 \
        "1" "OpenClaw (~/.openclaw/skills/)" ON \
        "2" "OpenCode (~/.config/opencode/skills/)" OFF \
        "3" "Claude Code CLI (~/.claude/skills/)" OFF \
        3>&1 1>&2 2>&3)
    
    # Check if user cancelled
    if [ $? -ne 0 ]; then
        echo "❌ Installation cancelled"
        exit 1
    fi
    
    INSTALL_OPENCLAW=0
    INSTALL_OPENCODE=0
    INSTALL_CLAUDE=0
    
    # Parse selections (whiptail returns quoted numbers like "1" "2")
    for target in $SELECTIONS; do
        # Remove quotes
        target=$(echo $target | tr -d '"')
        case $target in
            1) INSTALL_OPENCLAW=1 ;;
            2) INSTALL_OPENCODE=1 ;;
            3) INSTALL_CLAUDE=1 ;;
        esac
    done
else
    # Fallback to simple text input
    echo "  [1] OpenClaw (~/.openclaw/skills/)"
    echo "  [2] OpenCode (~/.config/opencode/skills/)"
    echo "  [3] Claude Code CLI (~/.claude/skills/)"
    echo ""
    echo "💡 Enter numbers (space separated, e.g., 1 2 3 for all)"
    echo ""
    read -p "Select: " TARGETS < /dev/tty
    
    INSTALL_OPENCLAW=0
    INSTALL_OPENCODE=0
    INSTALL_CLAUDE=0
    
    # Parse selections
    for target in $TARGETS; do
        case $target in
            1) INSTALL_OPENCLAW=1 ;;
            2) INSTALL_OPENCODE=1 ;;
            3) INSTALL_CLAUDE=1 ;;
        esac
    done
fi

# Validate at least one selection
if [ $INSTALL_OPENCLAW -eq 0 ] && [ $INSTALL_OPENCODE -eq 0 ] && [ $INSTALL_CLAUDE -eq 0 ]; then
    echo ""
    echo "❌ No target selected. Exiting."
    exit 1
fi

# Show selected targets
echo ""
echo "Selected targets:"
[ $INSTALL_OPENCLAW -eq 1 ] && echo "  ✅ OpenClaw"
[ $INSTALL_OPENCODE -eq 1 ] && echo "  ✅ OpenCode"
[ $INSTALL_CLAUDE -eq 1 ] && echo "  ✅ Claude Code CLI"
echo ""

# Primary install directory (full installation)
if [ $INSTALL_OPENCLAW -eq 1 ]; then
    PRIMARY_DIR="$HOME/.openclaw/skills/knowledge-search-skill"
elif [ $INSTALL_OPENCODE -eq 1 ]; then
    PRIMARY_DIR="$HOME/.config/opencode/skills/knowledge-search"
else
    PRIMARY_DIR="$HOME/.claude/skills/knowledge-search"
fi

# Check existing installation
if [ -d "$PRIMARY_DIR" ]; then
    if command -v gum &> /dev/null; then
        if gum confirm "Already installed at $PRIMARY_DIR. Remove and reinstall?" < /dev/tty; then
            rm -rf "$PRIMARY_DIR"
            echo "✅ Removed existing installation"
        else
            echo "❌ Installation cancelled"
            exit 1
        fi
    elif command -v whiptail &> /dev/null; then
        if whiptail --title "Already Installed" --yesno "Already installed at:\n$PRIMARY_DIR\n\nRemove and reinstall?" 10 70; then
            rm -rf "$PRIMARY_DIR"
            echo "✅ Removed existing installation"
        else
            echo "❌ Installation cancelled"
            exit 1
        fi
    else
        echo "⚠️  Already installed: $PRIMARY_DIR"
        read -p "Remove and reinstall? (y/N): " -n 1 -r < /dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PRIMARY_DIR"
            echo "✅ Removed existing installation"
        else
            echo "❌ Installation cancelled"
            exit 1
        fi
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Supabase Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Same Supabase = Shared knowledge base"
echo ""

if command -v gum &> /dev/null; then
    SUPABASE_URL=$(gum input --placeholder "Supabase URL (e.g., https://xxx.supabase.co)" < /dev/tty)
    SUPABASE_KEY=$(gum input --placeholder "Supabase anon key" --password < /dev/tty)
elif command -v whiptail &> /dev/null; then
    SUPABASE_URL=$(whiptail --title "Supabase URL" --inputbox "Enter Supabase URL (e.g., https://xxx.supabase.co):" 10 70 3>&1 1>&2 2>&3)
    SUPABASE_KEY=$(whiptail --title "Supabase Key" --inputbox "Enter Supabase anon key:" 10 70 3>&1 1>&2 2>&3)
else
    read -p "Supabase URL (e.g., https://xxx.supabase.co): " SUPABASE_URL < /dev/tty
    read -p "Supabase Key (anon key): " SUPABASE_KEY < /dev/tty
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Embedding Model Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v gum &> /dev/null; then
    EMBEDDING_SELECTION=$(gum choose \
        "OpenAI text-embedding-3-small (Recommended, \$0.002/1M tokens)" \
        "OpenAI text-embedding-3-large (\$0.013/1M tokens)" \
        "Cohere embed-multilingual-v3.0 (Multilingual)" \
        < /dev/tty)
    
    case "$EMBEDDING_SELECTION" in
        *"3-small"*)
            EMBEDDING_PROVIDER="openai"
            EMBEDDING_MODEL="text-embedding-3-small"
            EMBEDDING_API_KEY=$(gum input --placeholder "Enter OpenAI API Key (sk-proj-...)" < /dev/tty)
            ;;
        *"3-large"*)
            EMBEDDING_PROVIDER="openai"
            EMBEDDING_MODEL="text-embedding-3-large"
            EMBEDDING_API_KEY=$(gum input --placeholder "Enter OpenAI API Key (sk-proj-...)" < /dev/tty)
            ;;
        *"Cohere"*)
            EMBEDDING_PROVIDER="cohere"
            EMBEDDING_MODEL="embed-multilingual-v3.0"
            EMBEDDING_API_KEY=$(gum input --placeholder "Enter Cohere API Key" < /dev/tty)
            ;;
        *)
            echo "❌ Invalid selection: '$EMBEDDING_SELECTION'"
            exit 1
            ;;
    esac
    
else
    # Fallback to whiptail or text input
    if command -v whiptail &> /dev/null; then
        EMBEDDING_CHOICE=$(whiptail --title "Embedding Model" --menu "Select embedding model:" 15 70 3 \
            "1" "OpenAI text-embedding-3-small (Recommended, \$0.002/1M)" \
            "2" "OpenAI text-embedding-3-large (\$0.013/1M)" \
            "3" "Cohere embed-multilingual-v3.0 (Multilingual)" \
            3>&1 1>&2 2>&3)
    else
        echo "  [1] OpenAI text-embedding-3-small (Recommended, \$0.002/1M tokens)"
        echo "  [2] OpenAI text-embedding-3-large (\$0.013/1M tokens)"
        echo "  [3] Cohere embed-multilingual-v3.0 (Multilingual)"
        echo ""
        read -p "Select (1-3): " -n 1 -r EMBEDDING_CHOICE < /dev/tty
        echo ""
    fi

    echo ""
    case $EMBEDDING_CHOICE in
    1)
        EMBEDDING_PROVIDER="openai"
        EMBEDDING_MODEL="text-embedding-3-small"
        if command -v whiptail &> /dev/null; then
            EMBEDDING_API_KEY=$(whiptail --title "OpenAI API Key" --inputbox "Enter OpenAI API Key (sk-proj-...):" 10 70 3>&1 1>&2 2>&3)
        else
            read -p "OpenAI API Key (sk-proj-...): " EMBEDDING_API_KEY < /dev/tty
        fi
        ;;
    2)
        EMBEDDING_PROVIDER="openai"
        EMBEDDING_MODEL="text-embedding-3-large"
        if command -v whiptail &> /dev/null; then
            EMBEDDING_API_KEY=$(whiptail --title "OpenAI API Key" --inputbox "Enter OpenAI API Key (sk-proj-...):" 10 70 3>&1 1>&2 2>&3)
        else
            read -p "OpenAI API Key (sk-proj-...): " EMBEDDING_API_KEY < /dev/tty
        fi
        ;;
    3)
        EMBEDDING_PROVIDER="cohere"
        EMBEDDING_MODEL="embed-multilingual-v3.0"
        if command -v whiptail &> /dev/tty; then
            EMBEDDING_API_KEY=$(whiptail --title "Cohere API Key" --inputbox "Enter Cohere API Key:" 10 70 3>&1 1>&2 2>&3)
        else
            read -p "Cohere API Key: " EMBEDDING_API_KEY < /dev/tty
        fi
        ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
    esac
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 Translation Model Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v gum &> /dev/null; then
    TRANSLATION_SELECTION=$(gum choose \
        "Claude Sonnet 4.5 (Recommended, Best quality)" \
        "GPT-4o (OpenAI)" \
        "No translation (English documents only)" \
        < /dev/tty)
    
    case "$TRANSLATION_SELECTION" in
        *"Claude"*)
            TRANSLATION_PROVIDER="anthropic"
            TRANSLATION_MODEL="claude-sonnet-4-5-20250929"
            TRANSLATION_API_KEY=$(gum input --placeholder "Enter Claude API Key (sk-ant-...)" < /dev/tty)
            ;;
        *"GPT-4o"*)
            TRANSLATION_PROVIDER="openai"
            TRANSLATION_MODEL="gpt-4o"
            TRANSLATION_API_KEY=$(gum input --placeholder "Enter OpenAI API Key (sk-proj-...)" < /dev/tty)
            ;;
        *"No translation"*)
            TRANSLATION_PROVIDER="none"
            TRANSLATION_MODEL=""
            TRANSLATION_API_KEY=""
            ;;
        *)
            echo "❌ Invalid selection: '$TRANSLATION_SELECTION'"
            exit 1
            ;;
    esac
    
else
    # Fallback to whiptail or text input
    if command -v whiptail &> /dev/null; then
        TRANSLATION_CHOICE=$(whiptail --title "Translation Model" --menu "Select translation model:" 15 70 3 \
            "1" "Claude Sonnet 4.5 (Recommended, Best quality)" \
            "2" "GPT-4o (OpenAI)" \
            "3" "No translation (English documents only)" \
            3>&1 1>&2 2>&3)
    else
        echo "  [1] Claude Sonnet 4.5 (Recommended, Best quality)"
        echo "  [2] GPT-4o (OpenAI)"
        echo "  [3] No translation (English documents only)"
        echo ""
        read -p "Select (1-3): " -n 1 -r TRANSLATION_CHOICE < /dev/tty
        echo ""
    fi

    echo ""
    case $TRANSLATION_CHOICE in
    1)
        TRANSLATION_PROVIDER="anthropic"
        TRANSLATION_MODEL="claude-sonnet-4-5-20250929"
        if command -v whiptail &> /dev/null; then
            TRANSLATION_API_KEY=$(whiptail --title "Claude API Key" --inputbox "Enter Claude API Key (sk-ant-...):" 10 70 3>&1 1>&2 2>&3)
        else
            read -p "Claude API Key (sk-ant-...): " TRANSLATION_API_KEY < /dev/tty
        fi
        ;;
    2)
        TRANSLATION_PROVIDER="openai"
        TRANSLATION_MODEL="gpt-4o"
        if command -v whiptail &> /dev/null; then
            TRANSLATION_API_KEY=$(whiptail --title "OpenAI API Key" --inputbox "Enter OpenAI API Key (sk-proj-...):" 10 70 3>&1 1>&2 2>&3)
        else
            read -p "OpenAI API Key (sk-proj-...): " TRANSLATION_API_KEY < /dev/tty
        fi
        ;;
    3)
        TRANSLATION_PROVIDER="none"
        TRANSLATION_MODEL=""
        TRANSLATION_API_KEY=""
        ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
    esac
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Downloading files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# List of files to download
FILES=(
    "SKILL.md"
    "README.md"
    "requirements.txt"
    "schema.sql"
    "setup.py"
    "src/__init__.py"
    "src/cli.py"
    "src/search.py"
    "src/ingest.py"
)

# Download files from GitHub
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

mkdir -p src
for file in "${FILES[@]}"; do
    echo "  - $file"
    curl -sSL "$BASE_URL/$file" -o "$file"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐍 Setting up Python environment..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Move to primary install directory
mkdir -p "$(dirname "$PRIMARY_DIR")"
mv "$TEMP_DIR" "$PRIMARY_DIR"
cd "$PRIMARY_DIR"

# Create Python virtual environment
python3 -m venv venv

# Install dependencies
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Creating config file..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create config.json
cat > config.json << EOF
{
  "supabase": {
    "url": "$SUPABASE_URL",
    "key": "$SUPABASE_KEY"
  },
  "embedding": {
    "provider": "$EMBEDDING_PROVIDER",
    "model": "$EMBEDDING_MODEL",
    "api_key": "$EMBEDDING_API_KEY"
  },
  "translation": {
    "provider": "$TRANSLATION_PROVIDER",
    "model": "$TRANSLATION_MODEL",
    "api_key": "$TRANSLATION_API_KEY"
  },
  "search": {
    "default_limit": 5,
    "min_similarity": 35.0
  },
  "sources": {
    "obsidian": {
      "path": "~/Documents/ObsidianVault",
      "enabled": false
    }
  }
}
EOF

echo "✅ config.json created"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Creating symlinks for other targets..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlinks for other selected targets
if [ $INSTALL_OPENCLAW -eq 1 ] && [ "$PRIMARY_DIR" != "$HOME/.openclaw/skills/knowledge-search-skill" ]; then
    OPENCLAW_DIR="$HOME/.openclaw/skills/knowledge-search-skill"
    if [ ! -e "$OPENCLAW_DIR" ]; then
        mkdir -p "$(dirname "$OPENCLAW_DIR")"
        ln -s "$PRIMARY_DIR" "$OPENCLAW_DIR"
        echo "✅ OpenClaw symlink created"
    fi
fi

if [ $INSTALL_OPENCODE -eq 1 ] && [ "$PRIMARY_DIR" != "$HOME/.config/opencode/skills/knowledge-search" ]; then
    OPENCODE_DIR="$HOME/.config/opencode/skills/knowledge-search"
    if [ ! -e "$OPENCODE_DIR" ]; then
        mkdir -p "$(dirname "$OPENCODE_DIR")"
        ln -s "$PRIMARY_DIR" "$OPENCODE_DIR"
        echo "✅ OpenCode symlink created"
    fi
fi

if [ $INSTALL_CLAUDE -eq 1 ] && [ "$PRIMARY_DIR" != "$HOME/.claude/skills/knowledge-search" ]; then
    CLAUDE_DIR="$HOME/.claude/skills/knowledge-search"
    if [ ! -e "$CLAUDE_DIR" ]; then
        mkdir -p "$(dirname "$CLAUDE_DIR")"
        ln -s "$PRIMARY_DIR" "$CLAUDE_DIR"
        echo "✅ Claude Code CLI symlink created"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Registering CLI command..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Register ks CLI
KS_BIN="/opt/homebrew/bin/ks"
if [ ! -f "$KS_BIN" ]; then
    cat > "$KS_BIN" << EOFCLI
#!/bin/bash
cd "$PRIMARY_DIR"
source venv/bin/activate
python src/cli.py "\$@"
EOFCLI
    chmod +x "$KS_BIN"
    echo "✅ ks command registered"
else
    echo "⚠️  ks command already exists"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Primary install: $PRIMARY_DIR"
echo ""
echo "Installed to:"
[ $INSTALL_OPENCLAW -eq 1 ] && echo "  ✅ OpenClaw"
[ $INSTALL_OPENCODE -eq 1 ] && echo "  ✅ OpenCode"
[ $INSTALL_CLAUDE -eq 1 ] && echo "  ✅ Claude Code CLI"
echo ""
echo "✨ Start using in your selected AI tools"
echo "   The agent will automatically search your knowledge base."
echo ""
echo "💡 Additional options:"
echo "   - Index your documents: ks ingest <folder>"
echo "   - Test search: ks search \"query\""
echo "   - Check status: ks status"
echo ""
