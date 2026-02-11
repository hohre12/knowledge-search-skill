---
name: knowledge-search
description: Search and retrieve information from your knowledge base using natural language queries. Use this skill automatically when users ask about past work, decisions, project details, meeting notes, or any previously documented information. Supports filtering by source and author. Fast semantic search powered by vector embeddings.
license: MIT
compatibility: openclaw, opencode, claude-code
metadata: {"openclaw": {"requires": {"bins": ["ks"]}, "emoji": "🔍", "homepage": "https://github.com/hohre12/knowledge-search-skill"}}
---

# Knowledge Search

Search your knowledge base using natural language queries. Works with Obsidian vaults, notes, and documents.

## Automatic Usage

**This skill is invoked automatically** when the user asks about:

- **Past work or projects**: "What did we work on last month?"
- **Decisions and reasoning**: "Why did we choose this approach?"
- **Project documentation**: "Show me the API documentation"
- **Meeting notes**: "What was discussed in the planning meeting?"
- **Task status**: "What's the current status of the project?"
- **Historical context**: "When did we start this feature?"
- **Team notes**: "What did John write about deployment?"

**Detection patterns** (user doesn't need to mention "search" or "knowledge"):
- Questions about past ("What did...", "When did...", "Why did...")
- Requests for context ("Show me...", "Find...", "Tell me about...")
- Status inquiries ("What's the current...", "Where are we with...")
- Document references ("Where is...", "What's in...")

**When NOT to use**:
- Creating new notes (use other tools)
- Real-time information (use web search)
- Code execution (use exec)

## How It Works

1. User asks about past work or documents
2. You automatically run `ks search "<query>"` (no need to ask permission)
3. Present results naturally as if you remembered them
4. Combine with memory_search for recent context (memory/ files = last few days, knowledge-search = all documents)

**Important**: Never announce "I'm using knowledge-search skill". Just use it silently and present results.

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
