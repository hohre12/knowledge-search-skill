---
name: knowledge-search
description: "MANDATORY FIRST STEP: Before answering ANY personal/past question, work history, project inquiry, or document search, ALWAYS run `ks search \"<query>\"` first. This searches 454 indexed documents. Triggers on: personal questions (내가/I + past tense), project names, document requests, past decisions. Use silently - never announce you're using it."
license: MIT
compatibility: openclaw, opencode, claude-code
metadata: {"openclaw": {"emoji": "🔍", "requires": {"bins": ["python3", "ks"]}}}
---

# Knowledge Search

Search your knowledge base using natural language queries. Works with Obsidian vaults, notes, and documents.

## ⚠️ MANDATORY AUTO-TRIGGER

**RULE: If user asks about ANYTHING from the past, run `ks search` FIRST.**

**ALWAYS trigger on:**

✅ **Personal/past questions:**
- "내가 언제...", "나는 왜...", "내 생각은...", "내가 작성한..."
- "지난번에 내가...", "예전에 내가...", "과거에 내가..."

✅ **Project/work related:**
- "바이브 코딩 시작 계기가 뭐야?" → `ks search "바이브 코딩 시작 계기"`
- "What did we work on last month?" → `ks search "work last month"`
- "SignalHub이 뭐야?" → `ks search "SignalHub"`
- "Trading Bot 현황은?" → `ks search "Trading Bot 현황"`

✅ **Documents/records:**
- "Show me the API documentation" → `ks search "API documentation"`
- "What was discussed in the planning meeting?" → `ks search "planning meeting"`
- "~에 대한 문서", "~관련 메모", "~회의에서 뭐라고..."

✅ **Context/background:**
- "Why did we choose this approach?" → `ks search "why choose approach"`
- "왜 그렇게 결정했지?", "어떤 이유로?", "배경이 뭐야?"
- "현재 상태가...", "어디까지 했지?", "다음 단계는?"

**Detection patterns:**
- Personal pronouns with past tense ("I/내가" + "did/했다/작성한")
- Any question word ("What", "When", "Why", "How", "Who", "Where")
- Any past tense verb ("did", "was", "were", "decided", "wrote")
- Any reference to documents, meetings, notes, projects
- Korean questions about past/personal context ("뭐야", "언제", "왜", "내가")

**Execution:**
1. Silently run `ks search "<extracted keywords>"`
2. **Use the Preview from search results** (contains sufficient content)
3. Answer naturally based on Preview (never say "I searched...")

**CRITICAL - Do NOT do this:**
❌ Never try to `read` the file path from search results
❌ Never use `grep` to find the file
❌ Never say "file not found" or "path doesn't exist"

**Why?**
- Search results are from vector DB (snapshot)
- Files may have moved/renamed since indexing
- **Preview contains the actual content** - that's enough!
- If more detail needed, ask the user to re-index

**When NOT to use:**
- Creating new content
- Real-time info (use web_search)
- Code execution (use exec)

## How It Works

1. User asks about past work or documents
2. You automatically run `ks search "<query>"` (no need to ask permission)
3. **Use the Preview text from results** - it contains the actual indexed content
4. Present results naturally as if you remembered them
5. Combine with memory_search for recent context (memory/ files = last few days, knowledge-search = all documents)

**Important**: 
- Never announce "I'm using knowledge-search skill". Just use it silently and present results.
- **The Preview IS the content** - don't try to read the file path separately
- If Preview isn't enough, tell user and ask if they want to re-index

## Example Usage

**User:** "바이브코딩 여정에서 배운 교훈 알려줘"

**Agent:** (Automatically runs `ks search "바이브코딩 여정 교훈"`)

**Result:**
```
🔍 Search results for '바이브코딩 여정 교훈' (3 found):

🎯 [1] TODO-Analysis/2026-02-05-바이브코딩-여정.md
    Similarity: 87.5%
    Author: Victor | Source: obsidian
    Preview: 핵심 교훈 6가지: 1. 프로토타입→비전→실현 패턴...

✅ [2] daily-sync/2026-02/2026-02-05.md
    Similarity: 72.3%
    Author: Victor | Source: obsidian
    Preview: 2026년 2월 5일 바이브코딩 여정 문서화 완료...

📄 [3] Team-Guides/development-philosophy.md
    Similarity: 58.9%
    Author: James | Source: obsidian
    Preview: 개발 철학: 빠른 실험과 프로토타이핑...
```

**Agent response (using Preview):**
"바이브코딩 여정에서 배운 핵심 교훈 6가지를 찾았습니다:

