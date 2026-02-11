# Knowledge Search Skill

OpenClaw/OpenCode/Claude Code CLI용 지식 검색 스킬

**특정 트리거 없이** 자연어로 대화하면 AI 에이전트가 자동으로 지식 베이스를 검색합니다.

## 🎯 자동 트리거

사용자가 "knowledge-search 스킬 사용해서..."라고 명시하지 않아도, 에이전트가 자동으로 판단하여 실행합니다:

```
❌ 명시 필요 없음: "knowledge-search 스킬로 프로젝트 찾아줘"
✅ 자연스럽게: "프로젝트 진행 상황 알려줘" → 자동 실행!
```

**자동 트리거 조건:**
- 과거 작업/프로젝트 질문 ("What did...", "When did...")
- 문서/노트 요청 ("Show me...", "Find...")
- 결정사항/이유 질문 ("Why did...", "What was...")
- 상태 확인 ("What's the current...")

## ✨ 특징

- 🔍 **자연어 검색**: "프로젝트 우선순위 알려줘" → 자동 검색
- 🌍 **다국어 지원**: 한국어/영어 자동 번역 (선택 가능)
- 🤖 **다중 모델**: OpenAI, Cohere 임베딩 / Claude, GPT 번역
- 📦 **공유 가능**: 같은 Supabase = 같은 지식 베이스
- 🔒 **격리 보장**: 각자 다른 Supabase = 완전 격리

## 🚀 설치 (30초)

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash
```

설치 중 입력:
1. Supabase URL & Key
2. 임베딩 모델 선택 (OpenAI/Cohere)
3. 번역 모델 선택 (Claude/GPT/없음)
4. API 키 입력

## 📊 Supabase 설정

1. https://supabase.com 에서 프로젝트 생성
2. SQL Editor에서 `schema.sql` 실행:

```bash
cat ~/.openclaw/skills/knowledge-search-skill/schema.sql
```

3. 테이블 생성 확인:

```sql
SELECT COUNT(*) FROM embeddings;
```

## 💬 사용 방법

### 자동 사용 (OpenClaw 권장)

OpenClaw에서 자연스럽게 대화하면 자동으로 스킬이 실행됩니다:

```
사용자: "바이브코딩 여정에서 배운 교훈 알려줘"
AI: (자동으로 ks search 실행) → 검색 결과 기반 답변

사용자: "프로젝트 진행 상황 알려줘"
AI: (자동으로 ks search 실행) → 답변

사용자: "팀 가이드에 뭐가 있었지?"
AI: (자동으로 ks search 실행) → 답변
```

**에이전트가 "검색 중입니다..."라고 말하지 않고 자연스럽게 결과를 제시합니다.**

### 수동 검색 (CLI)

직접 명령어로 검색:

```bash
ks search "검색어"
ks search "프로젝트 계획" --limit 10
ks search "긴급 작업" --author John
```

## 📝 나만의 문서 인덱싱 (선택)

```bash
# Obsidian 경로 설정
vi ~/.openclaw/skills/knowledge-search/config.json
# sources.obsidian.path 수정

# 폴더 인덱싱
ks ingest Notes
ks ingest Projects
ks ingest Projects/MyProject

# 상태 확인
ks status
```

## 🔄 업데이트

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/update.sh | bash
```

## 📂 구조

```
~/.openclaw/skills/knowledge-search/
├── SKILL.md              # 에이전트용 스킬 정의
├── config.json           # 설정 (API 키, Supabase)
├── requirements.txt      # Python 의존성
├── schema.sql            # Supabase 스키마
└── src/
    ├── cli.py            # CLI 진입점
    ├── search.py         # 검색 로직
    └── ingest.py         # 임베딩 로직
```

## 🔧 OpenClaw 통합

이 스킬은 OpenClaw의 **Eager Loading** 메커니즘을 사용합니다:

**Frontmatter 설정:**
```yaml
name: knowledge-search
user-invocable: true              # 슬래시 커맨드 지원
disable-model-invocation: false   # 에이전트 자동 실행 허용
metadata:
  openclaw:
    requires:
      bins: [python3, ks]         # 필수 명령어
```

**동작 방식:**
1. OpenClaw 시작 시 `requires.bins` 체크 (python3, ks)
2. 통과하면 SKILL.md 전체 내용을 시스템 프롬프트에 주입
3. 에이전트가 "Automatic Usage" 섹션을 읽고 자동 판단
4. 트리거 패턴 일치 시 `ks search` 자동 실행

**사용자 경험:**
- ✅ 설치만 하면 끝 (추가 설정 불필요)
- ✅ 자연스러운 대화로 검색
- ✅ "스킬 사용해서..." 명시 불필요

## 🤝 지식 공유

**같은 팀에서 지식 공유하려면?**

1. 팀원 A가 Supabase 프로젝트 생성 + 문서 인덱싱
2. 팀원 B, C가 설치할 때 같은 Supabase URL/Key 입력
3. 모두 같은 지식 베이스 사용 ✅

**개인용으로 완전 격리하려면?**

각자 다른 Supabase 프로젝트 사용

## 💰 비용

- **검색**: ~$0.00001/회
- **인덱싱**: 문서 크기에 따라 $0.001~$0.01/파일

예시: 500개 문서 인덱싱 = $0.50

## 🛠️ CLI 명령어

```bash
ks search <query>         # 검색
ks ingest <folder>        # 폴더 인덱싱
ks status                 # 상태 확인
ks --help                 # 도움말
```

## 📚 지원 플랫폼

- ✅ OpenClaw (권장)
- ✅ OpenCode
- ✅ Claude Code CLI

## 🔗 링크

- GitHub: https://github.com/hohre12/knowledge-search-skill
- Supabase: https://supabase.com
- OpenClaw: https://openclaw.ai
