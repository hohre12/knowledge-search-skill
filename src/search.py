"""
Knowledge Search - 검색 로직

OpenClaw 에이전트들이 사용하는 핵심 검색 기능
"""

import json
import openai
from supabase import create_client
from typing import List, Dict, Optional
from pathlib import Path


class KnowledgeSearch:
    """Vector DB 기반 지식 검색"""
    
    def __init__(self, config_path: str = "config.json"):
        """
        초기화
        
        Args:
            config_path: 설정 파일 경로
        """
        # 설정 로드
        with open(config_path) as f:
            config = json.load(f)
        
        self.config = config
        
        # Supabase 클라이언트
        self.supabase = create_client(
            config["supabase"]["url"],
            config["supabase"]["key"]
        )
        
        # Embedding 설정
        self.embedding_provider = config["embedding"]["provider"]
        self.embedding_model = config["embedding"]["model"]
        self.embedding_api_key = config["embedding"]["api_key"]
        
        # Translation 설정
        self.translation_provider = config["translation"]["provider"]
        self.translation_model = config["translation"].get("model", "")
        self.translation_api_key = config["translation"].get("api_key", "")
        
        # 검색 설정
        self.default_limit = config["search"]["default_limit"]
        self.min_similarity = config["search"]["min_similarity"]
    
    def translate_query(self, query: str) -> str:
        """
        쿼리를 영어로 번역 (다국어 지원)
        
        Args:
            query: 원본 쿼리
        
        Returns:
            번역된 쿼리 (영어) 또는 원본
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
            limit: 결과 개수
            source: 소스 필터 (예: "obsidian", "github")
            author: 작성자 필터
            min_similarity: 최소 유사도 %
        
        Returns:
            검색 결과 리스트
        """
        # 기본값 설정
        if limit is None:
            limit = self.default_limit
        if min_similarity is None:
            min_similarity = self.min_similarity
        
        # 쿼리 번역
        translated_query = self.translate_query(query)
        if translated_query != query:
            print(f"🔍 검색 중: '{query}' → EN: '{translated_query}'")
        else:
            print(f"🔍 검색 중: '{query}'")
        
        # 임베딩 생성
        query_embedding = self.get_embedding(translated_query)
        
        # Supabase 검색
        results = self.supabase.rpc('search_embeddings', {
            'query_embedding': query_embedding,
            'match_threshold': min_similarity / 100.0,
            'match_count': limit * 3
        }).execute()
        
        # 필터링 및 포맷
        filtered = []
        for row in results.data:
            metadata = row['metadata']
            
            # 소스 필터
            if source and metadata.get('source') != source:
                continue
            
            # 작성자 필터
            if author and metadata.get('author') != author:
                continue
            
            # 유사도 계산
            similarity = round(row['similarity'] * 100, 1)
            
            # 최소 유사도 필터
            if similarity < min_similarity:
                continue
            
            # 원본 언어 우선 (한국어 있으면 한국어, 없으면 영어)
            text_original = metadata.get('text_original', '')
            text_en = metadata.get('text', '')
            
            filtered.append({
                'path': metadata['path'],
                'text': text_original if text_original else text_en,  # 원본 우선!
                'text_en': text_en,  # 영어 번역본 (별도 제공)
                'similarity': similarity,
                'author': metadata.get('author', 'unknown'),
                'source': metadata.get('source', 'unknown'),
                'date': metadata.get('date', '')
            })
        
        # 유사도 순 정렬
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
