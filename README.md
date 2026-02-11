# Knowledge Search Skill

> **Author**: Jaewon Bae ([@hohre12](https://github.com/hohre12))

AI-powered knowledge base search for OpenClaw/OpenCode/Claude Code CLI

**Auto-triggered** - Just chat naturally, the AI agent automatically searches your knowledge base.

## 🎯 Auto-Trigger

No need to explicitly say "use knowledge-search skill..." - the agent automatically decides when to use it:

```
❌ No need: "Use knowledge-search skill to find project"
✅ Natural: "Tell me about project progress" → Auto-triggered!
```

**Auto-trigger conditions:**
- Past work/project questions ("What did...", "When did...")
- Document/note requests ("Show me...", "Find...")
- Decision/reasoning questions ("Why did...", "What was...")
- Status checks ("What's the current...")

## ✨ Features

- 🔍 **Natural Language Search**: "Tell me project priorities" → Auto-search
- 🌍 **Multilingual**: Auto-translate Korean/English (optional)
- 🤖 **Multi-Model**: OpenAI, Cohere embeddings / Claude, GPT translation
- 📦 **Shareable**: Same Supabase = Shared knowledge base
- 🔒 **Isolated**: Different Supabase = Complete isolation
- 💾 **Vector DB Only**: Delete original files after indexing (save space/security)

## 🚀 Installation (One-liner!)

```bash
npx github:hohre12/knowledge-search-skill
```

**Beautiful OpenClaw-style UI installation!**

During installation:
1. Select installation target (OpenClaw/OpenCode/Claude)
2. Enter Supabase URL & Key
3. Choose embedding model (OpenAI/Cohere)
4. Choose translation model (Claude/GPT/None)
5. Enter API keys

**Or traditional method:**
```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/install.sh | bash
```

## 📊 Supabase Setup

1. Create project at https://supabase.com
2. Run `schema.sql` in SQL Editor:

```bash
cat ~/.openclaw/skills/knowledge-search/schema.sql
```

3. Verify table creation:

```sql
SELECT COUNT(*) FROM embeddings;
```

## 💬 Usage

### Automatic Usage (OpenClaw Recommended)

Just chat naturally in OpenClaw - the skill auto-triggers:

```
User: "What did I learn from Vibe Coding journey?"
AI: (auto-runs ks search) → Answers based on results

User: "Tell me project progress"
AI: (auto-runs ks search) → Answers

User: "What's in the team guide?"
AI: (auto-runs ks search) → Answers
```

**The agent responds naturally without saying "Searching..."**

### Manual Search (CLI)

Direct command-line search:

```bash
ks search "query"
ks search "project plan" --limit 10
ks search "urgent tasks" --author John
```

## 🏗️ Architecture

**Vector DB = Single Source of Truth**

```
Original Docs → Indexing → Vector DB (embeddings + full text)
                              ↓
                        Delete originals OK ✅
                              ↓
                        Search results = Preview (full content)
```

**Important:**
- Search result **Preview = Full indexed content** (not summary)
- Original files can be deleted after indexing (save space/security)
- File paths are just metadata (no actual file access needed)

**Benefits:**
- ✅ Disk space savings (deduplication)
- ✅ Enhanced security (delete sensitive docs after indexing)
- ✅ Fast search (no file system access)
- ✅ Easy sharing (just share Vector DB)

## 📝 Index Your Own Documents (Optional)

```bash
# Configure Obsidian path
vi ~/.openclaw/skills/knowledge-search/config.json
# Edit sources.obsidian.path

# Index folders
ks ingest Notes
ks ingest Projects
ks ingest Projects/MyProject

# Check status
ks status
```

## 🔄 Update

```bash
curl -sSL https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main/update.sh | bash
```

## 📂 Structure

```
~/.openclaw/skills/knowledge-search/
├── SKILL.md              # Skill definition for agents
├── config.json           # Configuration (API keys, Supabase)
├── requirements.txt      # Python dependencies
├── schema.sql            # Supabase schema
└── src/
    ├── cli.py            # CLI entry point
    ├── search.py         # Search logic
    └── ingest.py         # Embedding logic
```

## 🔧 OpenClaw Integration

This skill uses OpenClaw's **Eager Loading** mechanism:

**Frontmatter configuration:**
```yaml
name: knowledge-search
user-invocable: true              # Slash command support
disable-model-invocation: false   # Allow agent auto-execution
metadata:
  openclaw:
    requires:
      bins: [python3, ks]         # Required binaries
```

**How it works:**
1. OpenClaw checks `requires.bins` at startup (python3, ks)
2. If passed, injects entire SKILL.md into system prompt
3. Agent reads "Automatic Usage" section and decides
4. When trigger pattern matches, auto-runs `ks search`

**User experience:**
- ✅ Just install and done (no extra config)
- ✅ Natural conversation for search
- ✅ No need to say "use skill..."

## 🤝 Knowledge Sharing

**Want to share knowledge with your team?**

1. Team member A creates Supabase project + indexes documents
2. Team members B, C enter same Supabase URL/Key during installation
3. Everyone uses the same knowledge base ✅

**Want complete isolation for personal use?**

Each person uses different Supabase project

## 💰 Cost

- **Search**: ~$0.00001/query
- **Indexing**: $0.001~$0.01/file depending on size

Example: Indexing 500 documents = $0.50

## 🛠️ CLI Commands

```bash
ks search <query>         # Search
ks ingest <folder>        # Index folder
ks status                 # Check status
ks --help                 # Help
```

## 📚 Supported Platforms

- ✅ OpenClaw (recommended)
- ✅ OpenCode
- ✅ Claude Code CLI

## 🐛 Known Issues

### OpenClaw File Descriptor Leak (#11181)

**Problem**: OpenClaw watches skill folders recursively, opening file descriptors for every file. Python virtual environments contain thousands of files, potentially hitting system limits (default macOS: 256).

**Solution**: Install venv OUTSIDE skills folder:
- ✅ Correct: `~/.local/share/knowledge-search-venv/` (default in our installer)
- ❌ Wrong: `~/.openclaw/skills/knowledge-search/venv/`

**Symptoms if misconfigured**:
- `OSError: [Errno 24] Too many open files`
- OpenClaw becomes unresponsive
- File operations fail

**Manual fix** (if you installed incorrectly):
```bash
# Move venv outside skills folder
mv ~/.openclaw/skills/knowledge-search/venv ~/.local/share/knowledge-search-venv

# Update ks command wrapper
sudo vi /opt/homebrew/bin/ks
# Change: source ~/.local/share/knowledge-search-venv/bin/activate
```

**Status**: This is an OpenClaw bug, not a skill issue. Workaround is reliable.

## 🔗 Links

- GitHub: https://github.com/hohre12/knowledge-search-skill
- Supabase: https://supabase.com
- OpenClaw: https://openclaw.ai

## 👤 Author

**Jaewon Bae**
- GitHub: [@hohre12](https://github.com/hohre12)
- Project: [knowledge-search-skill](https://github.com/hohre12/knowledge-search-skill)

## 📄 License

MIT License - Feel free to use and modify!
