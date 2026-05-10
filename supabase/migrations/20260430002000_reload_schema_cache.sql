-- 첫 baseline 적용 뒤 Supabase REST/PostgREST가 새 테이블을 못 보는 경우를 복구합니다.
-- "relation profiles already exists"가 뜬 상태에서는 baseline을 다시 실행하지 말고 이 파일만 실행하세요.

select pg_notify('pgrst', 'reload schema');

