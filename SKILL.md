---
name: knowledge-search
description: Search indexed knowledge base using natural language. MANDATORY: Use when user asks about past work, projects, documents, meetings, decisions, or any historical context - run `ks search --format json` FIRST before answering. Always use --format json to get full document content.
homepage: https://github.com/hohre12/knowledge-search-skill
metadata:
  {
    "openclaw":
      {
        "emoji": "🔍",
        "requires": { "bins": ["ks"] },
        "install":
          [
            {
              "id": "curl",
              "kind": "curl",
              "url": "https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh",
              "bins": ["ks"],
              "label": "Install knowledge-search (interactive installer)",
            },
          ],
      },
  }
---

# Knowledge Search

Search your indexed knowledge base using natural language. Powered by vector embeddings + semantic search.

## When to use

**🚨 MANDATORY: Use immediately when user asks about:**

- Past work/context: "What did we work on last month?"
- Project history: "Why did we choose this approach?"
- Meeting notes: "What was discussed in the meeting?"
- Documentation: "Show me the API docs"
- Decisions: "When did we decide to use X?"
- Personal memories: "나의 바이브 코딩 시작 계기가 뭐야?"

**Detection patterns (auto-trigger):**
- Question words: What, When, Why, How, Who, Where
- Past tense: did, was, decided, wrote, discussed
- References: documents, meetings, notes, projects, history
- Korean: 뭐야, 언제, 왜, 어떻게

**Usage (CRITICAL for AI):**
1. **Always use `--format json`** to get full document content (standard RAG)
2. Run `ks search "<keywords>" --format json` silently
3. Parse JSON response: `results[].text` contains full document text
4. Use full text as context (no need to read files)
5. Present answer naturally based on full content

## Quick commands

```bash
# AI usage (get full content - RAG)
ks search "project architecture" --format json

# Human usage (preview only)
ks search "project architecture"

# With filters (AI)
ks search "API design" --author Victor --limit 10 --format json

# Broader results (lower threshold)
ks search "deployment" --min-similarity 30 --format json

# Check status
ks status
```

## Search options

- `--format json` - **REQUIRED for AI**: Get full document text (not preview)
- `--limit N` - Results count (default: 5)
- `--source <name>` - Filter by source
- `--author <name>` - Filter by author
- `--min-similarity N` - Minimum % (default: 35.0)

**Output formats:**
- `--format json` - Full content for AI/RAG (use this!)
- `--format text` - Preview only for humans (default)

**Similarity guide:**
- 🎯 80%+ : Highly relevant
- ✅ 60-79% : Relevant
- 📄 50-59% : Somewhat relevant
- 35-49% : Tangentially related

## Installation

One-line installer (interactive, multi-platform):

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash
```

**Requirements:**
- Supabase project (free tier: 500MB)
- API keys (OpenAI/Claude for embeddings)
- Python 3.10+

Full setup guide: https://github.com/hohre12/knowledge-search-skill

## Search tips

**Always use JSON format for AI:**
```bash
ks search "query" --format json
```
- Returns full document content (not preview)
- Standard RAG pattern: search → get full text → answer
- No need to read files separately

**Be specific:**
- ✅ "RSS feed implementation details"
- ❌ "rss" (too vague)

**No results?**
- Try different keywords
- Lower `--min-similarity` to 25
- Check `ks status` to verify indexed documents

**Slow search?**
- First search may be slow (cold start)
- Should be <500ms after warmup

## Indexing new documents

```bash
# Index folder
ks ingest ~/Documents/NewProject

# With metadata
ks ingest ~/Notes --author Victor --source obsidian
```

## More info

GitHub: https://github.com/hohre12/knowledge-search-skill
