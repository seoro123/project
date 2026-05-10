-- SQL Editor 내용을 전부 지운 뒤, 이 파일 내용만 실행하세요.
-- 이 파일은 테이블을 만들지 않으므로 "relation profiles already exists"가 날 수 없습니다.

select to_regclass('public.profiles') as profiles_table;
select to_regclass('public.diaries') as diaries_table;
select to_regclass('public.personas') as personas_table;
select pg_notify('pgrst', 'reload schema');
