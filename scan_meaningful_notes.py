#!/usr/bin/env python3
"""
101번 이후 메모에서 의미있는 콘텐츠 선별

카테고리:
1. 아이디어/아이템 - 창업, 사업, 프로젝트 구상
2. 개인 철학 - 인생관, 가치관, 생각
3. 개인적 고민 - 진로, 인생, 창업, 가족 고민
4. 학습 + 느낀점 - 개발, 기술, 책 등 학습 내용
"""

import os
import re
from datetime import datetime
from pathlib import Path

# 제외 키워드 (쇼핑, 단순 메모)
EXCLUDE_KEYWORDS = [
    '살거', '사기', '쇼핑', '주문', '배송', '택배', '결제',
    '인터넷신청', '전화번호', '주소', '비밀번호', 
    '냉장고', '세탁기', '청소', '설거지', '옷장', '침대', '매트리스',
    'ok', '완료', '체크', '확인'
]

# 포함 키워드
IDEA_KEYWORDS = [
    '아이디어', '아이템', '창업', '사업', '어플', '앱', '웹사이트', '서비스',
    '프로젝트', '플랫폼', '솔루션', '비즈니스', '스타트업'
]

PHILOSOPHY_KEYWORDS = [
    '생각', '철학', '인생', '가치', '의미', '목표', '꿈', '비전',
    '성공', '실패', '행복', '관계', '사랑', '자유', '성장',
    '무엇을', '왜', '어떻게', '나는'
]

CONCERN_KEYWORDS = [
    '고민', '걱정', '불안', '두려움', '선택', '결정', '갈등',
    '어려움', '문제', '위험', '도전', '한계', '방향'
]

LEARNING_KEYWORDS = [
    '배운', '깨달은', '느낀', '알게된', '이해', '공부', '학습',
    '책', '강의', '튜토리얼', '정리', '요약', '리뷰',
    '개발', '코딩', 'programming', 'algorithm', 'framework'
]

def parse_creation_date(content):
    """생성일 파싱"""
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
            
            if '오후' in content[match.start():match.end()+10] and hour < 12:
                hour += 12
            elif '오전' in content[match.start():match.end()+10] and hour == 12:
                hour = 0
            
            dt = datetime(year, month, day, hour, minute, second)
            return dt
        except:
            pass
    
    return None

def categorize_content(filename, content):
    """내용 분석하여 카테고리 판단"""
    text = filename + "\n" + content
    text_lower = text.lower()
    
    categories = []
    
    # 제외 조건 체크
    if any(kw in text_lower for kw in EXCLUDE_KEYWORDS):
        # 단, 다른 강력한 키워드가 있으면 유지
        strong_keywords = IDEA_KEYWORDS + PHILOSOPHY_KEYWORDS + CONCERN_KEYWORDS
        if not any(kw in text_lower for kw in strong_keywords):
            return None
    
    # 너무 짧으면 제외 (50자 이하)
    if len(content.strip()) < 50:
        return None
    
    # 카테고리 판단
    if any(kw in text_lower for kw in IDEA_KEYWORDS):
        categories.append("아이디어/아이템")
    
    if any(kw in text_lower for kw in PHILOSOPHY_KEYWORDS):
        # 철학적 내용인지 추가 검증 (문장 길이)
        if len(content) > 100:
            categories.append("개인 철학")
    
    if any(kw in text_lower for kw in CONCERN_KEYWORDS):
        categories.append("개인적 고민")
    
    if any(kw in text_lower for kw in LEARNING_KEYWORDS):
        categories.append("학습+느낀점")
    
    # 질문 형태 체크 (철학/고민)
    if '?' in text or '?' in text:
        if not categories:
            categories.append("개인 철학")
    
    return categories if categories else None

def main():
    notes_dir = Path.home() / "apple-notes-export"
    
    # 모든 파일 읽기
    files = []
    for f in notes_dir.glob("*.md"):
        if f.name.startswith('README') or f.name.startswith('SETUP') or f.name.startswith('note-list'):
            continue
        
        try:
            with open(f, 'r', encoding='utf-8') as file:
                content = file.read()
            
            dt = parse_creation_date(content)
            if dt:
                files.append((dt, f.name, content))
        except:
            pass
    
    # 날짜순 정렬
    files.sort(key=lambda x: x[0])
    
    print(f"총 {len(files)}개 파일 스캔\n")
    print("="*80)
    print("101번 이후 의미있는 메모 선별")
    print("="*80)
    
    selected = []
    
    # 101번 이후만 처리
    for i, (dt, filename, content) in enumerate(files[100:], start=101):
        categories = categorize_content(filename, content)
        
        if categories:
            selected.append({
                'index': i,
                'filename': filename,
                'date': dt,
                'categories': categories,
                'preview': content[:200].replace('\n', ' ').strip()
            })
    
    # 카테고리별로 그룹화
    by_category = {
        '아이디어/아이템': [],
        '개인 철학': [],
        '개인적 고민': [],
        '학습+느낀점': []
    }
    
    for item in selected:
        for cat in item['categories']:
            by_category[cat].append(item)
    
    # 결과 출력
    print(f"\n📊 총 {len(selected)}개 선별됨\n")
    
    for cat_name, items in by_category.items():
        if not items:
            continue
        
        print(f"\n{'='*80}")
        print(f"📌 {cat_name} ({len(items)}개)")
        print('='*80)
        
        for item in items[:50]:  # 각 카테고리 최대 50개
            print(f"\n{item['index']}. {item['filename']}")
            print(f"   날짜: {item['date'].strftime('%Y-%m-%d %H:%M')}")
            print(f"   카테고리: {', '.join(item['categories'])}")
            print(f"   미리보기: {item['preview'][:150]}...")
    
    # 전체 리스트 파일로 저장
    output_file = notes_dir / "selected_meaningful_101plus.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        for item in selected:
            f.write(f"{item['index']}. {item['filename']}\n")
            f.write(f"   날짜: {item['date'].strftime('%Y-%m-%d %H:%M')}\n")
            f.write(f"   카테고리: {', '.join(item['categories'])}\n\n")
    
    print(f"\n\n💾 전체 목록 저장: {output_file}")
    print(f"총 {len(selected)}개 항목")

if __name__ == "__main__":
    main()
