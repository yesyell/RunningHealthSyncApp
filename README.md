# RunningHealthSyncApp

`RunningHealthSyncApp`은 `running_health_mcp`의 tool 계층을 실제로 호출하는 SwiftUI iOS 앱 예제입니다.  
UI는 한국어 우선이며, 러닝 목표, 주간 거리, 페이스 추세, 회복 상태, 추천 코스, 자연어 질의 흐름까지 한 앱에서 다룹니다.

## 왜 HTTP 브리지를 추가했나

`running_health_mcp/server.py`는 표준 `stdio` 기반 MCP 서버입니다. 이 방식은 데스크톱 에이전트에는 적합하지만, iOS 앱은 다음 이유로 `stdio` MCP 프로세스를 직접 다루기 어렵습니다.

- iOS 앱 내부에서 Python 런타임과 MCP subprocess를 안정적으로 관리하기 어렵습니다.
- 시뮬레이터/실기기에서 로컬 프로세스 생명주기와 표준 입출력 스트림 연결을 앱 계층에 직접 넣는 것은 확장성이 낮습니다.
- 실제 모바일 앱 구조에서는 네트워크 경계가 있는 브리지 계층이 테스트, 배포, 인증, 원격화에 유리합니다.

그래서 개발용으로 `running_health_mcp/http_bridge.py`를 추가했습니다.  
이 브리지는 `server.py`와 동일한 tool module(`app_context.py`, `tools/*.py`, `TOOL_DEF`, `run()`)을 그대로 사용합니다. 즉, 스키마와 실행 로직의 기준은 원본 MCP 코드입니다.

## 먼저 확인한 MCP tool 요약

코드 기준으로 확인한 tool은 아래 5개입니다.

- `health_query`
  - 입력: `metric`, `period`, `limit` 또는 `sql`
  - 구조화 조회 지표: `pace`, `weekly_mileage`, `distance`, `sessions`, `heart_rate`
  - 기간: `weekly`, `monthly`, `recent_sessions`
  - 응답: `data`, `query`, `context`

- `health_interpret`
  - 입력: `user_query`
  - 응답: `matched_concepts`, `is_trend_query`, `intent`, `period`, `aggregation`, `next_actions`, `user_baseline`

- `health_report`
  - 입력: `period`, `n`
  - 응답: `period`, `series`, `summary`

- `health_insight`
  - 입력: `metric`, `weeks`
  - metric: `pace`, `distance`, `weekly_mileage`, `recovery`
  - 응답: `metric`, `weeks`, `series`, `analysis`, `signals`, `user_context`

- `running_recommend`
  - 입력: `location`, `lat`, `lon`
  - 응답: `input`, `weather`, `recent_pace_min_km`, `suggested_pace_min_km`, `courses`, `cold_tips`, `user_context`

## 디렉터리 구조

```text
RunningHealthSyncApp/
  RunningHealthSyncApp.xcodeproj
  RunningHealthSyncApp/
    App/
    Models/
    Services/
    ViewModels/
    Views/
    Preview/
    Info.plist
```

## 브리지 실행

`running_health_mcp` 폴더에서 실행:

```bash
cd /Users/yelin/Documents/STUDY/MCP/running_health_mcp
python3 http_bridge.py
```

기본 주소:

```text
http://127.0.0.1:8080
```

확인:

```bash
curl http://127.0.0.1:8080/api/tools
curl -X POST http://127.0.0.1:8080/api/dashboard -H 'Content-Type: application/json' -d '{}'
```

## Xcode 실행

1. `RunningHealthSyncApp/RunningHealthSyncApp.xcodeproj`를 엽니다.
2. 시뮬레이터 기준으로 실행합니다.
3. 브리지가 다른 주소에서 떠 있다면 `AppConfiguration.baseURL` 값을 수정합니다.

기본값:

```text
http://127.0.0.1:8080
```

실기기 테스트 시에는 `127.0.0.1` 대신 개발 머신의 LAN IP를 사용해야 합니다.

## 화면 구성

- 대시보드
- 자연어 질의
- 리포트
- 인사이트
- 추천 코스
- 구조화 조회

## 다음 단계

- 인증/사용자 분리
- 브리지의 실제 MCP stdio 프록시화
- 서버 푸시/백그라운드 동기화
- HealthKit 실데이터 매핑
