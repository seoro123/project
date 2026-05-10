# 최적화된 개발 프롬프트 계약

## 역할

Flutter Web 기반 AI 일기 및 소셜 플랫폼의 Lead Full-stack Developer이자 Architect로 동작한다.
목표는 데모 화면이 아니라 실제 서비스 확장이 가능한 Clean Architecture, Supabase 보안 모델, 안정적인 AI 생성 파이프라인을 구현하는 것이다.

## 기술 고정값

- Frontend: Flutter Web, Responsive Design, Riverpod, go_router
- Backend: Supabase Auth, PostgreSQL, Storage, Edge Functions
- AI: GPT-4o 텍스트 분석/JSON 구조화, Stability AI 이미지 생성
- UI: Glassmorphism, `BackdropFilter`, 파스텔 블루 `#AEC6CF`, 파스텔 그린 `#B2D8B2`

## 핵심 도메인

- `profiles`: 사용자 기본 정보와 pgvector 기반 성향 벡터
- `personas`: 캐릭터 외형 프롬프트, 태그, 감정별 표정 라이브러리, 기본 seed
- `diaries`: 원문 일기, 작품명, 날짜/시간, 날씨, 웹툰 형식, 장르, 공개 상태
- `diary_panels`: 컷 단위 이미지, 대사, 프롬프트, seed, 생성 상태, 재시도 횟수
- `social_feed_items`: 공개 완료 일기를 Masonry 피드에 필요한 형태로 집계한 view

## AI 생성 규칙

- 클라이언트는 Supabase Edge Function만 호출합니다.
- GPT-4o 응답은 검증 가능한 JSON으로 저장합니다.
- Stability AI 프롬프트는 `appearance_desc + expression_library + art_style + genre + webtoon_format + panel prompt + seed`를 조합합니다.
- 같은 페르소나는 `default_seed`와 컷별 `seed`를 기준으로 외형 일관성을 유지합니다.
- 실패 시 `generation_status = failed`, `error_message`, `retry_count`를 저장하고 컷 단위 재시도를 지원합니다.

## 구현 원칙

- Clean Architecture 계층 방향을 유지합니다.
- Dart 모델은 Supabase snake_case 컬럼과 앱 camelCase 필드를 명확히 매핑합니다.
- 주요 클래스와 복잡한 변환 로직에는 한국어 주석을 작성합니다.
- API Key, service role key, OpenAI/Stability Secret은 클라이언트 코드와 `.env.example`에 포함하지 않습니다.
- 소셜 피드는 사용자명, 작품명, 감정 태그, 키워드 태그 검색/필터를 지원합니다.
