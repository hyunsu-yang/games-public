# SnapPuzzle 실행 가이드 (Windows 기준)

> Java 백엔드 개발자를 위한 Flutter 앱 실행 안내서.
> Windows PC에서 Android 앱을 빌드하고 갤럭시 패드/폰에 설치합니다.
> iOS 빌드는 Mac에서만 가능하므로 이 가이드에서는 다루지 않습니다.

---

## 목차

1. [개념 잡기 — Spring Boot와 비교](#1-개념-잡기--spring-boot와-비교)
2. [환경 설치 (1회만)](#2-환경-설치-1회만)
3. [프로젝트 셋업](#3-프로젝트-셋업)
4. [갤럭시 패드/폰에서 실행](#4-갤럭시-패드폰에서-실행)
5. [에뮬레이터로 실행 (기기 없을 때)](#5-에뮬레이터로-실행-기기-없을-때)
6. [APK 빌드 및 배포](#6-apk-빌드-및-배포)
7. [개발할 때 알면 좋은 것들](#7-개발할-때-알면-좋은-것들)
8. [자주 겪는 문제와 해결법](#8-자주-겪는-문제와-해결법)

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

## 2. 환경 설치 (1회만)

2가지만 설치하면 됩니다.

### 2-1. Flutter SDK

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

### 2-2. Android Studio

1. https://developer.android.com/studio 에서 다운로드 → 설치
2. 최초 실행 → **Next** 계속 클릭 (Android SDK 자동 다운로드)
3. 터미널에서:

```bash
# Android SDK 라이선스 동의 (y를 여러 번 입력)
flutter doctor --android-licenses
```

### 2-3. 설치 확인

```bash
flutter doctor
```

아래 두 항목이 체크되면 준비 완료:

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
```

> `[✗] Xcode` 는 무시해도 됩니다 — Mac 전용이며 Android 빌드에 영향 없습니다.

---

## 3. 프로젝트 셋업

```bash
cd C:\workspace-play\seoaPuzzleGame

# 1. Android 플랫폼 빌드 파일 생성 (lib/ 소스코드는 건드리지 않음)
flutter create --platforms=android .

# 2. 의존성 설치 (= gradle dependencies)
flutter pub get

# 3. 코드 생성 (= Lombok annotation processor)
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. 갤럭시 패드/폰에서 실행

### 4-1. 기기 준비 (1회)

갤럭시 패드 또는 폰에서:

1. **개발자 옵션 활성화**
   - 설정 → 휴대전화(태블릿) 정보 → 소프트웨어 정보
   - **빌드 번호 7번 연속 탭**
   - "개발자 모드가 활성화되었습니다" 확인

2. **USB 디버깅 켜기**
   - 설정 → 개발자 옵션 → **USB 디버깅** ON

### 4-2. USB 연결

1. USB-C 케이블로 기기를 PC에 연결
   - **데이터 전송 가능한 케이블** 사용 (충전 전용은 안 됨)
2. 기기에 "USB 디버깅 허용?" 팝업 → **허용** (항상 허용 체크 권장)
3. 기기 화면에서 USB 모드가 "파일 전송" 또는 "데이터 전송"인지 확인

### 4-3. 실행

```bash
# 기기 인식 확인
flutter devices
```

출력 예시:
```
SM T970 (mobile) • XXXXXXXXXX • android-arm64 • Android 13 (API 33)
```

```bash
# 앱 실행 (자동 빌드 + 설치 + 실행)
flutter run
```

갤럭시 패드 화면에 SnapPuzzle 앱이 뜹니다.

---

## 5. 에뮬레이터로 실행 (기기 없을 때)

에뮬레이터 = PC 화면에서 돌아가는 가상 안드로이드 기기입니다.

### 5-1. 에뮬레이터 생성

1. Android Studio 실행
2. **Tools → Device Manager**
3. **Create Virtual Device**
4. 기기 선택:
   - 폰: `Pixel 7`
   - 태블릿: `Pixel Tablet` 또는 `Nexus 10`
5. 시스템 이미지: **API 34 (Android 14)** 권장 → Download 클릭
6. **Finish**

### 5-2. 에뮬레이터 실행

Device Manager에서 ▶ 버튼 클릭, 또는:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

### 5-3. 앱 실행

```bash
flutter run
```

> 에뮬레이터가 느리면: Android Studio → Device Manager → 에뮬레이터 설정 → Graphics: **Hardware - GLES 2.0** 선택.
> BIOS에서 **Intel VT-x** 또는 **AMD-V** 가상화가 켜져 있는지도 확인.

---

## 6. APK 빌드 및 배포

APK를 빌드해서 GitHub Release에 올리면, 누구나 폰에서 다운받아 설치할 수 있습니다.

### 6-1. 자동 배포 (GitHub Actions — 권장)

이 프로젝트에 `.github/workflows/build-apk.yml`이 설정되어 있습니다.
Git 태그를 푸시하면 자동으로 APK가 빌드되어 GitHub Release에 업로드됩니다.

```bash
# 1. 변경사항 커밋
git add -A && git commit -m "feat: my changes"

# 2. 버전 태그 생성 + 푸시
git tag v1.0.0
git push origin main --tags

# 3. GitHub Actions가 자동으로:
#    테스트 → APK 빌드 → Release 생성 → APK 첨부
```

빌드 완료 후:
- GitHub 저장소 → **Releases** 페이지에 APK 파일이 올라가 있음
- 갤럭시 패드/폰에서 Release 페이지 접속 → APK 다운로드 → 설치

### 6-2. 수동 빌드 (로컬)

```bash
# 릴리즈 APK 빌드
flutter build apk --release

# 결과 파일 위치
# build/app/outputs/flutter-apk/app-release.apk
```

이 파일을 GitHub Release에 직접 업로드하거나, 카카오톡/이메일로 전송해도 됩니다.

### 6-3. 갤럭시 패드/폰에서 APK 설치

1. 폰/패드 브라우저로 GitHub Release 페이지 접속
2. `.apk` 파일 다운로드
3. "출처를 알 수 없는 앱" 허용 팝업 → **허용**
4. 다운로드한 파일 열기 → **설치**
5. SnapPuzzle 앱 아이콘이 홈 화면에 생김

---

## 7. 개발할 때 알면 좋은 것들

### 7-1. 핫 리로드

`flutter run`으로 앱이 실행된 상태에서:

| 키 | 동작 | Spring Boot 비유 |
|---|---|---|
| `r` | 핫 리로드 (코드 변경 즉시 반영, 앱 상태 유지) | DevTools보다 **훨씬 빠름** |
| `R` | 핫 리스타트 (앱 상태 초기화 후 재시작) | 서버 재시작 |
| `q` | 앱 종료 | Ctrl+C |

### 7-2. 무선 디버깅 (케이블 없이)

USB로 첫 연결을 한 뒤, 이후에는 무선으로도 가능합니다.

```bash
# 기기: 설정 → 개발자 옵션 → 무선 디버깅 ON
# 기기에서 페어링 코드 확인 후:
adb pair <ip>:<port>      # 최초 1회
adb connect <ip>:<port>   # 연결
flutter run
```

### 7-3. VS Code에서 개발 (선택)

Android Studio 대신 VS Code를 코드 에디터로 쓸 수 있습니다.

1. VS Code → Extensions → **Flutter** 검색 → 설치
2. `F5` 키로 앱 실행 (Run and Debug)
3. 코드 저장 시 자동 핫 리로드

---

## 8. 자주 겪는 문제와 해결법

### "flutter: command not found"

```bash
# 환경변수 확인 — 터미널을 새로 열어야 적용됨
flutter --version

# 안 되면 직접 경로로 실행해서 확인
C:\flutter\bin\flutter --version
```

### "No devices found"

```bash
# 에뮬레이터가 안 떠 있거나 USB 기기가 안 잡힌 경우
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
[환경 설치 — 1회]
  Flutter SDK (C:\flutter) + Android Studio
      ↓
[프로젝트 셋업 — 1회]
  flutter create . → flutter pub get → build_runner build
      ↓
[실행 — 두 가지 방법]
  방법 1: USB 연결 → flutter run → 기기에서 바로 실행
  방법 2: flutter build apk → APK 파일 배포 → 설치

[자동 배포]
  git tag v1.0.0 → git push --tags → GitHub Actions가 APK 빌드 → Release에 업로드
```
