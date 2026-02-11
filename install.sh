#!/bin/bash
set -e

# Knowledge Search Skill Installer
REPO="hohre12/knowledge-search-skill"
BRANCH="main"
INSTALL_DIR="$HOME/.openclaw/skills/knowledge-search-skill"

echo "📦 Knowledge Search Skill Installation..."
echo ""

# 1. Check existing installation
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  Already installed: $INSTALL_DIR"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
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

# Move to install directory
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$TEMP_DIR" "$INSTALL_DIR"
cd "$INSTALL_DIR"

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
echo "🔧 Registering CLI command..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Register ks CLI
KS_BIN="/opt/homebrew/bin/ks"
if [ ! -f "$KS_BIN" ]; then
    cat > "$KS_BIN" << 'EOFCLI'
#!/bin/bash
cd "$HOME/.openclaw/skills/knowledge-search-skill"
source venv/bin/activate
python src/cli.py "$@"
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
echo "📁 Install location: $INSTALL_DIR"
echo ""
echo "✨ Start using in OpenClaw/OpenCode/Claude Code CLI"
echo "   The agent will automatically search your knowledge base."
echo ""
echo "💡 Additional options:"
echo "   - Index your documents: ks ingest <folder>"
echo "   - Test search: ks search \"query\""
echo "   - Check status: ks status"
echo ""
