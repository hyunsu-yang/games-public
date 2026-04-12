# SnapPuzzle 실행 가이드 (Mac 기준)

> Java 백엔드 개발자를 위한 Flutter 앱 실행 안내서.
> Mac 한 대에서 갤럭시 패드(Android) + 아이패드(iOS) 모두 빌드·설치합니다.
> Spring Boot에서 `./gradlew bootRun` 하듯, Flutter에서는 `flutter run` 하나면 앱이 뜹니다.

---

## 목차

1. [개념 잡기 — Spring Boot와 비교](#1-개념-잡기--spring-boot와-비교)
2. [환경 설치 (1회만)](#2-환경-설치-1회만)
3. [프로젝트 셋업](#3-프로젝트-셋업)
4. [갤럭시 패드에서 실행](#4-갤럭시-패드에서-실행)
5. [아이패드에서 실행](#5-아이패드에서-실행)
6. [에뮬레이터 / 시뮬레이터로 실행](#6-에뮬레이터--시뮬레이터로-실행)
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

**핵심**: Flutter SDK가 `lib/`의 Dart 소스코드 **1벌**을 Android APK와 iOS IPA **두 앱**으로 빌드합니다.

```
              lib/ (Dart 소스코드)
                      │
                Flutter SDK
               ┌──────┴──────┐
               ▼              ▼
          Android APK      iOS IPA
         (갤럭시 패드)     (아이패드)
```

---

## 2. 환경 설치 (1회만)

총 4개를 설치합니다. 순서대로 진행하세요.

### 2-1. Xcode (iOS 빌드용)

가장 오래 걸리므로 **먼저 시작**합니다.

1. **App Store** → "Xcode" 검색 → **설치** (약 12GB, 20~40분 소요)
2. 설치 완료 후 터미널에서:

```bash
# command-line tools 설치
sudo xcode-select --install

# 라이선스 동의
sudo xcodebuild -license accept
```

### 2-2. Flutter SDK

```bash
# 홈 디렉토리에 Flutter SDK 클론
cd ~ && git clone https://github.com/flutter/flutter.git -b stable

# 환경변수 등록 (zsh 기준 — Mac 기본 쉘)
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 설치 확인
flutter --version
```

> bash를 쓰는 경우 `~/.zshrc` 대신 `~/.bash_profile`에 추가

### 2-3. Android Studio (Android SDK + 에뮬레이터용)

1. https://developer.android.com/studio 에서 Mac용 다운로드
2. DMG 열고 Applications 폴더로 드래그
3. 최초 실행 → **Next** 계속 클릭 (Android SDK 자동 다운로드)
4. 터미널에서:

```bash
# Android SDK 라이선스 동의
flutter doctor --android-licenses
# y를 여러 번 입력
```

### 2-4. CocoaPods (iOS 의존성 관리)

```bash
# Java의 Maven/Gradle 같은 역할 (iOS 네이티브 라이브러리 관리)
sudo gem install cocoapods
```

### 2-5. 설치 확인

```bash
flutter doctor
```

아래처럼 **전부 체크**되면 준비 완료:

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Android Studio
```

---

## 3. 프로젝트 셋업

프로젝트를 Mac에 가져온 후 1회 실행합니다.

```bash
# 프로젝트 디렉토리로 이동
cd /path/to/seoaPuzzleGame

# 1. 플랫폼 빌드 파일 생성 (android/, ios/ 구조 완성)
#    lib/ 소스코드는 건드리지 않음
flutter create --platforms=android,ios .

# 2. 의존성 설치 (= gradle dependencies)
flutter pub get

# 3. 코드 생성 (= Lombok annotation processor)
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. 갤럭시 패드에서 실행

### 4-1. 갤럭시 패드 준비 (기기에서 1회)

1. **개발자 옵션 활성화**
   - 설정 → 태블릿 정보 → 소프트웨어 정보 → **빌드 번호 7번 연속 탭**
   - "개발자 모드가 활성화되었습니다" 메시지 확인

2. **USB 디버깅 켜기**
   - 설정 → 개발자 옵션 → **USB 디버깅** ON

### 4-2. Mac에 연결

1. USB-C 케이블로 갤럭시 패드를 Mac에 연결
   - **데이터 전송 가능한 케이블** 사용 (충전 전용 케이블은 안 됨)
2. 갤럭시 패드에 "USB 디버깅 허용?" 팝업 → **허용** (항상 허용 체크 권장)

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
# 갤럭시 패드에서 앱 실행 (자동 설치 + 실행)
flutter run
```

패드 화면에 SnapPuzzle 앱이 뜹니다. 끝입니다.

> 기기가 여러 대 연결된 경우: `flutter run -d <device_id>`

---

## 5. 아이패드에서 실행

iOS는 **코드 서명(Code Signing)** 이라는 추가 단계가 있습니다.
Apple이 "이 앱은 누가 만들었는지" 인증하는 절차인데, 개발 테스트용은 무료 Apple ID로 됩니다.

### 5-1. Xcode에서 서명 설정 (1회)

```bash
# Xcode에서 iOS 프로젝트 열기
open ios/Runner.xcworkspace
```

Xcode가 열리면:

1. 좌측 파일 목록에서 **Runner** (파란 아이콘) 클릭
2. 가운데 영역 상단 **Signing & Capabilities** 탭 클릭
3. **Team** 드롭다운 → **Add an Account...** → Apple ID 로그인
4. 로그인 후 본인 계정(Personal Team) 선택
5. **Bundle Identifier** 를 고유 값으로 변경:
   - 예: `com.seoa.snappuzzle` (다른 사람과 겹치지 않는 값)

> 이 과정은 Spring Boot 프로젝트를 서버에 배포할 때 SSH 키 등록하는 것과 비슷합니다.
> "이 개발자가 이 앱을 만들었다"는 인증서를 Xcode가 자동 생성합니다.

### 5-2. iPad 연결

1. USB-C 케이블로 아이패드를 Mac에 연결
2. 아이패드에 "이 컴퓨터를 신뢰하겠습니까?" → **신뢰** 선택

### 5-3. 실행

```bash
# 기기 확인
flutter devices
```

출력 예시:
```
iPad (mobile) • 00008030-XXXXXXXXXXXX • ios • iPadOS 17.x
```

```bash
# 아이패드에서 앱 실행
flutter run
```

### 5-4. 첫 실행 시 "신뢰하지 않는 개발자" 해결

첫 실행 시 아이패드에서 앱이 열리지 않고 경고가 나옵니다.
아이패드에서:

1. **설정** → **일반** → **VPN 및 기기 관리**
2. "개발자 앱" 섹션에서 본인 Apple ID 선택
3. **신뢰** 선택
4. 다시 `flutter run` 실행

> 이후에는 이 단계가 필요 없습니다.

---

## 6. 에뮬레이터 / 시뮬레이터로 실행

실제 기기 없이 Mac 화면에서 가상 기기로 테스트할 수도 있습니다.

### 6-1. iOS 시뮬레이터 (Xcode 내장)

```bash
# 시뮬레이터 앱 열기
open -a Simulator

# 기기 변경: 시뮬레이터 메뉴 → File → Open Simulator
# 추천: iPad (10th generation) 또는 iPad Air

# 시뮬레이터가 부팅된 상태에서
flutter run
```

### 6-2. Android 에뮬레이터 (Android Studio)

1. Android Studio → **Tools → Device Manager**
2. **Create Virtual Device** 클릭
3. 카테고리 **Tablet** → `Pixel Tablet` 선택 → **Next**
4. 시스템 이미지 **API 34** 선택 (Download 필요하면 클릭) → **Next** → **Finish**
5. ▶ 버튼으로 에뮬레이터 실행

```bash
# 에뮬레이터가 부팅된 상태에서
flutter run
```

---

## 7. 개발할 때 알면 좋은 것들

### 7-1. 핫 리로드 — 가장 큰 장점

`flutter run`으로 앱이 실행된 상태에서:

| 키 | 동작 | Spring Boot 비유 |
|---|---|---|
| `r` | 핫 리로드 (코드 변경 즉시 반영, 상태 유지) | DevTools 재시작보다 **훨씬 빠름** |
| `R` | 핫 리스타트 (앱 상태 초기화 후 재시작) | 서버 재시작 |
| `q` | 앱 종료 | Ctrl+C |

코드를 수정하고 `r`만 누르면 **1초 안에** 기기 화면이 업데이트됩니다.

### 7-2. 두 기기 동시 테스트

```bash
# 갤럭시 패드와 아이패드가 모두 연결된 상태에서
flutter devices   # 두 기기 모두 보임

# 각각 별도 터미널에서 실행
flutter run -d <galaxy_pad_id>    # 터미널 1
flutter run -d <ipad_id>          # 터미널 2
```

### 7-3. 무선 디버깅 (케이블 없이)

USB로 첫 연결을 한 뒤, 이후에는 무선으로도 가능합니다.

**갤럭시 패드:**
```bash
# 패드: 설정 → 개발자 옵션 → 무선 디버깅 ON
# 패드에서 페어링 코드 확인 후:
adb pair <ip>:<port>      # 최초 1회
adb connect <ip>:<port>   # 연결
flutter run
```

**아이패드:**
1. USB로 연결된 상태에서 Xcode → **Window → Devices and Simulators**
2. 아이패드 선택 → **Connect via network** 체크
3. 이후 같은 Wi-Fi에서 케이블 없이 `flutter run`

### 7-4. 릴리즈 빌드 (배포용)

```bash
# Android APK (갤럭시 패드에 직접 설치 가능한 파일)
flutter build apk --release
# 결과: build/app/outputs/flutter-apk/app-release.apk

# iOS (App Store 제출용)
flutter build ios --release
# Xcode → Product → Archive 로 제출
```

---

## 8. 자주 겪는 문제와 해결법

### "flutter: command not found"

```bash
# 환경변수 확인
echo $PATH | tr ':' '\n' | grep flutter

# 없으면 다시 등록
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "No devices found" — 기기가 안 보일 때

```bash
# Android 기기
adb devices                    # 목록이 비어 있으면 케이블/USB 디버깅 확인

# iOS 기기
# Xcode에서 서명 설정이 안 되어 있으면 기기가 보여도 빌드 실패함
# → 5-1 단계 확인
```

### "Gradle build failed" (Android)

```bash
# = gradle clean + 재빌드
flutter clean && flutter pub get && flutter run
```

### "CocoaPods" 관련 에러 (iOS)

```bash
cd ios && pod install && cd ..
# 그래도 안 되면:
cd ios && pod deintegrate && pod install && cd ..
```

### "Code Signing" 에러 (iOS)

Xcode에서 Signing & Capabilities 설정을 다시 확인:
- Team이 선택되어 있는지
- Bundle Identifier가 고유한 값인지

### 빌드 성공인데 하얀 화면만 나올 때

```bash
# Riverpod 코드 생성이 안 된 경우
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 앱이 느릴 때

`flutter run`은 기본적으로 **debug 모드**입니다 (디버깅 정보 포함이라 느림).
실제 성능을 보려면:

```bash
flutter run --release    # 릴리즈 모드 (디버깅 불가하지만 빠름)
flutter run --profile    # 프로파일 모드 (성능 측정용)
```

---

## 한눈에 보는 요약

```
[환경 설치 — 1회]
  Xcode + Flutter SDK + Android Studio + CocoaPods
      ↓
[프로젝트 셋업 — 1회]
  flutter create . → flutter pub get → build_runner build
      ↓
[실행]
  USB 연결 → flutter run → 끝!

  갤럭시 패드: USB 디버깅 ON → USB 연결 → flutter run
  아이패드:    Xcode 서명 설정 → USB 연결 → flutter run
```
