#!/bin/bash
set -e

echo "🗑️  Knowledge Search Skill 삭제"
echo ""

REMOVED=0

# 1. OpenClaw
OPENCLAW_DIR="$HOME/.openclaw/skills/knowledge-search-skill"
if [ -d "$OPENCLAW_DIR" ] || [ -L "$OPENCLAW_DIR" ]; then
    rm -rf "$OPENCLAW_DIR"
    echo "✅ OpenClaw 삭제: $OPENCLAW_DIR"
    REMOVED=1
fi

# 2. OpenCode
OPENCODE_DIR="$HOME/.config/opencode/skills/knowledge-search"
if [ -d "$OPENCODE_DIR" ] || [ -L "$OPENCODE_DIR" ]; then
    rm -rf "$OPENCODE_DIR"
    echo "✅ OpenCode 삭제: $OPENCODE_DIR"
    REMOVED=1
fi

# 3. Claude Code CLI
CLAUDE_DIR="$HOME/.claude/skills/knowledge-search"
if [ -d "$CLAUDE_DIR" ] || [ -L "$CLAUDE_DIR" ]; then
    rm -rf "$CLAUDE_DIR"
    echo "✅ Claude Code 삭제: $CLAUDE_DIR"
    REMOVED=1
fi

# 4. CLI 명령어 삭제
for KS_BIN in /usr/local/bin/ks /opt/homebrew/bin/ks; do
    if [ -f "$KS_BIN" ]; then
        rm "$KS_BIN"
        echo "✅ ks 명령어 삭제: $KS_BIN"
        REMOVED=1
    fi
done

if [ $REMOVED -eq 0 ]; then
    echo "⚠️  설치된 스킬을 찾을 수 없습니다"
else
    echo ""
    echo "🎉 삭제 완료!"
fi
