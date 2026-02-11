#!/bin/bash
set -e

REPO="hohre12/knowledge-search-skill"
BRANCH="main"
INSTALL_DIR="$HOME/.openclaw/skills/knowledge-search-skill"

echo "📦 Knowledge Search Skill 설치 시작..."
echo ""

# 1. 기존 설치 확인
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  이미 설치되어 있습니다: $INSTALL_DIR"
    read -p "삭제하고 재설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo "✅ 기존 설치 삭제 완료"
    else
        echo "❌ 설치 취소"
        exit 1
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Supabase 설정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 같은 Supabase 정보 입력 = 같은 지식 베이스 공유"
echo ""

read -p "Supabase URL (예: https://xxx.supabase.co): " SUPABASE_URL
read -p "Supabase Key (anon key): " SUPABASE_KEY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 임베딩 모델 선택"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) OpenAI text-embedding-3-small (권장, $0.002/1M tokens)"
echo "  2) OpenAI text-embedding-3-large ($0.013/1M tokens)"
echo "  3) Cohere embed-multilingual-v3.0 (다국어)"
echo ""
read -p "선택 (1-3): " -n 1 -r EMBEDDING_CHOICE
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
        echo "❌ 잘못된 선택"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 번역 모델 선택 (한국어 문서용)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) Claude Sonnet 4.5 (권장, 최고 품질)"
echo "  2) GPT-4o (OpenAI)"
echo "  3) 번역 안 함 (영어 문서만 사용)"
echo ""
read -p "선택 (1-3): " -n 1 -r TRANSLATION_CHOICE
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
        echo "❌ 잘못된 선택"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 파일 다운로드 중..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# 다운로드할 파일 목록
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

# GitHub raw URL에서 파일 다운로드
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

mkdir -p src
for file in "${FILES[@]}"; do
    echo "  - $file"
    curl -sSL "$BASE_URL/$file" -o "$file"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐍 Python 환경 설정 중..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 설치 디렉토리로 이동
mkdir -p "$(dirname "$INSTALL_DIR")"
mv "$TEMP_DIR" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Python 가상환경 생성
python3 -m venv venv

# 의존성 설치
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  설정 파일 생성 중..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# config.json 생성
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

echo "✅ config.json 생성 완료"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CLI 명령어 등록 중..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ks CLI 등록
KS_BIN="/opt/homebrew/bin/ks"
if [ ! -f "$KS_BIN" ]; then
    cat > "$KS_BIN" << 'EOFCLI'
#!/bin/bash
cd "$HOME/.openclaw/skills/knowledge-search-skill"
source venv/bin/activate
python src/cli.py "$@"
EOFCLI
    chmod +x "$KS_BIN"
    echo "✅ ks 명령어 등록 완료"
else
    echo "⚠️  ks 명령어 이미 존재"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 설치 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 설치 위치: $INSTALL_DIR"
echo ""
echo "✨ 이제 OpenClaw/OpenCode/Claude Code CLI에서"
echo "   자연스럽게 대화하세요. 에이전트가 자동으로"
echo "   지식 베이스를 검색합니다."
echo ""
echo "💡 추가 작업 (선택):"
echo "   - 나만의 문서 인덱싱: ks ingest <folder>"
echo "   - 검색 테스트: ks search \"쿼리\""
echo "   - 상태 확인: ks status"
echo ""
