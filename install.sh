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
echo "  1) OpenClaw (~/.openclaw/skills/)"
echo "  2) OpenCode (~/.config/opencode/skills/)"
echo "  3) Claude Code CLI (~/.claude/skills/)"
echo ""
echo "💡 You can select multiple (e.g., 1 2 3 or 1,2,3)"
echo ""
read -p "Select (space or comma separated): " TARGETS

# Parse selections
INSTALL_OPENCLAW=0
INSTALL_OPENCODE=0
INSTALL_CLAUDE=0

# Remove commas and process
TARGETS=$(echo "$TARGETS" | tr ',' ' ')

for target in $TARGETS; do
    case $target in
        1) INSTALL_OPENCLAW=1 ;;
        2) INSTALL_OPENCODE=1 ;;
        3) INSTALL_CLAUDE=1 ;;
    esac
done

# Validate at least one selection
if [ $INSTALL_OPENCLAW -eq 0 ] && [ $INSTALL_OPENCODE -eq 0 ] && [ $INSTALL_CLAUDE -eq 0 ]; then
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
    echo "⚠️  Already installed: $PRIMARY_DIR"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PRIMARY_DIR"
        echo "✅ Removed existing installation"
    else
        echo "❌ Installation cancelled"
        exit 1
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Supabase Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Same Supabase = Shared knowledge base"
echo ""

read -p "Supabase URL (e.g., https://xxx.supabase.co): " SUPABASE_URL
read -p "Supabase Key (anon key): " SUPABASE_KEY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Embedding Model Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) OpenAI text-embedding-3-small (Recommended, \$0.002/1M tokens)"
echo "  2) OpenAI text-embedding-3-large (\$0.013/1M tokens)"
echo "  3) Cohere embed-multilingual-v3.0 (Multilingual)"
echo ""
read -p "Select (1-3): " -n 1 -r EMBEDDING_CHOICE
echo ""
echo ""

case $EMBEDDING_CHOICE in
    1)
        EMBEDDING_PROVIDER="openai"
        EMBEDDING_MODEL="text-embedding-3-small"
        read -p "OpenAI API Key (sk-proj-...): " EMBEDDING_API_KEY
        ;;
    2)
        EMBEDDING_PROVIDER="openai"
        EMBEDDING_MODEL="text-embedding-3-large"
        read -p "OpenAI API Key (sk-proj-...): " EMBEDDING_API_KEY
        ;;
    3)
        EMBEDDING_PROVIDER="cohere"
        EMBEDDING_MODEL="embed-multilingual-v3.0"
        read -p "Cohere API Key: " EMBEDDING_API_KEY
        ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 Translation Model Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) Claude Sonnet 4.5 (Recommended, Best quality)"
echo "  2) GPT-4o (OpenAI)"
echo "  3) No translation (English documents only)"
echo ""
read -p "Select (1-3): " -n 1 -r TRANSLATION_CHOICE
echo ""
echo ""

case $TRANSLATION_CHOICE in
    1)
        TRANSLATION_PROVIDER="anthropic"
        TRANSLATION_MODEL="claude-sonnet-4-5-20250929"
        read -p "Claude API Key (sk-ant-...): " TRANSLATION_API_KEY
        ;;
    2)
        TRANSLATION_PROVIDER="openai"
        TRANSLATION_MODEL="gpt-4o"
        read -p "OpenAI API Key (sk-proj-...): " TRANSLATION_API_KEY
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
if [ $INSTALL_OPENCLAW -eq 0 ]; then
    # If OpenClaw not primary, maybe create symlink
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
