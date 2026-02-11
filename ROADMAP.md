# Knowledge Search Skill - Roadmap

## Phase 1: MVP (Current) ✅

**Goal:** Working skill for personal use across 3 computers

**Features:**
- ✅ Manual configuration (config.json)
- ✅ Single embedding model (text-embedding-3-small)
- ✅ Single translation model (Claude Sonnet 4.5)
- ✅ Install to OpenClaw/OpenCode/Claude Code
- ✅ CLI tool (`ks` command)

**Deployment:**
- GitHub Public repository
- One-line installation with curl

---

## Phase 2: Multi-user Ready 🚀

**Goal:** Easy installation for anyone with their own infrastructure

### 2.1 Interactive Setup Wizard

**Installation flow:**
```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash

# Interactive prompts:
1. 🛠️  Where to install? (User selects their tool)
   - OpenClaw (recommended)
   - OpenCode
   - Claude Code CLI
   - All (install to OpenClaw + symlinks for others)
   
2. 🗄️  Supabase configuration:
   - Supabase URL: https://YOUR_PROJECT.supabase.co
   - Supabase Key: YOUR_ANON_KEY
   - Auto-create tables? (y/N)
   
3. 🤖 Embedding model selection:
   - OpenAI text-embedding-3-small (recommended, $0.02/1M tokens)
   - OpenAI text-embedding-3-large (higher quality, $0.13/1M tokens)
   - Cohere embed-multilingual-v3.0 (multilingual, $0.10/1M tokens)
   
4. 🌐 Translation model:
   - Claude Sonnet 4.5 (highest quality, recommended, $3/$15 per 1M)
   - GPT-4o (fast and good, $2.50/$10 per 1M)
   - GPT-4o-mini (cheapest, $0.15/$0.60 per 1M)
   - Skip translation (English documents only, free)
   
5. 🔑 API Keys:
   - OpenAI API Key (if selected)
   - Anthropic API Key (if Claude selected)
   - Cohere API Key (if Cohere selected)
```

**Auto-generate config.json** based on inputs

### 2.2 Database Setup Automation

```bash
ks setup-db

# Interactive:
1. Create embeddings table
2. Create vector index (IVFFlat or HNSW)
3. Set up RLS policies
4. Test connection
```

### 2.3 Model Configuration

**config.json schema:**
```json
{
  "supabase": {
    "url": "...",
    "key": "..."
  },
  "embedding": {
    "provider": "openai|cohere",
    "model": "text-embedding-3-small",
    "api_key": "...",
    "dimensions": 1536
  },
  "translation": {
    "provider": "anthropic|openai|none",
    "model": "claude-sonnet-4-5-20250929",
    "api_key": "..."
  },
  "search": {
    "default_limit": 5,
    "min_similarity": 35.0
  }
}
```

### 2.4 Multi-provider Support

**Embedding providers:**
- ✅ OpenAI (text-embedding-3-small, text-embedding-3-large)
- 🚧 Cohere (embed-multilingual-v3.0)
- 🚧 Voyage AI (voyage-large-2)
- 🚧 Local (sentence-transformers)

**Translation providers:**
- ✅ Anthropic (Claude Sonnet 4.5)
- ✅ OpenAI (GPT-4o, GPT-4o-mini)
- 🚧 Google (Gemini)
- 🚧 None (English documents only)

### 2.5 Document Source Flexibility

**Support multiple document sources:**
- ✅ Obsidian vault (current)
- 🚧 Local markdown folder
- 🚧 Notion export
- 🚧 Google Drive
- 🚧 Confluence

---

## Phase 3: ClawHub Publication 🌟

**Goal:** Community-ready skill on ClawHub

### 3.1 ClawHub Packaging

```bash
# Publish to ClawHub
clawhub publish

# Users install
npx clawhub install knowledge-search
```

### 3.2 Web-based Configuration UI

**Optional web UI for easy setup:**
```bash
ks configure --web
# Opens http://localhost:3000
# Guide users through setup with a friendly UI
```

### 3.3 Pre-built Templates

**Quick start templates:**
- Personal knowledge base (Obsidian)
- Team documentation (Confluence export)
- Code documentation (markdown)
- Research papers (PDF → markdown)

### 3.4 Community Features

- ⭐ Stars and ratings on ClawHub
- 💬 Comments and feedback
- 📊 Usage statistics
- 🐛 Issue tracker integration

---

## Phase 4: Advanced Features 💎

### 4.1 Incremental Updates

```bash
ks update --incremental
# Only index new/changed documents
# Smart diffing based on file hash
```

### 4.2 Multi-language Support

- Auto-detect document language
- Language-specific embeddings
- Query in any language

### 4.3 Advanced Search

- Hybrid search (vector + keyword)
- Filters (date, author, tags)
- Reranking for better results
- Query expansion

### 4.4 Analytics Dashboard

```bash
ks analytics

# Show:
- Search frequency
- Popular queries
- Low-confidence results
- Index health
```

---

## Implementation Priority

**Phase 1:** ✅ Done
**Phase 2.1:** Next (Interactive setup)
**Phase 2.2:** Then (DB automation)
**Phase 2.3-2.5:** Later (Multi-provider support)
**Phase 3:** When ready for community
**Phase 4:** Future enhancements

---

## Breaking Changes

**v1.0 → v2.0:**
- Config schema change (split embedding/translation)
- CLI command changes (`ks setup-db` added)
- Migration script provided

**v2.0 → v3.0:**
- Multi-provider support
- Database schema update (provider metadata)
- Migration script provided