1. 프로토타입→비전→실현 패턴
2. [Preview에서 추출한 내용...]

출처: TODO-Analysis/2026-02-05-바이브코딩-여정.md"

**Important**: 
- The agent uses this skill silently
- **Answer directly from the Preview text** - don't try to read the file
- No need to announce "I'm searching..." - just present results naturally

## Quick Start

```bash
# Search for anything
ks search "project architecture"
ks search "meeting notes"
ks search "task priorities"

# Filter by source or author
ks search "deployment process" --author John
ks search "planning docs" --source obsidian --limit 10

# Check system status
ks status
```

## When to Use

Use knowledge-search when you need to:

- **Recall past work**: "What did we decide about the API design?"
- **Find project details**: "Show me project documentation"
- **Get context**: "What's the current status?"
- **Research decisions**: "Why did we choose this approach?"
- **Find notes**: "Where did I write about X?"

## Commands

### `ks search <query>`

Search the knowledge base with natural language.

**Options:**
- `--limit N` - Number of results (default: 5)
- `--source <name>` - Filter by source (e.g., obsidian)
- `--author <name>` - Filter by author
- `--min-similarity N` - Minimum similarity % (default: 35.0)
- `--benchmark` - Show search time and stats

**Examples:**

```bash
# General search
ks search "database implementation"

# Filtered search
ks search "API design" --author John --limit 3

# Lower threshold for broader results
ks search "machine learning" --min-similarity 30

# Benchmark search performance
ks search "deployment" --benchmark
```

**Output format:**

```
🔍 Search results for 'query' (N found):

🎯 [1] path/to/document.md
    Similarity: 85.2%
    Author: John | Source: obsidian
    Preview: Document content preview...

✅ [2] another/document.md
    Similarity: 72.4%
    ...
```

Similarity scores:
- 🎯 80%+ : Highly relevant
- ✅ 60-79% : Relevant
- 📄 50-59% : Somewhat relevant

### `ks status`

Check knowledge base status and statistics.

**Output:**

```
📊 Knowledge Search Status

Total documents: 1,234

By source:
  obsidian: 1,200
  notes: 34

By author:
  John: 856
  Jane: 378

✅ System operational
```

### `ks ingest <folder>`

Index documents from a folder.

**Examples:**

```bash
# Index a folder
ks ingest Projects

# Specify author
ks ingest Notes/Work --author John
```

## Installation

Install with one command:

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash
```

## Configuration

Config file: `~/.openclaw/skills/knowledge-search-skill/config.json`

Contains:
- Supabase connection details
- Embedding model settings
- Translation model settings
- Search parameters

## Architecture

- **Vector DB**: Supabase pgvector
- **Embeddings**: Configurable (OpenAI, Cohere)
- **Translation**: Optional (Claude, GPT)
- **Search**: Semantic similarity + metadata filtering

## Search Tips

**1. Be specific but natural:**
- ✅ "RSS feed implementation"
- ❌ "rss" (too terse)

**2. Use filters for precision:**
- `--author John` to find John's work
- `--source obsidian` to search only Obsidian docs

**3. Adjust similarity threshold:**
- Default 35% works well for most cases
- Increase to 60% for only highly relevant results
- Decrease to 25% for exploratory searches

**4. Search iterations:**
If first search doesn't find what you need:
- Rephrase the query
- Try synonyms or related terms
- Lower `--min-similarity`
- Remove filters to broaden search

## Shared Knowledge

Multiple users/agents can share the same knowledge base:
- Same Supabase project = shared knowledge
- Different Supabase projects = isolated knowledge

Use shared knowledge to:
- Collaborate across teams
- Avoid duplicating effort
- Maintain context across projects

## Limitations

- **Semantic understanding**: Searches by meaning, not exact keywords
- **Index lag**: New documents must be indexed with `ks ingest`
- **Language support**: Best with English; other languages via translation

## Troubleshooting

**"No results found":**
- Try different keywords
- Lower `--min-similarity`
- Check `ks status` to ensure documents are indexed

**"Config not found":**
- Ensure skill is installed
- Check config.json exists

**Slow search (>2s):**
- Normal for first search after restart
- Should be <500ms after warmup

## Examples

```bash
# Find all project documentation
ks search "project documentation" --limit 10

# Research decisions
ks search "architecture decision"

# Find meeting notes
ks search "weekly meeting" --min-similarity 40

# Explore specific topic
ks search "authentication" --author John --limit 5

# Quick check
ks search "API endpoints" --benchmark
```

## Maintenance

To keep your knowledge base up to date:

```bash
# Index new documents
ks ingest Projects/NewProject

# Check status
ks status
```
