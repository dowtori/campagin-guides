# SIRIAI Training Campus v4

소현님을 위한 DM 모집 업무 교육 맵. 여섯 부스와 18개 활동으로 구성했습니다.

## 바로 열기

1. `downloads/SIRIAI_Training_Campus_v4.rbxl`을 받습니다. Roblox Studio에서 이전 파일을 닫고 새 v4 파일을 엽니다.
2. **플레이**를 누르면 화면 위에 `SIRIAI v4`와 환영 창이 표시됩니다.
3. 첫 미션으로 이동하거나, 부스 안으로 걸어 들어가 **E** 또는 화면 아래 **미션 시작**을 누릅니다. 단말기 자체의 E/터치 버튼도 동작합니다.
4. 실제 Roblox 접속 링크는 본인 계정에 게시하고 이용 권한을 설정하면 생성됩니다. 현재 웹 링크는 미리보기·다운로드 페이지입니다.

기본 `SIRIAI_Training_Campus.rbxlx` 주소도 최신 v4입니다. 이름에 v2·v3가 붙은 파일은 이전 버전입니다. 새 `.rbxl` 파일은 같은 프로젝트를 담은 압축된 네이티브 형식입니다.

## 이번에 바꾼 내용

- 부스 사이 간격을 넓히고, 불투명한 뒤쪽 벽·개별 색·큰 번호·전용 그림으로 공간을 구분했습니다.
- 안내판이 기둥에 가리던 입구 구조를 없앴습니다. 부스 번호·제목·그림·설명·단말기는 각각 별도 위치에 배치했습니다.
- 미션 시작을 단말기 근처에만 의존하지 않도록 바꿨습니다. 부스 내부의 화면 버튼과 E 입력은 같은 서버 검증 경로를 사용합니다. 미래 미션 잠금, 거리 검사, 중복 입력 제한은 유지합니다.
- 실행 진입점을 작은 부트스트랩으로 나누고, 공유 모듈은 ReplicatedStorage에서 준비될 때까지 기다립니다. 시작 오류가 있으면 조용히 멈추는 대신 화면에 재시도 버튼과 오류 위치를 표시합니다. 개별 UI 이벤트의 오류도 나머지 입력을 끊지 않도록 처리합니다.
- 금빛 갈대·보랏빛 픽셀 하늘·붉은 태양·청록색 마름모 조형물을 실제 공간에 반영했습니다. 배경은 사방을 둘러싼 이미지 패널로 구성했습니다.
- 제공된 시리아이 심볼·로고·프로필 이미지와 실제 확장프로그램 화면을 사용합니다. 부스 그림 여섯 종과 하늘은 이미지 생성 도구로 새로 제작했습니다. 콘셉트 페이지에만 두지 않고 실제 맵에 픽셀 데이터를 포함했습니다.

## 시각 자료

`assets/asset-provenance.json`에 사용 자료, 출처, 생성 도구와 전체 프롬프트, 사용 위치를 기록했습니다.

- `assets/world-sky.png`: 확정한 붉은 태양 시안에서 제작한 배경용 하늘
- `assets/booth-art-atlas.png`: 여섯 부스를 위한 새 픽셀 아트
- `assets/siriai-symbol*.png`, `siriai-wordmark-white.png`: 사용자 제공 시리아이 로고
- `assets/siriai-profile-gradient.jpg`: 사용자 제공 프로필용 이미지
- `assets/ig-lead-saver-settings.png`, `chrome-extension-options.png`: 사용자 제공 실제 설정 캡처

이미지는 `src/shared/RasterData/`에 이미지별로 인코딩되며, 필요한 이미지부터 불러옵니다. 전체 빌드용 데이터는 `raster-data.json`입니다. 원본 이미지의 실제 픽셀을 사용하며, EditableImage가 사용 가능하면 ImageLabel로 표시하고 그 외에는 병합한 픽셀 사각형으로 표시합니다. 맵을 열었을 때 별도 이미지 주소를 설정할 필요가 없습니다. 웹의 광원·물 렌더링은 Roblox와 다르며, 웹 화면을 실제 Roblox 플레이 캡처로 표시하지 않습니다.

## 교육과 조작

| 부스 | 내용 |
|---|---|
| 01 프로필 스튜디오 | 제공 로고·소개·링크로 계정 준비 |
| 02 연결 연구실 | IG Lead Saver 설정·연결 순서·기본 상태 |
| 03 크리에이터 가든 | 캠페인 적합도·기존 접촉·지원 요청 |
| 04 DM 포스트오피스 | 구간별 문구·발송 후 상태·유효 발송 |
| 05 리플라이 카페 | 고료 조정 희망 금액 기록·공유·어려운 문의 |
| 06 리워드 라운지 | 유효 발송 300원·최종 선정 2,000원·정산 |

PC는 WASD/스페이스, 모바일은 화면 조이스틱과 점프 버튼을 사용합니다. 미션지도 또는 M으로 현재·완료한 부스로 이동합니다. 노을 산책은 진행 상황을 유지한 채 물가로 이동하며, 교육으로 돌아가기로 복귀합니다. 스탬프는 중복 지급되지 않습니다. 닫기·캐릭터 재생성 후 이번 접속의 완료 단계는 유지되고, 재접속하면 새 연습을 시작합니다.

실제 DM·계정·업무 시트에 연결하지 않는 교육용 사례입니다. 실제 DM에는 기본 고료가 포함되고, 조정을 희망하는 경우 희망 금액을 기록·공유합니다. 지원과 최종 선정은 구분하며 최종 선정은 브랜드에서 진행합니다.

## 빌드

```sh
python build_raster_assets.py
python build_map.py
rojo build default.project.json -o downloads/SIRIAI_Training_Campus_v4.rbxl
rojo build default.project.json -o downloads/SIRIAI_Training_Campus.rbxlx
python tests/run_tests.py --luau /path/to/luau
python tests/environment.spec.py
```

`src/shared/ClientMain.lua`는 전체 교육 UI, `RasterRenderer.lua`는 실제 이미지 표시, `VisualTutorials.lua`는 18개 조작 활동입니다. `src/client/TrainingBootstrap.client.lua`가 실행을 시작합니다. `src/server/TrainingServer.server.lua`가 진행과 거리·단계·답안을 검증합니다.

## 확인 범위

Rojo 빌드와 Luau 구문 검증, 상태·진행 318개 검증, 36개 PC/모바일 활동 UI 경로, 12개 산책/복귀 검사, 13개 전체 클라이언트 시작/이벤트 검사, 여섯 부스의 네 모서리·18개 활동을 포함한 51개 서버 진입 검사를 실행했습니다. 안내판과 기둥의 교차, 부스 간격, 실제 이미지 데이터, 연속된 산책길도 확인합니다. 웹은 PC·모바일에서 이미지·미션 선택·18개 활동·다운로드를 확인합니다.

어댑터 검증은 Roblox 엔진을 대신하지 않습니다. 이 환경에는 Roblox Studio가 없어 실제 엔진 플레이와 계정 게시를 수행하지 못했습니다. 시작 오류가 재현되면 새 부트스트랩의 화면 오류 또는 Studio 출력의 `[SIRIAI]` 메시지로 위치를 확인할 수 있습니다.

웹에는 Three.js(MIT)와 Pretendard(OFL)를 사용합니다. 라이선스는 `vendor/THREE-LICENSE.txt`, `assets/Pretendard-LICENSE.txt`에 포함되어 있습니다.
