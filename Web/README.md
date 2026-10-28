# KALRadar Web

비공식 KAL 호출부호 관측 웹 앱. 지도·검색·항공편 선택·수동 조회·가상 데모·개인정보 안내를 제공합니다. OpenSky → ADSB.lol → adsb.fi 순서로 서버에서 조회하며 제공자 제한 시 대기합니다. 사용자 현재 위치와 검색어를 서버에 전송하지 않습니다. 지도는 Leaflet 1.9.4와 OpenStreetMap 타일을 사용하며 출처를 표시합니다.

## 공통 업데이트

상위 프로젝트의 Shared/radar.json이 공통 원본입니다. Scripts/generate-project.js가 Swift와 Web/shared/radar.json을 생성합니다. 웹 build.mjs도 상위 원본이 있으면 동기화합니다. Web만 독립 체크아웃한 배포 환경에서는 포함된 shared/radar.json을 사용합니다.

- node ../Scripts/watch-sync.mjs: 원본 변경 시 양쪽 생성 코드와 웹 빌드를 갱신합니다.
- ../Scripts/update-all.sh: 원본 동기화, 웹 검증·빌드, 개발 서명 iOS 빌드. NODE가 PATH에 없으면 KERADAR_NODE_BIN에 실행 파일 경로를 지정합니다.
- node scripts/preview.mjs: http://localhost:4173 로컬 웹 실행.

SwiftUI와 HTML UI는 별도 코드여서 기능 변경은 양쪽 구현이 필요합니다. 공통 설정 변경은 자동 생성됩니다. 설치된 iPhone 앱은 새 빌드 설치 또는 App Store 업데이트가 필요하고, 호스팅 웹은 검증 후 Sites 배포가 필요합니다. 소스 동기화가 설치·배포를 대신하지 않습니다.

## 데이터 제한

개인 비공개 이용 버전입니다. 공개·상업 배포는 각 제공자 허가와 ODbL 의무를 별도 확인해야 합니다. 웹은 서버 IP를 공유하며 서버 메모리와 엣지의 짧은 캐시를 사용합니다. 최소 30초 간격과 대기 상태는 프로세스/엣지 기준이며 모든 서버 지역을 포괄하는 영구 제한 저장소는 아닙니다. 서버 재시작 후 상태는 초기화됩니다. 자동 타이머 조회는 없습니다.

Leaflet 라이선스: vendor/Leaflet-LICENSE.txt.

## GitHub Pages 배포

- GitHub Pages 주소: https://outinletter.github.io/kalradar/
- 저장소 Settings → Pages → Source에서 **GitHub Actions**를 선택합니다.
- `main`의 `Web/` 변경을 푸시하면 `.github/workflows/pages.yml`이 정적 웹을 빌드·배포합니다.
- 수동 빌드: `node Web/scripts/build-pages.mjs` (저장소 루트) 또는 `node scripts/build-pages.mjs` (Web 폴더).
- Pages는 화면과 저장 스케줄을 제공합니다. `/api/positions`, `/api/route`, `/api/schedules`는 기존 공개 Sites 서버에 연결하며 허용 출처는 `https://outinletter.github.io`입니다.
- `/kalradar/` 하위 경로, 앱 아이콘, 개인정보 경로, 오프라인 화면 캐시를 지원합니다. 새로운 항공기 위치 조회에는 서버 연결이 필요합니다.
