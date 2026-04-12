# 🧩 SnapPuzzle

> **찰칵! 찍은 사진이 퍼즐이 되는 마법**

아이가 직접 카메라로 찍은 사진이 4가지 퍼즐로 변환되는 모바일 게임.  
자신만의 사진으로 만든 퍼즐이기에 몰입도와 성취감이 극대화됩니다.

| | |
|---|---|
| **대상 연령** | 6 ~ 8세 (초등 저학년) |
| **플랫폼** | iPad (iPadOS 16+) · Android (API 26+, Tablet/Phone) |
| **개발** | Flutter 3.x · Dart · Flame Engine |
| **버전** | 1.0.0 |

---

## 📱 스크린샷 / 화면 흐름

```
홈 화면  →  사진 찍기 / 갤러리 선택  →  퍼즐 유형 선택  →  난이도 선택  →  플레이  →  완성 축하
```

---

## 🎮 게임 모드

### 1. 직소 퍼즐 (Jigsaw)
드래그 앤 드롭으로 조각을 맞추는 클래식 퍼즐.

| 난이도 | 조각 수 | 힌트 | 회전 |
|---|---|---|---|
| 쉽게 ★ | 6조각 (2×3) | 반투명 가이드라인 | 없음 |
| 보통 ★★ | 12조각 (3×4) | 외곽선만 | 없음 |
| 어려워 ★★★ | 20조각 (4×5) | 없음 | 90° 회전 포함 |

- 근접 시 자석 스냅(Magnet Snap) 효과
- 배경 희미한 원본 사진으로 참고 가능

### 2. 슬라이드 퍼즐 (Slide)
빈칸을 이용해 타일을 밀어 원본 사진을 복원.

| 난이도 | 격자 | 번호 표시 |
|---|---|---|
| 쉽게 ★ | 3×3 (8타일) | 있음 |
| 보통 ★★ | 4×4 (15타일) | 없음 |
| 어려워 ★★★ | 5×5 (24타일) | 없음 |

- Unsolvable 배치 방지 알고리즘 (inversion count 검증)
- 이동 횟수 카운터 → 최소 이동 도전 요소

### 3. 회전 퍼즐 (Rotate)
랜덤 회전된 타일을 탭하여 올바른 방향으로 돌려놓기.

| 난이도 | 타일 수 | 회전 단위 |
|---|---|---|
| 쉽게 ★ | 4타일 (2×2) | 180° |
| 보통 ★★ | 9타일 (3×3) | 90° |
| 어려워 ★★★ | 16타일 (4×4) | 90° |

- 올바른 방향 타일은 초록 테두리 하이라이트
- 90° 회전 애니메이션

### 4. 틀린그림 찾기 (Spot the Difference)
원본과 자동 변형된 사진을 나란히 비교, 다른 부분 탭.

| 난이도 | 차이 개수 | 시간 제한 |
|---|---|---|
| 쉽게 ★ | 3개 | 없음 |
| 보통 ★★ | 5개 | 90초 |
| 어려워 ★★★ | 7개 | 60초 |

- 픽셀 레벨 자동 변형 엔진 (색상 반전)
- 틀린 부분 탭 시 원형 리플 애니메이션

---

## ⭐ 보상 시스템

### 별점 (1 ~ 3개)

| 별점 | 조건 |
|---|---|
| ★★★ | 힌트 미사용 + par 시간 이내 완성 |
| ★★ | 힌트 1회 이하 또는 par 시간 이내 |
| ★ | 퍼즐 완성 (항상 최소 1개 보장) |

### 레벨 시스템

| 레벨 | 이름 | 필요 별 |
|---|---|---|
| 1 | 퍼즐 초보자 | 0 |
| 2 | 퍼즐 친구 | 10 |
| 3 | 퍼즐 고수 | 30 |
| 4 | 퍼즐 달인 | 60 |
| 5 | 퍼즐 마스터 | 100 |

### 컬렉션 앨범
- 완성 퍼즐은 "나의 퍼즐 앨범"에 사진 카드로 저장
- 모드별 배지 표시 · 4가지 모두 완성 시 골드 프레임 해금

---

## 🔒 보호자 기능

설정 진입 시 수학 문제(3×4=?)로 잠금 해제.

- 플레이 시간 제한: 30분 / 1시간 / 무제한
- 카메라 접근 ON/OFF (갤러리만 허용 모드)
- 갤러리 저장 정책 선택
- 고대비 접근성 모드
- 오늘 플레이 통계 확인

---

## ⚙️ 기술 스택

