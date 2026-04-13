# SnapPuzzle 실행 가이드 (Windows 기준)

> Java 백엔드 개발자를 위한 Flutter 앱 실행 안내서.
> Windows PC에서 Android 앱을 빌드하고 갤럭시 패드/폰에 설치합니다.
> iOS 빌드는 Mac에서만 가능하므로 이 가이드에서는 다루지 않습니다.

---

## 목차

1. [개념 잡기 — Spring Boot와 비교](#1-개념-잡기--spring-boot와-비교)
2. [개발 방식 선택](#2-개발-방식-선택)
3. [방식 A: GitHub Actions로 빌드 (간편)](#3-방식-a-github-actions로-빌드-간편)
4. [방식 B: 로컬에서 직접 실행 (핫 리로드)](#4-방식-b-로컬에서-직접-실행-핫-리로드)
5. [갤럭시 패드/폰에서 APK 설치](#5-갤럭시-패드폰에서-apk-설치)
6. [개발할 때 알면 좋은 것들](#6-개발할-때-알면-좋은-것들)
7. [자주 겪는 문제와 해결법](#7-자주-겪는-문제와-해결법)

---

## 1. 개념 잡기 — Spring Boot와 비교

| 개념 | Spring Boot | Flutter (이 프로젝트) |
|------|-------------|----------------------|
| 소스 코드 | `src/main/java/` | `lib/` |
| 빌드 도구 | Gradle | Flutter CLI |
| 의존성 관리 | `build.gradle` | `pubspec.yaml` |
| 의존성 설치 | `./gradlew dependencies` | `flutter pub get` |
| 코드 생성 | Lombok annotation processor | `dart run build_runner build` |
| 실행 | `./gradlew bootRun` | `flutter run` |
| 실행 대상 | 내장 Tomcat (localhost) | **실제 기기 또는 에뮬레이터** |
| 핫 리로드 | DevTools (수 초) | **`r` 키 → 1초 미만** |
| 빌드 결과물 | `.jar` | `.apk` |

**핵심**: `lib/` 안의 Dart 소스코드를 Flutter SDK가 Android APK로 빌드합니다.

---

## 2. 개발 방식 선택

두 가지 방식이 있습니다. **필요에 따라 선택**하세요.

| | 방식 A: GitHub Actions | 방식 B: 로컬 실행 |
|---|---|---|
| **설치할 것** | Flutter SDK만 | Flutter SDK + Android Studio |
| **빌드 장소** | GitHub 서버 | 내 PC |
| **기기 연결** | 필요 없음 (APK 다운로드) | USB로 연결 |
| **핫 리로드** | 불가 (코드 수정마다 push 필요) | **가능 (1초 만에 반영)** |
| **적합한 상황** | 간단한 수정, 배포, 남에게 공유 | UI 개발, 디버깅, 빠른 반복 |

> **추천**: 처음엔 **방식 A**로 시작하고, 개발이 본격화되면 **방식 B**를 추가 셋업

---

## 3. 방식 A: GitHub Actions로 빌드 (간편)

**Android Studio 설치 불필요.** Flutter SDK만 있으면 됩니다.
APK 빌드는 GitHub 서버가 대신 해주고, 결과물을 패드/폰에서 다운받아 설치합니다.

```
코드 수정 → push + tag → GitHub Actions가 APK 빌드 → Release에 업로드 → 패드에서 다운로드
```

### 3-1. Flutter SDK 설치

```bash
# Git으로 Flutter SDK 클론
cd C:\ && git clone https://github.com/flutter/flutter.git -b stable
```

환경변수에 `C:\flutter\bin` 추가:

1. `Win + R` → `sysdm.cpl` → **고급** 탭 → **환경 변수**
2. 사용자 변수 → **Path** → **편집** → **새로 만들기** → `C:\flutter\bin` 입력 → **확인**
3. 터미널을 **새로 열어서** 확인:

```bash
flutter --version
```

### 3-2. 프로젝트 셋업

```bash
cd C:\workspace-play\seoaPuzzleGame

# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 테스트 (로컬에서 확인)
flutter test

# 정적 분석
flutter analyze
```

> `flutter pub get`, `flutter test`, `flutter analyze`는 Android SDK 없이 동작합니다.

### 3-3. APK 자동 빌드 + 배포

이 프로젝트에 `.github/workflows/build-apk.yml`이 설정되어 있습니다.
Git 태그를 푸시하면 GitHub Actions가 자동으로 APK를 빌드하고 Release에 올립니다.

```bash
# 1. 변경사항 커밋
git add -A && git commit -m "feat: my changes"

# 2. 버전 태그 생성 + 푸시
git tag v1.0.0
git push origin main --tags

# 3. GitHub Actions가 자동으로:
#    테스트 → APK 빌드 → Release 생성 → APK 첨부
```

빌드 완료 후 GitHub 저장소 → **Releases** 페이지에 APK 파일이 올라갑니다.

> GitHub 웹에서 **Actions → Build & Release APK → Run workflow** 버튼으로 수동 실행도 가능합니다.

---

## 4. 방식 B: 로컬에서 직접 실행 (핫 리로드)

USB로 기기를 연결하고 `flutter run`으로 실행하면, 코드 수정이 **1초 안에** 기기에 반영됩니다.
이 방식은 **Android Studio(Android SDK)**가 추가로 필요합니다.

### 4-1. Android Studio 설치

1. https://developer.android.com/studio 에서 다운로드 → 설치
2. 최초 실행 → **Next** 계속 클릭 (Android SDK 자동 다운로드)
3. 터미널에서:

```bash
# Android SDK 라이선스 동의 (y를 여러 번 입력)
flutter doctor --android-licenses
```

4. 설치 확인:

```bash
flutter doctor
```

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
```

> `[✗] Xcode`는 무시 — Mac 전용이며 Android에 영향 없음

### 4-2. 프로젝트 셋업

```bash
cd C:\workspace-play\seoaPuzzleGame

# Android 플랫폼 빌드 파일 생성 (lib/ 소스코드는 건드리지 않음)
flutter create --platforms=android .

# 의존성 설치
flutter pub get

# 코드 생성
dart run build_runner build --delete-conflicting-outputs
```

### 4-3. 갤럭시 패드/폰 준비 (기기에서 1회)

1. **개발자 옵션 활성화**
   - 설정 → 휴대전화(태블릿) 정보 → 소프트웨어 정보
   - **빌드 번호 7번 연속 탭**
   - "개발자 모드가 활성화되었습니다" 확인

2. **USB 디버깅 켜기**
   - 설정 → 개발자 옵션 → **USB 디버깅** ON

### 4-4. USB 연결 후 실행

1. USB-C 케이블로 기기를 PC에 연결
   - **데이터 전송 가능한 케이블** 사용 (충전 전용은 안 됨)
2. 기기에 "USB 디버깅 허용?" 팝업 → **허용** (항상 허용 체크 권장)

```bash
# 기기 인식 확인
flutter devices

# 앱 실행 (자동 빌드 + 설치 + 실행)
flutter run
```

갤럭시 패드 화면에 SnapPuzzle 앱이 뜹니다.

### 4-5. 에뮬레이터로 실행 (기기 없을 때)

1. Android Studio → **Tools → Device Manager**
2. **Create Virtual Device**
3. 기기 선택: 폰 `Pixel 7` / 태블릿 `Pixel Tablet`
4. 시스템 이미지: **API 34** 권장 → Download → **Finish**
5. ▶ 버튼으로 에뮬레이터 실행

```bash
flutter run
```

### 4-6. 로컬 APK 빌드

```bash
# 릴리즈 APK 빌드
flutter build apk --release

# 결과 파일
# build/app/outputs/flutter-apk/app-release.apk
```

이 파일을 카카오톡/이메일로 전송하거나 GitHub Release에 직접 업로드할 수 있습니다.

---

## 5. 갤럭시 패드/폰에서 APK 설치

GitHub Release 또는 로컬 빌드로 만든 APK 파일을 설치하는 방법입니다.

1. 폰/패드 브라우저로 GitHub Release 페이지 접속
2. `SnapPuzzle-v1.0.0.apk` 파일 다운로드
3. "출처를 알 수 없는 앱" 허용 팝업 → **허용**
4. 다운로드한 파일 열기 → **설치**
5. 홈 화면에 SnapPuzzle 앱 아이콘 생성

---

## 6. 개발할 때 알면 좋은 것들

### 6-1. 핫 리로드 (방식 B에서만 가능)

`flutter run`으로 앱이 실행된 상태에서:

| 키 | 동작 | Spring Boot 비유 |
|---|---|---|
| `r` | 핫 리로드 (코드 변경 즉시 반영, 앱 상태 유지) | DevTools보다 **훨씬 빠름** |
| `R` | 핫 리스타트 (앱 상태 초기화 후 재시작) | 서버 재시작 |
| `q` | 앱 종료 | Ctrl+C |

### 6-2. 무선 디버깅 (방식 B, 케이블 없이)

USB로 첫 연결을 한 뒤, 이후에는 무선으로도 가능합니다.

```bash
# 기기: 설정 → 개발자 옵션 → 무선 디버깅 ON
# 기기에서 페어링 코드 확인 후:
adb pair <ip>:<port>      # 최초 1회
adb connect <ip>:<port>   # 연결
flutter run
```

### 6-3. VS Code에서 개발 (선택)

Android Studio 대신 VS Code를 코드 에디터로 쓸 수 있습니다.

1. VS Code → Extensions → **Flutter** 검색 → 설치
2. `F5` 키로 앱 실행 (Run and Debug)
3. 코드 저장 시 자동 핫 리로드

---

## 7. 자주 겪는 문제와 해결법

### "flutter: command not found"

```bash
# 환경변수 확인 — 터미널을 새로 열어야 적용됨
flutter --version

# 안 되면 직접 경로로 실행해서 확인
C:\flutter\bin\flutter --version
```

### "No devices found" (방식 B)

```bash
# USB 기기가 안 잡히는 경우
adb devices          # 목록이 비어 있으면 케이블/USB 디버깅 확인
flutter devices      # flutter가 인식하는 기기 목록
```

### "Gradle build failed"

```bash
# 빌드 캐시 정리 후 재시도 (= gradle clean)
flutter clean
flutter pub get
flutter run
```

### "flutter pub get" 실패

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### 빌드 성공인데 하얀 화면만 나올 때

```bash
# Riverpod 코드 생성 누락
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 앱이 느릴 때

debug 모드는 디버깅 정보가 포함되어 느립니다. 실제 성능 확인:

```bash
flutter run --release     # 릴리즈 모드 (디버깅 불가, 빠름)
flutter run --profile     # 프로파일 모드 (성능 측정용)
```

---

## 한눈에 보는 요약

```
방식 A: GitHub Actions (Android Studio 불필요)
──────────────────────────────────────────────
  [설치] Flutter SDK만
      ↓
  [개발] 코드 수정 → flutter test → git push + tag
      ↓
  [빌드] GitHub Actions가 자동 APK 빌드
      ↓
  [설치] 패드/폰에서 Release 페이지 → APK 다운로드 → 설치


방식 B: 로컬 실행 + 핫 리로드 (Android Studio 필요)
──────────────────────────────────────────────
  [설치] Flutter SDK + Android Studio
      ↓
  [개발] USB 연결 → flutter run → r 키로 핫 리로드
      ↓
  [배포] flutter build apk 또는 GitHub Actions
```
