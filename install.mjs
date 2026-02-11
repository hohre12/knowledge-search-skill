#!/usr/bin/env node

/**
 * Knowledge Search - Interactive Installation
 * OpenClaw-style UI with @clack/prompts
 */

import * as p from '@clack/prompts';
import { execSync, exec } from 'child_process';
import { promisify } from 'util';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const execAsync = promisify(exec);

const HOME = homedir();

async function main() {
  console.clear();
  
  p.intro('📦 Knowledge Search Installation');
  
  // 1. Select targets
  const targets = await p.multiselect({
    message: 'Select installation targets',
    options: [
      { value: 'openclaw', label: 'OpenClaw (~/.openclaw/skills/)', hint: 'Recommended' },
      { value: 'opencode', label: 'OpenCode (~/.config/opencode/skills/)' },
      { value: 'claude', label: 'Claude Code CLI (~/.claude/skills/)' }
    ],
    initialValues: ['openclaw'],
    required: true,
  });
  
  if (p.isCancel(targets)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  // 2. Supabase configuration
  p.note('Same Supabase = Shared knowledge base', 'Configuration');
  
  const supabaseUrl = await p.text({
    message: 'Supabase URL',
    placeholder: 'https://xxx.supabase.co',
    validate: (value) => {
      if (!value) return 'URL is required';
      if (!value.startsWith('https://')) return 'Must start with https://';
      return;
    }
  });
  
  if (p.isCancel(supabaseUrl)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  const supabaseKey = await p.password({
    message: 'Supabase anon key',
    validate: (value) => !value ? 'Key is required' : undefined,
  });
  
  if (p.isCancel(supabaseKey)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  // 3. Embedding model selection
  const embeddingModel = await p.select({
    message: 'Select embedding model',
    options: [
      { value: 'openai-small', label: 'OpenAI text-embedding-3-small', hint: 'Recommended, $0.002/1M tokens' },
      { value: 'openai-large', label: 'OpenAI text-embedding-3-large', hint: '$0.013/1M tokens' },
      { value: 'cohere', label: 'Cohere embed-multilingual-v3.0', hint: 'Multilingual' },
    ],
  });
  
  if (p.isCancel(embeddingModel)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  let embeddingProvider, embeddingModelName, embeddingApiKey;
  
  if (embeddingModel === 'openai-small' || embeddingModel === 'openai-large') {
    embeddingProvider = 'openai';
    embeddingModelName = embeddingModel === 'openai-small' ? 'text-embedding-3-small' : 'text-embedding-3-large';
    embeddingApiKey = await p.password({
      message: 'OpenAI API Key',
      validate: (value) => !value ? 'API Key is required' : undefined,
    });
  } else {
    embeddingProvider = 'cohere';
    embeddingModelName = 'embed-multilingual-v3.0';
    embeddingApiKey = await p.password({
      message: 'Cohere API Key',
      validate: (value) => !value ? 'API Key is required' : undefined,
    });
  }
  
  if (p.isCancel(embeddingApiKey)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  // 4. Translation model selection
  const translationModel = await p.select({
    message: 'Select translation model',
    options: [
      { value: 'claude', label: 'Claude Sonnet 4.5', hint: 'Recommended, Best quality' },
      { value: 'gpt4o', label: 'GPT-4o' },
      { value: 'gpt4o-mini', label: 'GPT-4o mini', hint: 'Cheapest' },
      { value: 'none', label: 'No translation', hint: 'English documents only' },
    ],
  });
  
  if (p.isCancel(translationModel)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  let translationProvider, translationModelName, translationApiKey;
  
  if (translationModel === 'claude') {
    translationProvider = 'anthropic';
    translationModelName = 'claude-sonnet-4-5-20250929';
    translationApiKey = await p.password({
      message: 'Claude API Key',
      validate: (value) => !value ? 'API Key is required' : undefined,
    });
  } else if (translationModel === 'gpt4o' || translationModel === 'gpt4o-mini') {
    translationProvider = 'openai';
    translationModelName = translationModel === 'gpt4o' ? 'gpt-4o' : 'gpt-4o-mini';
    translationApiKey = await p.password({
      message: 'OpenAI API Key',
      validate: (value) => !value ? 'API Key is required' : undefined,
    });
  } else {
    translationProvider = 'none';
    translationModelName = '';
    translationApiKey = '';
  }
  
  if (translationModel !== 'none' && p.isCancel(translationApiKey)) {
    p.cancel('Installation cancelled');
    process.exit(0);
  }
  
  // 5. Installation
  p.log.step('Starting installation...');
  
  try {
    // Determine primary directory
    const primaryDir = targets.includes('openclaw') 
      ? join(HOME, '.openclaw/skills/knowledge-search')
      : targets.includes('opencode')
      ? join(HOME, '.config/opencode/skills/knowledge-search')
      : join(HOME, '.claude/skills/knowledge-search');
    
    // Download files from GitHub
    const s1 = p.spinner();
    
    mkdirSync(primaryDir, { recursive: true });
    mkdirSync(join(primaryDir, 'src'), { recursive: true });
    
    const files = [
      'SKILL.md',
      'README.md',
      'requirements.txt',
      'schema.sql',
      'config.json.example',
      'src/__init__.py',
      'src/cli.py',
      'src/search.py',
      'src/ingest.py',
    ];
    
    const baseUrl = 'https://raw.githubusercontent.com/hohre12/knowledge-search-skill/main';
    
    s1.start('Downloading files from GitHub...');
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      s1.message(`Downloading [${i + 1}/${files.length}] ${file}...`);
      try {
        await execAsync(`curl -sSL ${baseUrl}/${file} -o ${join(primaryDir, file)}`);
      } catch (err) {
        // Continue on error
      }
    }
    
    s1.stop('✓ Files downloaded');
    
    // Create venv
    const s2 = p.spinner();
    s2.start('Creating Python virtual environment...');
    const venvDir = join(HOME, '.local/share/knowledge-search-venv');
    mkdirSync(join(HOME, '.local/share'), { recursive: true });
    execSync(`python3 -m venv ${venvDir}`, { stdio: 'pipe' });
    s2.stop('✓ Python venv created');
    
    // Install dependencies
    p.log.step('Upgrading pip...');
    execSync(`${venvDir}/bin/pip install --quiet --upgrade pip`, { stdio: 'inherit' });
    
    p.log.step('Installing Python packages (openai, supabase, tiktoken, anthropic, click)...');
    // Show progress bar only (not detailed logs)
    execSync(`${venvDir}/bin/pip install -q --progress-bar on -r ${primaryDir}/requirements.txt`, { stdio: 'inherit' });
    p.log.success('✓ Dependencies installed');
    
    // Create config.json
    p.log.step('Writing configuration...');
    const config = {
      supabase: {
        url: supabaseUrl,
        key: supabaseKey
      },
      embedding: {
        provider: embeddingProvider,
        model: embeddingModelName,
        api_key: embeddingApiKey
      },
      translation: {
        provider: translationProvider,
        model: translationModelName,
        api_key: translationApiKey
      },
      search: {
        default_limit: 5,
        min_similarity: 35.0
      },
      sources: {
        obsidian: {
          path: "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/AI-Workspace"
        }
      }
    };
    
    writeFileSync(join(primaryDir, 'config.json'), JSON.stringify(config, null, 2));
    p.log.success('✓ Configuration saved');
    
    // Register ks command
    p.log.step('Registering ks command...');
    const ksWrapper = `#!/bin/bash
cd ${primaryDir}
source ${venvDir}/bin/activate
python -m src.cli "$@"
`;
    writeFileSync('/opt/homebrew/bin/ks', ksWrapper);
    execSync('chmod +x /opt/homebrew/bin/ks');
    p.log.success('✓ ks command registered at /opt/homebrew/bin/ks');
    
    // Create symlinks
    if (targets.includes('opencode') && primaryDir !== join(HOME, '.config/opencode/skills/knowledge-search')) {
      p.log.step('Creating OpenCode symlink...');
      const opencodeDir = join(HOME, '.config/opencode/skills/knowledge-search');
      mkdirSync(join(HOME, '.config/opencode/skills'), { recursive: true });
      execSync(`ln -s ${primaryDir} ${opencodeDir}`);
      p.log.success('✓ OpenCode symlink created');
    }
    
    if (targets.includes('claude') && primaryDir !== join(HOME, '.claude/skills/knowledge-search')) {
      p.log.step('Creating Claude CLI symlink...');
      const claudeDir = join(HOME, '.claude/skills/knowledge-search');
      mkdirSync(join(HOME, '.claude/skills'), { recursive: true });
      execSync(`ln -s ${primaryDir} ${claudeDir}`);
      p.log.success('✓ Claude CLI symlink created');
    }
    
    p.outro(`
✨ Knowledge Search is ready!

Installed to:
${targets.map(t => `  ✅ ${t.charAt(0).toUpperCase() + t.slice(1)}`).join('\n')}

Next steps:
  • Test search: ks search "query"
  • Check status: ks status
  • Index documents: ks ingest <folder>
    `);
    
  } catch (error) {
    p.log.error('Installation failed');
    p.cancel(`Error: ${error.message}`);
    process.exit(1);
  }
}

main().catch(console.error);
