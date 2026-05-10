-- 앱에서 자동 생성했던 기본 캐릭터 2종만 제거합니다.
-- 사용자가 직접 만든 동명 캐릭터가 지워지지 않도록 seed와 생성 상태까지 함께 확인합니다.
delete from public.personas
where name in ('여자', '남자')
  and default_seed in (1201, 1202)
  and input_mode = 'tags'
  and is_public = false
  and generation_status = 'completed';

select pg_notify('pgrst', 'reload schema');
