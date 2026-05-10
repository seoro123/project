# 전체 폴더 구조

```text
project/
├─ docs/
│  ├─ folder_structure.md
│  └─ prompt_contract.md
├─ lib/
│  ├─ main.dart
│  ├─ app/
│  │  ├─ app.dart
│  │  └─ config/
│  ├─ core/
│  │  ├─ constants/          # 전역 상수와 환경 변수 키
│  │  ├─ enums/              # DB 값과 1:1로 매핑되는 enum
│  │  ├─ errors/             # 예외와 실패 메시지
│  │  ├─ extensions/         # UI/도메인 확장 메서드
│  │  ├─ network/            # 네트워크 공통 정책
│  │  ├─ result/             # 성공/실패 결과 래퍼
│  │  ├─ router/             # go_router 라우팅
│  │  ├─ supabase/           # Supabase 클라이언트 Provider
│  │  ├─ theme/              # Glassmorphism, 파스텔 색상, 타이포그래피
│  │  ├─ utils/              # 순수 유틸리티
│  │  └─ widgets/            # 여러 feature가 공유하는 위젯
│  └─ features/
│     ├─ auth/
│     │  ├─ data/
│     │  ├─ domain/
│     │  └─ presentation/
│     ├─ profile/
│     │  ├─ data/models/
│     │  ├─ domain/entities/
│     │  └─ presentation/
│     ├─ persona/
│     │  ├─ data/models/
│     │  ├─ data/repositories/
│     │  ├─ domain/entities/
│     │  ├─ domain/repositories/
│     │  ├─ domain/usecases/
│     │  └─ presentation/
│     ├─ diary/
│     │  ├─ data/models/
│     │  ├─ data/repositories/
│     │  ├─ domain/entities/
│     │  ├─ domain/repositories/
│     │  ├─ domain/usecases/
│     │  └─ presentation/
│     ├─ feed/
│     │  ├─ data/models/
│     │  ├─ data/repositories/
│     │  ├─ domain/entities/
│     │  ├─ domain/repositories/
│     │  └─ presentation/
│     └─ ai_pipeline/
│        ├─ data/dtos/
│        ├─ data/repositories/
│        ├─ domain/entities/
│        ├─ domain/usecases/
│        └─ presentation/
├─ supabase/
│  ├─ functions/
│  │  ├─ _shared/
│  │  ├─ generate-diary-assets/
│  │  └─ generate-persona-image/
│  ├─ migrations/
│  └─ seed/
├─ test/
├─ web/
├─ analysis_options.yaml
└─ pubspec.yaml
```

## 계층 규칙

- `domain`은 Flutter, Supabase, HTTP를 직접 import하지 않는 순수 계층으로 유지합니다.
- `data`는 Supabase row, Edge Function response, JSON 직렬화를 담당합니다.
- `presentation`은 Riverpod provider, 화면, 위젯만 포함합니다.
- AI Key와 프롬프트 조립은 클라이언트가 아니라 Supabase Edge Functions에서만 수행합니다.
- 일기 생성 결과는 `diaries`의 전체 상태와 `diary_panels`의 컷 단위 상태를 함께 사용합니다.
