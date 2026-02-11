#!/usr/bin/env python3
"""
Knowledge Search CLI - ks

Natural language search for your knowledge base
"""

import click
import time
import os
import sys
from pathlib import Path

# src 모듈 import를 위한 경로 추가
sys.path.insert(0, str(Path(__file__).parent))

from search import KnowledgeSearch
from ingest import KnowledgeIngest


@click.group()
@click.version_option(version='0.1.0')
def cli():
    """
    Knowledge Search - Semantic search for your documents
    
    Search your Obsidian vault, notes, and documents with natural language.
    """
    pass


@cli.command()
@click.argument('query')
@click.option('--limit', default=5, help='Number of results (default: 5)')
@click.option('--source', help='Filter by source (e.g., obsidian)')
@click.option('--author', help='Filter by author')
@click.option('--min-similarity', type=float, help='Minimum similarity % (default: from config)')
@click.option('--benchmark', is_flag=True, help='Show search timing')
def search(query, limit, source, author, min_similarity, benchmark):
    """
    Search your knowledge base
    
    Examples:
    
      ks search "project planning"
      
      ks search "task priority" --limit 10
      
      ks search "meeting notes" --author John
    """
    try:
        # KnowledgeSearch 초기화
        config_path = Path(__file__).parent.parent / 'config.json'
        ks = KnowledgeSearch(str(config_path))
        
        # 검색 실행
        start = time.time()
        results = ks.search(
            query, 
            limit=limit, 
            source=source, 
            author=author,
            min_similarity=min_similarity
        )
        elapsed = time.time() - start
        
        # 결과 출력
        if not results:
            click.echo("❌ No results found.")
            click.echo(f"\n💡 Tips:")
            click.echo(f"  - Try different keywords")
            click.echo(f"  - Lower --min-similarity value")
            return
        
        click.echo(f"🔍 Search results for '{query}' ({len(results)} found):\n")
        
        for i, result in enumerate(results, 1):
            # 유사도에 따른 이모지
            if result['similarity'] >= 80:
                emoji = '🎯'
            elif result['similarity'] >= 60:
                emoji = '✅'
            else:
                emoji = '📄'
            
            click.echo(f"{emoji} [{i}] {result['path']}")
            click.echo(f"    Similarity: {result['similarity']}%")
            click.echo(f"    Author: {result['author']} | Source: {result['source']}")
            
            # 텍스트 미리보기 (150자)
            text = result.get('text', '')
            if text:
                preview = text[:150] + '...' if len(text) > 150 else text
                click.echo(f"    Preview: {preview}")
            
            click.echo()
        
        # 벤치마크 정보
        if benchmark:
            click.echo(f"⏱️  Search time: {elapsed*1000:.0f}ms")
            click.echo(f"📊 Average similarity: {sum(r['similarity'] for r in results) / len(results):.1f}%")
    
    except FileNotFoundError:
        click.echo("❌ config.json not found.")
        click.echo("   Check your installation directory")
        sys.exit(1)
    except Exception as e:
        click.echo(f"❌ Error: {e}")
        if '--debug' in sys.argv:
            import traceback
            traceback.print_exc()
        sys.exit(1)


@cli.command()
def status():
    """
    Show index status
    
    Display total documents, source distribution, etc.
    """
    try:
        config_path = Path(__file__).parent.parent / 'config.json'
        ks = KnowledgeSearch(str(config_path))
        
        # 총 문서 수
        result = ks.supabase.table("embeddings").select("*", count='exact').execute()
        total = result.count
        
        click.echo("📊 Knowledge Search Status\n")
        click.echo(f"Total documents: {total}")
        
        if total > 0:
            # 소스별 통계
            sources = {}
            authors = {}
            for doc in result.data:
                meta = doc.get('metadata', {})
                source = meta.get('source', 'unknown')
                author = meta.get('author', 'unknown')
                
                sources[source] = sources.get(source, 0) + 1
                authors[author] = authors.get(author, 0) + 1
            
            click.echo("\nBy source:")
            for source, count in sorted(sources.items(), key=lambda x: -x[1]):
                click.echo(f"  {source}: {count}")
            
            click.echo("\nBy author:")
            for author, count in sorted(authors.items(), key=lambda x: -x[1]):
                click.echo(f"  {author}: {count}")
        
        click.echo("\n✅ System operational")
    
    except Exception as e:
        click.echo(f"❌ Error: {e}")
        sys.exit(1)


@cli.command()
@click.argument('folder')
@click.option('--source', default='obsidian', help='Source name')
@click.option('--author', default='unknown', help='Author name')
def ingest(folder, source, author):
    """
    Index documents from a folder
    
    Examples:
    
      ks ingest Projects
      
      ks ingest Notes/Work --author John
    """
    try:
        config_path = Path(__file__).parent.parent / 'config.json'
        ingestor = KnowledgeIngest(str(config_path))
        
        click.echo(f"📥 Indexing folder: {folder}\n")
        ingestor.ingest_folder(folder, source=source, author=author)
        click.echo("\n✅ Indexing complete!")
    
    except Exception as e:
        click.echo(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    cli()
