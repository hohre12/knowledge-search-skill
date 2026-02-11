"""
Knowledge Search - 데이터 임베딩

Obsidian 문서를 청크로 분할하여 Vector DB에 저장
"""

import json
import openai
from supabase import create_client
from typing import List, Dict, Optional
from pathlib import Path
import hashlib
import tiktoken
import re
from datetime import datetime


class KnowledgeIngest:
    """데이터 임베딩 및 저장"""
    
    def __init__(self, config_path: str = "config.json"):
        """초기화"""
        with open(config_path) as f:
            config = json.load(f)
        
        self.config = config
        
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
        
        # Chunking configuration
        self.chunk_size = 512
        self.chunk_overlap = 128
        self.min_chunk_size = 100
        
        # tiktoken encoder
        self.encoding = tiktoken.get_encoding("cl100k_base")
    
    def translate_text(self, text: str) -> str:
        """
        텍스트를 영어로 번역
        
        Args:
            text: 원본 텍스트
        
        Returns:
            번역된 텍스트 또는 원본
        """
        if self.translation_provider == "none":
            return text
        
        try:
            if self.translation_provider == "anthropic":
                from anthropic import Anthropic
                
                anthropic = Anthropic(api_key=self.translation_api_key)
                
                response = anthropic.messages.create(
                    model=self.translation_model,
                    max_tokens=4096,
                    temperature=0.3,
                    messages=[
                        {
                            "role": "user",
                            "content": f"You are a professional translator. Translate the following text to English. Preserve formatting, markdown, and technical terms. Keep it natural and accurate.\n\n{text}"
                        }
                    ]
                )
                
                return response.content[0].text
            
            elif self.translation_provider == "openai":
                import openai as oai
                
                oai.api_key = self.translation_api_key
                
                response = oai.chat.completions.create(
                    model=self.translation_model,
                    max_tokens=4096,
                    temperature=0.3,
                    messages=[
                        {
                            "role": "user",
                            "content": f"You are a professional translator. Translate the following text to English. Preserve formatting, markdown, and technical terms. Keep it natural and accurate.\n\n{text}"
                        }
                    ]
                )
                
                return response.choices[0].message.content
            
            else:
                return text
        
        except Exception as e:
            print(f"      ⚠️  번역 실패, 원문 사용: {str(e)[:100]}")
            return text
    
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
                input_type="search_document"
            )
            return response.embeddings[0]
        
        else:
            raise ValueError(f"Unknown embedding provider: {self.embedding_provider}")
    
    def chunk_text(self, text: str, metadata: dict) -> List[Dict]:
        """
        텍스트를 청크로 분할
        
        Args:
            text: 원본 텍스트
            metadata: 메타데이터
        
        Returns:
            청크 리스트
        """
        # Check word count
        word_count = len(text.split())
        
        # 짧은 문서는 전체 임베딩
        if word_count < 200:
            return [{
                "text": text,
                "chunk_index": 0,
                "total_chunks": 1,
                **metadata
            }]
        
        # 토큰화
        tokens = self.encoding.encode(text)
        
        # 청크 분할
        chunks = []
        start = 0
        chunk_index = 0
        
        while start < len(tokens):
            end = min(start + self.chunk_size, len(tokens))
            chunk_tokens = tokens[start:end]
            
            # 토큰을 텍스트로 디코딩
            chunk_text = self.encoding.decode(chunk_tokens)
            
            # 최소 크기 확인
            if len(chunk_tokens) >= self.min_chunk_size:
                chunks.append({
                    "text": chunk_text.strip(),
                    "chunk_index": chunk_index,
                    **metadata
                })
                chunk_index += 1
            
            # 다음 청크 시작 (겹침 고려)
            start += (self.chunk_size - self.chunk_overlap)
        
        # total_chunks 추가
        for chunk in chunks:
            chunk["total_chunks"] = len(chunks)
        
        return chunks
    
    def parse_creation_date(self, content: str) -> Optional[str]:
        """
        파일 내용에서 생성일 파싱
        
        Args:
            content: 파일 전체 내용
        
        Returns:
            ISO 8601 형식의 날짜 문자열 또는 None
        """
        # Apple Notes 형식: "Created: 2016년 2월 26일 금요일 오전 2:42:56"
        pattern = r'Created:\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일.*?(\d{1,2}):(\d{2}):(\d{2})'
        match = re.search(pattern, content)
        
        if match:
            try:
                year = int(match.group(1))
                month = int(match.group(2))
                day = int(match.group(3))
                hour = int(match.group(4))
                minute = int(match.group(5))
                second = int(match.group(6))
                
                # 오전/오후 처리
                if '오후' in content[match.start():match.end()+10] and hour < 12:
                    hour += 12
                elif '오전' in content[match.start():match.end()+10] and hour == 12:
                    hour = 0
                
                dt = datetime(year, month, day, hour, minute, second)
                return dt.isoformat()
            except:
                pass
        
        return None
    
    def parse_category(self, content: str) -> Optional[str]:
        """
        파일 내용에서 카테고리 파싱
        
        Args:
            content: 파일 전체 내용
        
        Returns:
            카테고리 문자열 또는 None
        """
        # 파일 첫 줄에서 "Category: [카테고리명]" 형식 파싱
        lines = content.split('\n')
        if lines and lines[0].strip().startswith("Category:"):
            category = lines[0].replace("Category:", "").strip()
            return category if category else None
        
        return None
    
    def ingest_file(self, file_path: Path, source: str = "obsidian", author: str = "unknown"):
        """
        파일을 읽어서 임베딩
        
        Args:
            file_path: 파일 경로
            source: 소스 이름
            author: 작성자
        """
        # 파일 읽기
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if not content.strip():
            print(f"   ⏭️  빈 파일: {file_path.name}")
            return
        
        # 생성일 파싱
        created_date = self.parse_creation_date(content)
        
        # 카테고리 파싱
        category = self.parse_category(content)
        
        # 메타데이터
        metadata = {
            "path": str(file_path.relative_to(Path.home())),
            "source": source,
            "author": author,
            "folder": file_path.parent.name,
            "file_hash": hashlib.md5(content.encode()).hexdigest()
        }
        
        # 생성일이 있으면 추가
        if created_date:
            metadata["created_date"] = created_date
            # date 필드도 추가 (날짜만, YYYY-MM-DD)
            metadata["date"] = created_date.split("T")[0]
        
        # 카테고리가 있으면 추가
        if category:
            metadata["category"] = category
        
        # 청킹
        chunks = self.chunk_text(content, metadata)
        print(f"   📝 {len(chunks)}개 청크")
        
        # 각 청크 처리
        for i, chunk in enumerate(chunks, 1):
            # 원문 저장
            text_original = chunk["text"]
            
            # 번역
            text_translated = self.translate_text(text_original)
            if self.translation_provider != "none":
                print(f"      [{i}/{len(chunks)}] 번역 완료")
            
            # 임베딩
            embedding = self.get_embedding(text_translated)
            print(f"      [{i}/{len(chunks)}] 임베딩 완료")
            
            # 메타데이터 구성
            final_metadata = {
                **chunk,
                "text": text_translated,
                "text_original": text_original
            }
            
            # Supabase에 저장
            self.supabase.table("embeddings").insert({
                "embedding": embedding,
                "metadata": final_metadata
            }).execute()
        
        print(f"   ✅ {file_path.name} 저장 완료")
    
    def ingest_folder(self, folder_name: str, source: str = "obsidian", author: str = "unknown"):
        """
        폴더 내 모든 .md 파일 임베딩
        
        Args:
            folder_name: 폴더 이름
            source: 소스 이름
            author: 작성자
        """
        # Obsidian 경로
        obsidian_path = Path(self.config["sources"]["obsidian"]["path"]).expanduser()
        folder_path = obsidian_path / folder_name
        
        if not folder_path.exists():
            print(f"❌ 폴더를 찾을 수 없습니다: {folder_path}")
            return
        
        # .md 파일 목록
        md_files = list(folder_path.glob("*.md"))
        
        if not md_files:
            print(f"❌ .md 파일이 없습니다: {folder_name}")
            return
        
        print(f"📂 {folder_name} ({len(md_files)}개 파일)")
        
        for file_path in md_files:
            try:
                self.ingest_file(file_path, source, author)
            except Exception as e:
                print(f"   ❌ 오류: {file_path.name} - {str(e)[:100]}")


def main():
    """CLI 진입점"""
    import sys
    
    if len(sys.argv) < 2:
        print("사용법: python ingest.py <folder>")
        sys.exit(1)
    
    folder = sys.argv[1]
    
    try:
        ingestor = KnowledgeIngest()
        ingestor.ingest_folder(folder)
    except Exception as e:
        print(f"❌ 오류: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