| 영역 | 선택 |
|---|---|
| 프레임워크 | Flutter 3.x (Dart) |
| 게임 엔진 | Flame Engine |
| 상태 관리 | Riverpod 2.x (AsyncNotifier) |
| 카메라 | camera · image_picker |
| 이미지 처리 | image 패키지 (Dart Isolate 비동기) |
| 로컬 저장 | sqflite (SQLite) · path_provider |
| 사운드 | audioplayers |
| 햅틱 | HapticFeedback API |
| IAP | in_app_purchase |

---

## 🚀 시작하기

### 요구 사항
- Flutter SDK 3.10 이상
- Dart SDK 3.0 이상
- iOS: Xcode 15+ (Mac 필요)
- Android: Android Studio / SDK API 26+

### 설치

```bash
# 저장소 클론
git clone https://github.com/hyunsu-yang/games-public.git
cd games-public

# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod annotation)
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

### 폰트 추가
`assets/fonts/`에 NanumRound 폰트 파일을 넣어야 합니다.

```
assets/fonts/
├── NanumRoundR.ttf     # Regular
├── NanumRoundB.ttf     # Bold (700)
└── NanumRoundEB.ttf    # ExtraBold (800)
```

> 나눔 폰트는 [네이버 나눔글꼴](https://hangeul.naver.com/font) 페이지에서 무료로 다운로드할 수 있습니다.

### 테스트

```bash
# 단위 테스트 실행
flutter test

# 정적 분석
flutter analyze
```

---

## 📁 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/        # 색상, 크기, 문자열, 테마
│   ├── models/           # Photo, PuzzleType/Difficulty, PuzzleRecord, UserProfile, Settings
│   └── database/         # SQLite DatabaseHelper (싱글톤)
├── features/
│   ├── home/             # 홈 화면
│   ├── camera/           # 카메라·갤러리·이미지 전처리
│   ├── puzzle/
│   │   ├── jigsaw/       # 직소 엔진 + 화면
│   │   ├── slide/        # 슬라이드 엔진 + 화면
│   │   ├── rotate/       # 회전 엔진 + 화면
│   │   └── spot_difference/  # 틀린그림 화면
│   ├── collection/       # 퍼즐 앨범
│   └── parental/         # 보호자 설정
└── shared/
    ├── utils/            # 이미지·햅틱·별점 유틸
    └── widgets/          # 공통 위젯 (별, 레벨, 로딩, 폭죽)
```

---

## 🗄️ 데이터베이스 스키마

```sql
-- 촬영·선택한 사진
photos (id, file_path, thumbnail_path, created_at, width_px, height_px)

-- 퍼즐 완성 기록 (best_stars 기준 upsert)
puzzles (id, photo_id, type, difficulty, completed_at, best_stars,
         best_time_seconds, total_moves, hints_used)

-- 사용자 진행 현황 (단일 행)
user_profile (total_stars, total_puzzles_completed,
              play_time_today_seconds, last_play_date)

-- 보호자 설정 (단일 행)
settings (daily_limit_minutes, camera_enabled, save_to_gallery,
          pin, high_contrast_mode)
```

---

## ♿ 접근성 및 안전

- 모든 터치 타겟 **최소 48×48dp**
- 고대비 모드: 퍼즐 외곽선 두껍게 표시
- 시스템 폰트 크기 설정 존중
- **COPPA 준수**: 개인정보 수집 없음, 외부 접속 없음, 광고 없음
- 사진 로컬 저장 전용, 외부 전송 기능 없음

---

## 📅 개발 로드맵

| 단계 | 내용 | 상태 |
|---|---|---|
| Phase 1 | 카메라, 직소 퍼즐, 기본 UI, iPad + Android 빌드 | ✅ 완료 |
| Phase 2 | 슬라이드·회전 퍼즐, 별점·컬렉션, 사운드·햅틱, 완성 애니메이션 | ✅ 완료 |
| Phase 3 | 틀린그림 찾기, 보호자 기능, COPPA 검토 | ✅ 완료 |
| Phase 4 | QA, 성능 최적화, 스토어 출시 준비 | 🔲 진행 예정 |

---

## 📊 목표 KPI

| 지표 | 목표 |
|---|---|
| DAU | 주 3회 이상 앱 실행 |
| 퍼즐 완성률 | 시작 대비 80% 이상 |
| 세션당 평균 퍼즐 | 3개 이상 |
| 7일 리텐션 | 40% 이상 |
| 평균 별점 | 2.2개 이상 |

---

## 📄 라이선스

이 프로젝트는 개인 개발 프로젝트입니다. 무단 배포 및 상업적 사용을 금지합니다.
