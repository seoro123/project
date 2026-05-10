-- OpenAI 프롬프트 단계에서 실패한 캐릭터 row를 정리합니다.
-- Gemini 전용 생성으로 전환했으므로 이 실패 기록은 재시도 UX를 방해합니다.
delete from public.personas
where generation_status = 'failed'
  and (
    coalesce(error_message, '') ilike '%openai%'
    or coalesce(error_message, '') ilike '%insufficient_quota%'
    or coalesce(error_message, '') ilike '%quota%'
    or coalesce(error_message, '') ilike '%이전 OpenAI%'
  );

select pg_notify('pgrst', 'reload schema');
