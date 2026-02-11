#!/usr/bin/env python3
"""
Apple Notes에 카테고리 추가 스크립트
각 메모 파일 최상단에 "Category: [카테고리명]" 추가
"""

import os
from pathlib import Path

# 카테고리 분류 규칙 (파일명 기반)
CATEGORY_RULES = {
    "운동/피트니스": [
        "운동", "루틴", "상체", "하체", "가슴", "복근", "팔", "인바디"
    ],
    "창업/비즈니스": [
        "북적북적", "창업", "아이템", "인력", "알바", "어플"
    ],
    "엔터테인먼트": [
        "영화", "책", "러브로지", "모엣샹동"
    ],
    "여행": [
        "여행", "챙겨야"
    ],
    "의료/건강": [
        "병원", "응급실", "할머니", "간호사", "의사", "시술", "발작", "심실성", "빈맥", "손승우"
    ],
    "학습/자격증": [
        "자격증", "중개사"
    ]
}

def categorize_file(filename: str) -> str:
    """파일명 기반 카테고리 분류"""
    filename_lower = filename.lower()
    
    for category, keywords in CATEGORY_RULES.items():
        for keyword in keywords:
            if keyword in filename_lower:
                return category
    
    return "기타"

def add_category_to_file(file_path: Path):
    """파일 최상단에 카테고리 추가"""
    # 카테고리 결정
    category = categorize_file(file_path.name)
    
    # 파일 내용 읽기
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 이미 Category가 있으면 스킵
    if content.startswith("Category:"):
        print(f"⏭️  Already has category: {file_path.name}")
        return
    
    # Category 추가
    new_content = f"Category: {category}\n\n{content}"
    
    # 파일 쓰기
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✅ Added [{category}] to: {file_path.name}")

def main():
    source_dir = Path.home() / "apple-notes-export/batch_1_selected"
    
    if not source_dir.exists():
        print(f"❌ Directory not found: {source_dir}")
        return
    
    print(f"📁 Processing files in: {source_dir}\n")
    
    # 모든 .md 파일 처리
    md_files = sorted(source_dir.glob("*.md"))
    
    if not md_files:
        print("❌ No .md files found")
        return
    
    print(f"📝 Found {len(md_files)} files\n")
    
    # 카테고리별 통계
    category_stats = {}
    
    for file_path in md_files:
        category = categorize_file(file_path.name)
        category_stats[category] = category_stats.get(category, 0) + 1
        add_category_to_file(file_path)
    
    # 통계 출력
    print("\n" + "="*50)
    print("📊 Category Statistics:")
    print("="*50)
    for category, count in sorted(category_stats.items(), key=lambda x: x[1], reverse=True):
        print(f"  {category}: {count}개")
    print("="*50)

if __name__ == "__main__":
    main()
