# KERadar · 무료 공개 ADS-B 버전

`KERadar.xcodeproj`를 열어 KERadar 스킴으로 실행합니다. iOS 17 이상. 기본은 공개 위치 조회 모드이며 새로고침 버튼으로 조회합니다. 토큰·FR24 API 플랜은 필요하지 않습니다.

## 조회 범위와 필터

기본 OpenSky 조회는 **전 세계**이며 수신망에서 관측된 KAL 항공기만 표시합니다. 전체 대한항공 항공기를 빠짐없이 보장하지 않습니다. OpenSky 제한/장애 시 ADSB.lol 또는 adsb.fi의 인천 중심 **250해리 지역 대체**로 전환하며 축소된 범위를 화면에 표시합니다. `KAL`+숫자+선택적 영문 1자 호출부호만 추정 포함합니다. 호출부호만으로 운항사/소유권 확정은 불가능합니다. 출도착 공항이나 KE 편명은 추측하지 않습니다.

## 제공자 자동 전환

1. OpenSky 익명 API (전 세계)
2. ADSB.lol (인천 중심 250해리)
3. adsb.fi (인천 중심 250해리)

429 제한, 401/403 정책 변경, 서버 오류, 네트워크 및 응답 해석 오류 시 다음 제공자로 전환합니다. 정상 빈 결과는 장애가 아니므로 전환하지 않습니다. 한 번 조회당 각 제공자는 최대 한 번 시도합니다. 최소 사용자 조회 간격 30초. Retry-After(초 또는 HTTP 날짜)와 OpenSky X-Rate-Limit-Retry-After-Seconds를 존중합니다. 429 헤더 미제공은 1시간, 401/403은 1시간, 기타 오류는 2분간 해당 제공자를 쉬게 합니다. 대기 상태는 앱 프로세스 메모리에 유지되며 재시작 후 초기화되지만 서버 자체 제한은 계속 적용됩니다. IP 교체·키 공유·제한 우회는 하지 않습니다.

모든 제공자가 실패하면 오류와 이전 성공 응답을 표시합니다. 출처·범위·마지막 조회시각을 표시합니다. 자동 타이머/백그라운드 요청 없음. API 응답은 ephemeral URLSession과 메모리로만 처리합니다.

## 이용 조건

- ADSB.lol: https://www.adsb.lol / https://api.adsb.lol · ODbL. 프로덕션 이용은 운영자 문의, 향후 키 정책 변경 가능.
- adsb.fi: https://adsb.fi / https://github.com/adsbfi/opendata · 개인 비상업용, 출처와 링크 표시, 초당 1회 제한. 상업/고빈도는 별도 문의.
- OpenSky: https://openskynetwork.github.io/opensky-api/rest.html · 익명 일일 400크레딧, 조회 면적별 비용. 전 세계 조회는 요청당 4크레딧으로 익명 하루 최대 약 100회(공유 IP의 다른 사용량에 따라 감소). 약관·재배포 허용 범위 별도 검토.

수신망에 따라 관측이 누락/지연될 수 있습니다. 무료 접근의 영구 지속이나 가용성을 보장하지 않습니다. 개인용 개발 앱이며 공개/상업 배포에는 약관·라이선스 검토가 필요합니다. 항공 안전·항법용이 아닙니다.

## 검증 및 설치

2026-10-14: Xcode 26.3에서 개발 서명된 iPhone용 1.1(2) 빌드 성공, codesign 검증 통과. 시뮬레이터 테스트 타깃 컴파일 성공. macOS에서 별도 회귀 실행으로 데이터 모드 전환, 검색, OpenSky 변환, 빈 결과, 조회 제한 확인. 실제 iOS 화면 검증과 XCTest 시뮬레이터 실행은 아직 수행하지 않았습니다. 등록된 iPhone 16 Pro가 연결 불가 상태여서 실제 설치는 미완료입니다.

비공식 앱 안내, 앱 내 개인정보 처리방침, PrivacyInfo.xcprivacy와 앱 아이콘을 추가했습니다. App Store 제출에는 공개 개인정보 처리방침/지원 URL, 제공자 배포 허가 및 실제 기기 검증이 추가로 필요합니다.
프로젝트 재생성: `node Scripts/generate-project.js`.

