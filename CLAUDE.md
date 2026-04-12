# SnapPuzzle — Claude Code 가이드

사진 기반 모바일 퍼즐 게임. 아이가 직접 찍은 사진으로 네 가지 퍼즐을 만드는 Flutter 앱.
- **대상**: 6~8세 / **플랫폼**: iPad (iPadOS 16+) + Android (API 26+)
- **기술 스택**: Flutter 3.x · Dart · Riverpod · SQLite · Flame Engine

---

## 개발 환경 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod, build_runner)
dart run build_runner build --delete-conflicting-outputs

# 테스트 실행
flutter test

# 정적 분석
flutter analyze

# 실행 (연결된 기기/에뮬레이터 필요)
flutter run

# 릴리즈 빌드
flutter build apk --release          # Android
flutter build ios --release          # iOS (Mac 필요)
```

---

## 프로젝트 구조

```
lib/
├── main.dart                        # 진입점 — ProviderScope 래핑
├── app.dart                         # MaterialApp + AppTheme
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # 파스텔 색상 팔레트
│   │   ├── app_sizes.dart           # 여백·반경·터치 타겟(≥48dp)
│   │   ├── app_strings.dart         # UI 문자열 (한국어)
│   │   └── app_theme.dart           # ThemeData (NanumRound 폰트)
│   ├── models/
│   │   ├── photo.dart               # 촬영·선택 사진 메타
│   │   ├── puzzle_type.dart         # PuzzleType enum + Difficulty enum
│   │   ├── puzzle_record.dart       # 퍼즐 완성 기록 (best_stars 등)
│   │   ├── user_profile.dart        # 레벨·별 누적·오늘 플레이 시간
│   │   └── settings.dart            # 보호자 설정 (PIN, 시간 제한 등)
│   └── database/
│       └── database_helper.dart     # SQLite 싱글톤 (4개 테이블)
├── features/
│   ├── home/                        # 홈 화면 + Riverpod 프로바이더
│   ├── camera/                      # 카메라 촬영·갤러리 선택·전처리
│   ├── puzzle/
│   │   ├── puzzle_selection_screen.dart   # 4가지 모드 선택
│   │   ├── difficulty_selection_screen.dart
│   │   ├── completion_screen.dart         # 완성 축하 (별점·폭죽)
│   │   ├── jigsaw/                        # 드래그 앤 드롭 직소
│   │   ├── slide/                         # 슬라이딩 타일
│   │   ├── rotate/                        # 탭-회전 타일
│   │   └── spot_difference/               # 틀린그림 찾기
│   ├── collection/                  # 퍼즐 앨범 (완성 기록)
│   └── parental/                    # 보호자 설정 (수학 잠금)
└── shared/
    ├── utils/
    │   ├── image_utils.dart         # 이미지 처리 (Isolate 비동기)
    │   ├── haptic_utils.dart        # HapticFeedback 래퍼
    │   └── star_calculator.dart     # 별점 계산 로직
    └── widgets/
        ├── star_display.dart        # 1~3개 별 표시 (애니메이션)
        ├── level_badge.dart         # 레벨 배지 + 진행도 바
        ├── loading_overlay.dart     # 퍼즐 생성 중 로딩 UI
        ├── puzzle_mode_card.dart    # 모드 선택 카드
        └── confetti_overlay.dart    # 완성 폭죽 파티클
