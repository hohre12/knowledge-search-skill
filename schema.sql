-- Knowledge Search Vector DB Schema
-- Supabase pgvector를 사용한 임베딩 저장소

-- pgvector extension 활성화
CREATE EXTENSION IF NOT EXISTS vector;

-- embeddings 테이블 생성
CREATE TABLE IF NOT EXISTS embeddings (
  id BIGSERIAL PRIMARY KEY,
  embedding vector(1536),  -- OpenAI text-embedding-3-small: 1536 차원
  metadata JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 메타데이터 인덱스 (빠른 필터링)
CREATE INDEX IF NOT EXISTS idx_metadata_source ON embeddings USING GIN ((metadata->'source'));
CREATE INDEX IF NOT EXISTS idx_metadata_author ON embeddings USING GIN ((metadata->'author'));
CREATE INDEX IF NOT EXISTS idx_metadata_path ON embeddings USING GIN ((metadata->'path'));

-- 벡터 유사도 검색 인덱스 (IVFFlat)
-- lists 파라미터는 문서 개수에 따라 조정 (권장: rows/1000, 최소 10)
-- 초기에는 100으로 설정 (2,500개 문서 예상)
CREATE INDEX IF NOT EXISTS idx_embedding_vector ON embeddings 
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- 벡터 유사도 검색 함수
CREATE OR REPLACE FUNCTION search_embeddings(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.5,
  match_count int DEFAULT 10,
  filter_source text DEFAULT NULL,
  filter_author text DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  similarity float,
  metadata jsonb,
  created_at timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    embeddings.id,
    1 - (embeddings.embedding <=> query_embedding) AS similarity,
    embeddings.metadata,
    embeddings.created_at
  FROM embeddings
  WHERE 
    (filter_source IS NULL OR embeddings.metadata->>'source' = filter_source)
    AND (filter_author IS NULL OR embeddings.metadata->>'author' = filter_author)
    AND (1 - (embeddings.embedding <=> query_embedding)) >= match_threshold
  ORDER BY embeddings.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- 통계 확인 함수
CREATE OR REPLACE FUNCTION get_stats()
RETURNS TABLE (
  total_count bigint,
  sources jsonb,
  authors jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_count,
    jsonb_agg(DISTINCT metadata->'source') as sources,
    jsonb_agg(DISTINCT metadata->'author') as authors
  FROM embeddings;
END;
$$;

-- Row Level Security (RLS) 설정
ALTER TABLE embeddings ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽을 수 있도록 (API Key로 제어)
CREATE POLICY "Enable read access for all users" ON embeddings
  FOR SELECT USING (true);

-- 인증된 사용자만 쓸 수 있도록
CREATE POLICY "Enable insert for authenticated users only" ON embeddings
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role');

CREATE POLICY "Enable delete for authenticated users only" ON embeddings
  FOR DELETE USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');

-- 인덱스 통계 업데이트 (선택적, 대량 삽입 후 실행)
-- VACUUM ANALYZE embeddings;

COMMENT ON TABLE embeddings IS 'Vector embeddings for knowledge search system';
COMMENT ON COLUMN embeddings.embedding IS 'OpenAI text-embedding-3-small (1536 dimensions)';
COMMENT ON COLUMN embeddings.metadata IS 'Document metadata: path, text, author, source, date, visibility';
