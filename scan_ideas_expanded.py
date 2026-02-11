#!/usr/bin/env python3
"""
아이디어/아이템 항목은 더 관대하게 선별
나머지는 엄격하게 유지
"""

import os
import re
from datetime import datetime
from pathlib import Path

# 강력 제외 키워드
HARD_EXCLUDE = [
    '살거', '사기', '쇼핑', '주문', '배송', '택배', '결제', '인터넷신청',
    '전화번호', '주소', '비밀번호', '냉장고', '세탁기', '청소', '설거지',
    '옷장', '침대', '매트리스', 'ok', '완료', '체크', '확인',
    '맵코드', '공항', '항공', '호텔', '숙소', '렌트', '예산'
]

# 아이디어 키워드 (더 광범위하게)
IDEA_KEYWORDS = [
    '아이디어', '아이템', '창업', '사업', '어플', '앱', '웹사이트', '서비스',
    '프로젝트', '플랫폼', '솔루션', '비즈니스', '스타트업', '개발',
    '구축', '제작', '만들', 'sdk', 'api', '시스템', '포트폴리오',
    '면접', '이직', '입사', '지원', '포폴', '기술스택'
]

# 깊은 철학/고민
DEEP_THOUGHT = [
    '이유', '철학', '가치관', '인생', '도전', '성장', '배움',
    '깨달음', '반성', '고민', '결정', '선택', '방향', '목표',
    '의미', '왜', '어떻게', '나는', '생각하는', '느낀'
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
    score = 0
    
    # 1. 강력 제외 키워드 체크
    exclude_count = sum(1 for kw in HARD_EXCLUDE if kw in text_lower)
    if exclude_count > 0:
        # 아이디어 키워드가 있으면 살릴 수 있음
        idea_count = sum(1 for kw in IDEA_KEYWORDS if kw in text_lower)
        if idea_count < 2:  # 아이디어 키워드가 2개 미만이면 제외
            return None
    
    # 2. 너무 짧으면 제외
    if len(content.strip()) < 150:
        return None
    
    # 3. HTML 태그만 가득하면 제외
    html_content = re.sub(r'<[^>]+>', '', content)
    if len(html_content.strip()) < 80:
        return None
    
    # 4. 아이디어/아이템 (관대하게)
    idea_count = sum(1 for kw in IDEA_KEYWORDS if kw in text_lower)
    if idea_count >= 1:
        categories.append("아이디어/아이템")
        score += idea_count * 2
    
    # 5. 개인 철학 (엄격하게)
    thought_count = sum(1 for kw in DEEP_THOUGHT if kw in text_lower)
    if thought_count >= 2 and len(content) >= 300:
        categories.append("개인 철학")
        score += thought_count
    
    # 6. 개인적 고민 (엄격하게)
    concern_keywords = ['고민', '걱정', '불안', '선택', '결정', '어려움', '위험', '도전']
    concern_count = sum(1 for kw in concern_keywords if kw in text_lower)
    if concern_count >= 1 and len(content) >= 250:
        categories.append("개인적 고민")
        score += concern_count * 1.5
    
    # 7. 학습+느낀점 (엄격하게)
    learning_keywords = ['배운', '깨달은', '느낀', '이해', '알게된', '경험']
    learning_count = sum(1 for kw in learning_keywords if kw in text_lower)
    if learning_count >= 1 and len(content) >= 250:
        tech_keywords = ['개발', '코딩', 'typescript', 'react', 'vue', 'api', 'backend', 'frontend']
        if any(kw in text_lower for kw in tech_keywords):
            categories.append("학습+느낀점")
            score += learning_count * 1.5
    
    # 8. 점수 기준 (아이디어는 관대)
    if "아이디어/아이템" in categories:
        if score < 1.5:
            return None
    else:
        if score < 2:
            return None
    
    return {
        'categories': categories,
        'score': score,
        'length': len(content)
    }

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
    print("🔍 아이디어/아이템 확장 선별 (101번 이후)")
    print("="*80)
    
    selected = []
    
    # 101번 이후만 처리
    for i, (dt, filename, content) in enumerate(files[100:], start=101):
        quality = categorize_content(filename, content)
        
        if quality:
            selected.append({
                'index': i,
                'filename': filename,
                'date': dt,
                'categories': quality['categories'],
                'score': quality['score'],
                'length': quality['length'],
                'preview': content[:300].replace('\n', ' ').strip()
            })
    
    # 점수 순으로 정렬
    selected.sort(key=lambda x: x['score'], reverse=True)
    
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
        
        # 점수순 정렬
        items_sorted = sorted(items, key=lambda x: x['score'], reverse=True)
        
        for i, item in enumerate(items_sorted, 1):
            print(f"{i}. [{item['index']}] {item['filename']}")
            print(f"   날짜: {item['date'].strftime('%Y-%m-%d')} | 점수: {item['score']:.1f} | 길이: {item['length']}자")
    
    # 전체 리스트 파일로 저장
    output_file = notes_dir / "selected_expanded.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        for item in selected:
            f.write(f"{item['index']}. {item['filename']}\n")
            f.write(f"   날짜: {item['date'].strftime('%Y-%m-%d %H:%M')}\n")
            f.write(f"   카테고리: {', '.join(item['categories'])}\n")
            f.write(f"   품질점수: {item['score']:.1f}\n\n")
    
    print(f"\n\n💾 전체 목록 저장: {output_file}")
    print(f"총 {len(selected)}개 항목")

if __name__ == "__main__":
    main()
