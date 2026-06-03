# RunningHealthSyncApp

`RunningHealthSyncApp`은 Strava로 로그인한 사용자의 러닝 데이터를 기반으로 대시보드, 리포트, 인사이트, 추천 코스, 자연어 질의를 제공하는 SwiftUI iOS 앱입니다.

앱은 `runnershello.duckdns.org` 백엔드 API와 통신하며, 로그인 후 발급받은 세션 토큰을 Keychain에 저장해 API 호출에 사용합니다.

## 주요 기능

- Strava OAuth 로그인
- Keychain 기반 세션 저장 및 로그아웃
- 주간 러닝 요약 대시보드
- 자연어 러닝 데이터 질의
- 기간별 러닝 리포트
- 페이스, 거리, 회복 상태 인사이트
- 위치와 최근 기록을 반영한 러닝 코스 추천
- 목표 페이스, 주간 목표 거리, 선호 지역 설정

## 앱 흐름

1. 앱 실행 시 Keychain에 세션 토큰이 있는지 확인합니다.
2. 세션이 없으면 Strava 로그인 화면을 표시합니다.
3. 서버에서 Strava OAuth 설정을 받아 인증 페이지를 엽니다.
4. 콜백 URL을 통해 받은 인증 코드를 서버에 전달합니다.
5. 서버가 앱 세션 토큰을 발급하면 Keychain에 저장합니다.
6. 이후 API 요청에는 `Authorization: Bearer <token>` 헤더를 붙여 호출합니다.

## 화면 구성

- `DashboardView`: 주간 거리, 최근 기록, 핵심 지표 요약
- `NaturalLanguageQueryView`: 자연어 질문 기반 러닝 데이터 조회
- `ReportView`: 기간별 러닝 리포트
- `InsightView`: 페이스, 거리, 회복 관련 추세 분석
- `RecommendationView`: 러닝 코스와 페이스 추천
- `StructuredQueryView`: 지표와 기간을 선택하는 구조화 조회
- `SettingsView`: 목표 및 Strava 세션 관리

## 서버 설정

기본 API 서버 주소는 `Info.plist`의 `RunningHealthBaseURL` 값으로 관리합니다.

```text
https://runnershello.duckdns.org
```

앱은 아래 API를 사용합니다.

- `GET /api/auth/strava/config`
- `POST /api/auth/strava/exchange`
- `POST /api/call/{tool_name}`
- `POST /api/dashboard`
- `POST /api/natural-query`

## OAuth 콜백

앱의 URL scheme은 `runnershello`입니다.

```text
runnershello://...
```

Strava OAuth 설정과 백엔드 콜백 처리도 이 scheme과 맞아야 합니다.

## 프로젝트 구조

```text
RunningHealthSyncApp/
  RunningHealthSyncApp.xcodeproj
  RunningHealthSyncApp/
    App/
    Auth/
    Models/
    Services/
    ViewModels/
    Views/
    Preview/
    Info.plist
```

## 실행 방법

1. Xcode에서 `RunningHealthSyncApp.xcodeproj`를 엽니다.
2. iOS 시뮬레이터 또는 실기기 타겟을 선택합니다.
3. 앱을 실행합니다.
4. 첫 화면에서 Strava로 로그인합니다.

서버 주소를 바꾸려면 `Info.plist`의 `RunningHealthBaseURL` 값을 수정합니다.
