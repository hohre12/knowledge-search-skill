#!/usr/bin/env python3
"""
Batch 임베딩 스크립트 - 절대 경로 지원
"""

import sys
from pathlib import Path
from src.ingest import KnowledgeIngest

def main():
    if len(sys.argv) < 2:
        print("사용법: python batch_ingest.py <folder_path> [source] [author]")
        sys.exit(1)
    
    folder_path = Path(sys.argv[1]).expanduser().resolve()
    source = sys.argv[2] if len(sys.argv) > 2 else "apple-notes"
    author = sys.argv[3] if len(sys.argv) > 3 else "jaewon"
    
    if not folder_path.exists():
        print(f"❌ 폴더를 찾을 수 없습니다: {folder_path}")
        sys.exit(1)
    
    # .md 파일 목록
    md_files = list(folder_path.glob("*.md"))
    
    if not md_files:
        print(f"❌ .md 파일이 없습니다: {folder_path}")
        sys.exit(1)
    
    print(f"📂 {folder_path.name} ({len(md_files)}개 파일)")
    print(f"🔧 Source: {source}, Author: {author}")
    print("")
    
    ingestor = KnowledgeIngest()
    
    success = 0
    failed = 0
    
    for i, file_path in enumerate(md_files, 1):
        try:
            print(f"[{i}/{len(md_files)}] {file_path.name}...", end=" ", flush=True)
            ingestor.ingest_file(file_path, source, author)
            print("✅")
            success += 1
        except Exception as e:
            print(f"❌ {str(e)[:80]}")
            failed += 1
    
    print("")
    print(f"✅ 완료: {success}개")
    if failed > 0:
        print(f"❌ 실패: {failed}개")

if __name__ == "__main__":
    main()