과거 FR24 참조 코드와 분석은 남아 있지만 앱 조회 경로는 PublicADSBClient만 사용합니다. 기존 Keychain 토큰을 읽거나 전송하지 않습니다.


## 병행 웹 버전과 동기화 (2026-10-14)

웹: https://keradar-parallel.gentlevale3.chatgpt.site (본인 전용 비공개 Sites)

Shared/radar.json을 기준으로 제공자 주소, 호출부호 필터, 조회 간격, 데모 항공편, 안내 문구와 버전을 관리합니다. iOS는 KERadar/SharedRadar.swift, 웹은 Web/shared/radar.json으로 생성됩니다. Web/README.md와 AGENTS.md에 병행 업데이트 절차가 있습니다.

`node Scripts/watch-sync.mjs`로 공통 원본 변경 감시·생성을 시작합니다. `Scripts/update-all.sh`는 웹 검증과 양쪽 빌드를 실행합니다. iOS 화면과 웹 화면은 별도 구현이며 기능 변경은 양쪽 수정이 필요합니다. 설치된 아이폰은 새 빌드 설치, 호스팅 웹은 검증된 소스의 Sites 배포로 업데이트됩니다.

1.2(3) 개발 서명 iOS 빌드 성공. 웹 디코딩/필터/대기 테스트 통과. 브라우저에서 데모, 검색, 선택, 개인정보 창, 모드 초기화 및 모바일 가로 넘침 검증. 로컬 웹 OpenSky 조회에서 49대 표시 확인. iPhone 연결 불가에 따른 실제 설치 미완료 상태는 계속됩니다.


설치 완료 (2026-10-14): Jeon’s iPhone (iPhone 16 Pro)에 KALRadar 1.2(3)를 devicectl로 설치하고 실행 요청 성공을 확인했습니다. 화면 조작·전체 기능 실기기 검증은 별도 확인이 필요합니다.


1.3(4): iOS·웹 밝은 테마 적용. 편명 옆 출도착 경로를 표시하고 선택한 실제 항공편은 ADSBDB 호출부호 조회로 IATA 편명·공항을 보완합니다. 등록 경로는 실제 운항일의 경로와 다를 수 있고 결과가 없으면 미상입니다. 웹 커밋 d00b81e9489f34d20fbb9212c9e6bd7c9a853320 푸시 및 비공개 배포 완료. Jeon’s iPhone 재설치 완료.


1.4(5): 실행·앱 복귀 시 자동 조회, 모호한 준비 안내·지도 위 큰 박스 제거. UTC 관측 시각, 120초 초과 위치 경과 표시, 전체 항공기 보기 및 항공편 요약 공유/복사 추가. 웹 실행 직후 30대 자동 표시 검증, 웹 커밋 64f88ade8755f9cab8416030e8f851dc2953829e 푸시·배포, iPhone 재설치 완료. 반복·백그라운드 네트워크 조회는 하지 않습니다.


## GitHub Pages 웹 배포

웹 주소: https://outinletter.github.io/kalradar/

저장소 Settings → Pages → Build and deployment의 Source를 **GitHub Actions**로 설정합니다. `main`의 `Web/` 소스가 변경되면 `.github/workflows/pages.yml`이 화면을 자동 배포합니다. 최초 설정 후 Actions의 "Deploy KAL Radar web to GitHub Pages"를 실행할 수 있습니다.

화면은 GitHub Pages에서 제공하고 항공 위치·등록 경로·새 스케줄 조회는 기존 공개 서버(https://keradar-parallel.gentlevale3.chatgpt.site)를 사용합니다. Pages는 정적 호스팅이므로 서버 API는 별도로 유지됩니다. 저장 스케줄과 오프라인 화면은 기존과 같이 지원합니다.

로컬 정적 빌드: `node Web/scripts/build-pages.mjs`. 세부 사항은 `Web/README.md`를 참고하세요.
