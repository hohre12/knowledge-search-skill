#!/bin/bash
set -e

echo "🔄 Knowledge Search Skill 업데이트 중..."

SKILL_DIR="$HOME/.openclaw/skills/knowledge-search-skill"

if [ ! -d "$SKILL_DIR" ]; then
    echo "❌ 스킬이 설치되어 있지 않습니다"
    echo "   설치: curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash"
    exit 1
fi

cd "$SKILL_DIR"

# 1. Git pull
echo "📥 최신 버전 다운로드 중..."
git pull origin main

# 2. 의존성 업데이트
echo "📦 의존성 업데이트 중..."
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo ""
echo "🎉 업데이트 완료!"
echo "   버전: $(git rev-parse --short HEAD)"