```

---

## 핵심 규칙

### 아키텍처
- **Feature-first**: 모든 코드는 `features/<기능명>/` 아래에 위치한다.
- **Riverpod 상태 관리**: `Provider` / `AsyncNotifier` 사용. `setState`는 순수 로컬 UI 상태에만 허용.
- **오프라인 퍼스트**: 서버 통신 없음. 모든 데이터는 SQLite 로컬 저장.
- **이미지 처리는 반드시 Isolate**: `ImageUtils`의 모든 무거운 연산은 `Isolate.run()`으로 실행해 UI 블로킹 방지.

### Difficulty enum
`puzzle_type.dart`의 `Difficulty` enum이 모드별 파라미터의 단일 진실 소스다.
새 퍼즐 모드를 추가할 때 다른 파일에 하드코딩하지 말고 여기에 getter를 추가한다.

```dart
// 예: 새 모드의 타일 수가 필요하면
int get myModeGrid => switch (this) { ... };
```

### 데이터베이스
- `DatabaseHelper.instance`는 싱글톤. 직접 인스턴스화하지 않는다.
- 퍼즐 기록 저장은 `upsertPuzzleRecord()`를 사용. 더 높은 별점이면 덮어쓰고, 낮으면 무시한다.
- 스키마 변경 시 `_dbVersion`을 올리고 `onUpgrade` 콜백을 추가한다.

### UI / UX
- **터치 타겟 최소 48×48dp** (`AppSizes.minTouchTarget`). 이보다 작은 인터랙티브 위젯은 금지.
- 색상은 `AppColors`에서만 가져온다. 위젯 안에 `Color(0xFF...)` 리터럴 하드코딩 금지.
- 한국어 문자열은 `AppStrings`에서만 가져온다. 위젯에 문자열 리터럴 금지.
- 햅틱은 `HapticUtils` 래퍼를 사용한다 (`pick`, `snap`, `complete`, `error`).

### COPPA / 아동 안전
- **외부 네트워크 호출 추가 금지** (광고 SDK, 분석 도구 포함).
- 사진은 앱 샌드박스(`getApplicationDocumentsDirectory()`)에만 저장.
- 외부 URL 링크 금지.

---

## 퍼즐 모드별 주요 파일

| 모드 | 엔진 | 화면 |
|---|---|---|
| 직소 | `jigsaw/jigsaw_engine.dart` | `jigsaw/jigsaw_screen.dart` |
| 슬라이드 | `slide/slide_engine.dart` | `slide/slide_screen.dart` |
| 회전 | `rotate/rotate_engine.dart` | `rotate/rotate_screen.dart` |
| 틀린그림 | `image_utils.dart` (diff 생성) | `spot_difference/spot_difference_screen.dart` |

새 퍼즐 모드 추가 시 체크리스트:
1. `PuzzleType` enum에 값 추가
2. `Difficulty`에 모드별 파라미터 getter 추가
3. `features/puzzle/<모드>/` 폴더 생성 (엔진 + 화면)
4. `difficulty_selection_screen.dart`의 `switch`에 라우트 추가
5. `PuzzleType`의 `koreanName`, `description`, `dbValue` 업데이트

---

## 별점 계산

`shared/utils/star_calculator.dart`

| 별점 | 조건 |
|---|---|
| ★★★ | 힌트 미사용 + par 시간 이내 |
| ★★ | 힌트 1회 이하 또는 par 시간 이내 |
| ★ | 퍼즐 완성 (항상 최소 1개 보장) |

Par 시간: Easy=120s / Medium=240s / Hard=420s
슬라이드는 이동 횟수 기준: Easy=50 / Medium=120 / Hard=250

---

## 에셋 추가 방법

### 폰트 (NanumRound)
1. `.ttf` 파일을 `assets/fonts/`에 추가
2. `pubspec.yaml`의 `fonts` 섹션에 등록

### 이미지 / 사운드
- `assets/images/` 또는 `assets/sounds/`에 추가
- `pubspec.yaml`에 이미 와일드카드(`assets/images/`)로 등록돼 있으므로 별도 등록 불필요

### 사운드 재생
`audioplayers` 패키지 사용. 현재 구현에 통합 예정 (Phase 2).

---

## 개발 로드맵 현황

| 단계 | 내용 | 상태 |
|---|---|---|
| Phase 1 MVP | 카메라, 직소 퍼즐, 기본 UI | ✅ 완료 |
| Phase 2 | 슬라이드·회전·별점·컬렉션·사운드·햅틱 | ✅ 완료 |
| Phase 3 | 틀린그림 찾기·보호자 기능·COPPA 검토 | ✅ 완료 |
| Phase 4 | QA·성능 최적화·스토어 출시 준비 | 🔲 진행 예정 |

---

## 테스트

```bash
flutter test                        # 전체 테스트 실행
flutter test test/puzzle_logic_test.dart   # 퍼즐 로직 단위 테스트만
```

`test/puzzle_logic_test.dart`에 포함된 테스트:
- `Difficulty` 파라미터 검증 (조각 수, 그리드, 시간 제한 등)
- `SlideEngine` — 셔플·이동·해결 판정
- `RotateEngine` — 회전 사이클·해결 판정
- `StarCalculator` — 별점 계산 케이스
