"""
Knowledge Search - Search Logic

Core search functionality used by OpenClaw agents
"""

import json
import openai
from supabase import create_client
from typing import List, Dict, Optional
from pathlib import Path


class KnowledgeSearch:
    """Vector DB-based knowledge search"""
    
    def __init__(self, config_path: str = "config.json"):
        """
        Initialize
        
        Args:
            config_path: Configuration file path
        """
        # Load configuration
        with open(config_path) as f:
            config = json.load(f)
        
        self.config = config
        
        # Supabase client
        self.supabase = create_client(
            config["supabase"]["url"],
            config["supabase"]["key"]
        )
        
        # Embedding configuration
        self.embedding_provider = config["embedding"]["provider"]
        self.embedding_model = config["embedding"]["model"]
        self.embedding_api_key = config["embedding"]["api_key"]
        
        # Translation configuration
        self.translation_provider = config["translation"]["provider"]
        self.translation_model = config["translation"].get("model", "")
        self.translation_api_key = config["translation"].get("api_key", "")
        
        # Search configuration
        self.default_limit = config["search"]["default_limit"]
        self.min_similarity = config["search"]["min_similarity"]
    
    def translate_query(self, query: str) -> str:
        """
        Translate query to English (multilingual support)
        
        Args:
            query: Original query
        
        Returns:
            Translated query (English) or original
        """
        if self.translation_provider == "none":
            return query
        
        try:
            if self.translation_provider == "anthropic":
                from anthropic import Anthropic
                
                anthropic = Anthropic(api_key=self.translation_api_key)
                
                response = anthropic.messages.create(
                    model=self.translation_model,
                    max_tokens=100,
                    temperature=0.3,
                    messages=[
                        {
                            "role": "user",
                            "content": f"You are a search query translator. Translate the following search query to English. Keep it short and natural. Preserve technical terms.\n\nQuery: {query}"
                        }
                    ]
                )
                
                return response.content[0].text.strip()
            
            elif self.translation_provider == "openai":
                import openai as oai
                
                oai.api_key = self.translation_api_key
                
                response = oai.chat.completions.create(
                    model=self.translation_model,
                    max_tokens=100,
                    temperature=0.3,
                    messages=[
                        {
                            "role": "user",
                            "content": f"You are a search query translator. Translate the following search query to English. Keep it short and natural. Preserve technical terms.\n\nQuery: {query}"
                        }
                    ]
                )
                
                return response.choices[0].message.content.strip()
            
            else:
                return query
        
        except Exception as e:
            print(f"      ⚠️  번역 실패, 원문 사용: {str(e)[:100]}")
            return query
    
    def get_embedding(self, text: str) -> List[float]:
        """
        텍스트를 벡터로 변환
        
        Args:
            text: 입력 텍스트
        
        Returns:
            임베딩 벡터
        """
        if self.embedding_provider == "openai":
            openai.api_key = self.embedding_api_key
            
            response = openai.embeddings.create(
                model=self.embedding_model,
                input=text
            )
            return response.data[0].embedding
        
        elif self.embedding_provider == "cohere":
            import cohere
            
            co = cohere.Client(self.embedding_api_key)
            response = co.embed(
                texts=[text],
                model=self.embedding_model,
                input_type="search_query"
            )
            return response.embeddings[0]
        
        else:
            raise ValueError(f"Unknown embedding provider: {self.embedding_provider}")
    
    def detect_temporal_intent(self, query: str) -> bool:
        """
        Detect if query asks about current/recent state
        
        Args:
            query: Search query
            
        Returns:
            True if query contains temporal keywords
        """
        temporal_keywords = [
            '지금', '현재', '최근', '최신', '오늘',
            'now', 'current', 'latest', 'recent', 'today'
        ]
        query_lower = query.lower()
        return any(keyword in query_lower for keyword in temporal_keywords)
    
    def search(
        self,
        query: str,
        limit: int = None,
        source: Optional[str] = None,
        author: Optional[str] = None,
        min_similarity: Optional[float] = None
    ) -> List[Dict]:
        """
        자연어 검색
        
        Args:
            query: 검색 쿼리
            limit: Number of results
            source: Source filter (e.g., "obsidian", "github")
            author: Author filter
            min_similarity: Minimum similarity %
        
        Returns:
            List of search results
        """
        # Set defaults
        if limit is None:
            limit = self.default_limit
        if min_similarity is None:
            min_similarity = self.min_similarity
        
        # Translate query
        translated_query = self.translate_query(query)
        if translated_query != query:
            print(f"🔍 Searching: '{query}' → EN: '{translated_query}'")
        else:
            print(f"🔍 Searching: '{query}'")
        
        # Generate embedding
        query_embedding = self.get_embedding(translated_query)
        
        # Search Supabase
        results = self.supabase.rpc('search_embeddings', {
            'query_embedding': query_embedding,
            'match_threshold': min_similarity / 100.0,
            'match_count': limit * 5
        }).execute()
        
        # Filter and format
        filtered = []
        for row in results.data:
            metadata = row['metadata']
            
            # Source filter
            if source and metadata.get('source') != source:
                continue
            
            # Author filter
            if author and metadata.get('author') != author:
                continue
            
            # Calculate similarity
            similarity = round(row['similarity'] * 100, 1)
            
            # Minimum similarity filter
            if similarity < min_similarity:
                continue
            
            # Prefer original language (Korean if available, else English)
            text_original = metadata.get('text_original', '')
            text_en = metadata.get('text', '')
            
            filtered.append({
                'path': metadata['path'],
                'text': text_original if text_original else text_en,  # Original first!
                'text_en': text_en,  # English translation (provided separately)
                'similarity': similarity,
                'author': metadata.get('author', 'unknown'),
                'source': metadata.get('source', 'unknown'),
                'date': metadata.get('date', '')
            })
        
        # Sort by similarity, with date consideration for temporal queries
        is_temporal = self.detect_temporal_intent(query)
        
        if is_temporal and filtered:
            # For temporal queries: weighted scoring (70% similarity + 30% recency)
            from datetime import datetime
            
            for result in filtered:
                date_str = result.get('date', '')
                
                if date_str:
                    try:
                        doc_date = datetime.fromisoformat(date_str[:10])
                        days_ago = (datetime.now() - doc_date).days
                        # Recency score: 100 at 0 days, decreases gradually
                        recency_score = max(0, 100 - (days_ago / 10))
                    except:
                        recency_score = 0
                else:
                    recency_score = 0
                
                # Weighted final score: 60% similarity + 40% recency
                result['final_score'] = result['similarity'] * 0.6 + recency_score * 0.4
            
            # Sort by final score
            filtered.sort(key=lambda x: x.get('final_score', x['similarity']), reverse=True)
        else:
            # Default: sort by similarity only
            filtered.sort(key=lambda x: x['similarity'], reverse=True)
        
        return filtered[:limit]
    
    def format_results(self, results: List[Dict]) -> str:
        """
        검색 결과 포맷
        
        Args:
            results: search() 결과
        
        Returns:
            포맷된 문자열
        """
        if not results:
            return "❌ 검색 결과가 없습니다."
        
        output = [f"✅ {len(results)}개 결과 발견:\n"]
        
        for i, result in enumerate(results, 1):
            output.append(
                f"{i}. [{result['similarity']}%] {result['path']}\n"
                f"   작성자: {result['author']} | 소스: {result['source']}\n"
                f"   내용: {result['text'][:100]}{'...' if len(result['text']) > 100 else ''}\n"
            )
        
        return "\n".join(output)


def main():
    """CLI 진입점"""
    import sys
    
    if len(sys.argv) < 2:
        print("사용법: python search.py '<검색어>'")
        sys.exit(1)
    
    query = sys.argv[1]
    
    try:
        searcher = KnowledgeSearch()
        results = searcher.search(query)
        print(searcher.format_results(results))
    except FileNotFoundError:
        print("❌ config.json 파일이 없습니다.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 오류: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
