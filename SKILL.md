---
name: knowledge-search
description: Search indexed knowledge base (454 documents from Obsidian) using natural language. Use when a user asks about past work, projects, documents, meetings, decisions, or any historical context - run `ks search` first before answering.
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

Search your indexed knowledge base using natural language queries. Powered by vector embeddings (Supabase pgvector).

## When to use (trigger phrases)

**Use this skill immediately when the user asks any question about:**

- **Past work/context**: "What did we work on last month?" → `ks search "work last month"`
- **Project history**: "Why did we choose this approach?" → `ks search "why choose approach"`
- **Meeting notes**: "What was discussed in the planning meeting?" → `ks search "planning meeting"`
- **Documentation**: "Show me the API documentation" → `ks search "API documentation"`
- **Decisions**: "When did we decide to use GraphQL?" → `ks search "decide GraphQL"`
- **Korean queries**: "바이브 코딩 시작 계기가 뭐야?" → `ks search "바이브 코딩 시작 계기"`

**Detection patterns (trigger automatically):**
- Question words: What, When, Why, How, Who, Where
- Past tense: did, was, were, decided, wrote, discussed
- References: documents, meetings, notes, projects, history
- Korean: 뭐야, 언제, 왜, 어떻게

**Execution rules:**
1. Run `ks search "<keywords>"` silently (no need to announce)
2. Present results naturally as if recalling from memory
3. Combine with `memory_search` for recent context (memory/ = last few days, ks = all indexed docs)

## Quick start

```bash
# Basic search
ks search "project architecture"

# With filters
ks search "API design" --author Victor --limit 10

# Broader results
ks search "deployment" --min-similarity 30

# Check status
ks status
```

## Commands

### `ks search <query>`

Search with natural language. Returns top results with similarity scores.

**Options:**
- `--limit N` - Results count (default: 5)
- `--source <name>` - Filter by source (e.g., obsidian)
- `--author <name>` - Filter by author
- `--min-similarity N` - Minimum % (default: 35.0)
- `--benchmark` - Show timing stats

**Output:**

```
🔍 Search results for 'query' (3 found):

🎯 [1] TODO-Analysis/2026-02-05-바이브코딩-여정.md
    Similarity: 87.5%
    Author: Victor | Source: obsidian
    Preview: 핵심 교훈 6가지...

✅ [2] daily-sync/2026-02-05.md
    Similarity: 72.3%
    ...
```

Similarity guide:
- 🎯 80%+ : Highly relevant
- ✅ 60-79% : Relevant
- 📄 50-59% : Somewhat relevant
- Lower : Tangentially related

### `ks status`

Show knowledge base statistics.

**Output:**

```
📊 Knowledge Search Status

Total documents: 454

By source:
  obsidian: 454

By author:
  Victor: 280
  James: 174

✅ System operational
```

### `ks ingest <folder>`

Index new documents from a folder.

```bash
# Index folder
ks ingest ~/Documents/NewProject

# With author metadata
ks ingest ~/Notes --author Victor
```

## Installation

Interactive installer with multi-target support (OpenClaw, OpenCode, Cursor, etc.):

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash
```

During installation:
1. Choose target platform(s) (checkbox UI)
2. Provide Supabase credentials (URL + anon key)
3. Select embedding model (OpenAI/Cohere/Claude/GPT)
4. Configure API keys

Config file: `~/.openclaw/skills/knowledge-search/config.json`

## Setup

**1. Create Supabase project** (free tier: 500MB, 50K rows):
- https://supabase.com/dashboard
- Run schema SQL (provided in installer)

**2. Index your documents:**

```bash
# Index specific folders (recommended)
ks ingest ~/Obsidian/daily-sync
ks ingest ~/Obsidian/TODO

# Check progress
ks status
```

## Search tips

**Be specific but natural:**
- ✅ "RSS feed implementation details"
- ❌ "rss" (too terse)

**Use filters for precision:**
- `--author Victor` to find Victor's work
- `--limit 10` for more results

**Adjust threshold:**
- Default 35% works for most cases
- Increase to 60% for high relevance only
- Decrease to 25% for exploratory searches

**Search iterations:**
- Try different keywords if no results
- Rephrase query or use synonyms
- Remove filters to broaden search

## Shared knowledge base

Multiple users/agents can share the same Supabase project:
- Same credentials = shared knowledge
- Different projects = isolated knowledge

Use for:
- Team collaboration
- Cross-agent context
- Avoid duplicate work

## Architecture

- **Vector DB**: Supabase pgvector (HNSW index)
- **Embeddings**: OpenAI text-embedding-3-large (1536 dims)
- **Translation**: Optional Claude Sonnet 4.5 (Korean → English)
- **Search**: Cosine similarity + metadata filtering

## Limitations

- Semantic search only (no exact keyword matching)
- New documents require manual indexing (`ks ingest`)
- Best results with English (translation overhead for other languages)

## Troubleshooting

**No results:**
- Try different keywords
- Lower `--min-similarity` to 25
- Check `ks status` (documents indexed?)

**Slow search (>2s):**
- Normal for first search (cold start)
- Should be <500ms after warmup

**Config not found:**
- Ensure skill installed via installer
- Check `~/.openclaw/skills/knowledge-search/config.json`

## Examples

```bash
# Find project docs
ks search "project documentation" --limit 10

# Research decisions
ks search "why GraphQL" --author James

# Meeting notes
ks search "planning meeting" --min-similarity 40

# Benchmark
ks search "API endpoints" --benchmark
```

## Known issues

**OpenClaw FD leak (#11181):**
- OpenClaw scans skills folder on every message
- Large directories (venv, .git) cause file descriptor leaks
- **Solution**: venv installed outside skills folder (`~/.local/share/knowledge-search-venv`)
- See GitHub README for details

## More info

Full documentation: https://github.com/hohre12/knowledge-search-skill
