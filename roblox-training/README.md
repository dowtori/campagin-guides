# SIRIAI Training Campus

소현님을 위한 인플루언서 모집 업무 교육 맵. 6개 공간을 방문하며 18개 활동을 완료하는 Roblox용 프로젝트입니다.

## 바로 열기

1. `downloads/SIRIAI_Training_Campus.rbxlx`를 받습니다.
2. PC의 **Roblox Studio → 파일 열기**에서 이 파일을 선택합니다.
3. **플레이**를 누르면 환영 화면과 교육 미션이 시작됩니다.
4. 계정에 올릴 때는 Studio의 **Roblox에 게시**를 사용하고, 원하는 이용 권한을 설정합니다. 실제 Roblox 경험 링크는 게시 후 생깁니다.

브라우저의 `index.html`은 맵 구조를 보여주는 3D 미리보기입니다. Roblox 경험을 대신 실행하지 않습니다.

## 교육 구성

| 순서 | 공간 | 연습 내용 |
|---|---|---|
| 1 | 프로필 스튜디오 | 제공 자료로 프로필 준비, 소개 문구, 업무 범위 |
| 2 | 연결 연구실 | IG Lead Saver 옵션 열기, 연결 순서, 기본 상태 |
| 3 | 크리에이터 가든 | 캠페인 적합도, 기존 접촉, 수집 지원 요청 |
| 4 | DM 포스트오피스 | 팔로워 구간별 문구, 발송 후 표시, 유효 발송 |
| 5 | 리플라이 카페 | 고료 조정 요청, 어려운 문의, 지원과 선정 구분 |
| 6 | 리워드 라운지 | 300원 기본 보수, 2,000원 선정 인센티브, 정산 예시 |

교육용 팔로워 조건·고료·가상 계정은 실제 캠페인 조건이 아닙니다. 실제 DM에는 기본 제안 고료가 들어 있으며, 조정을 희망하는 인원은 희망 금액을 기록·공유합니다. 최종 선정은 브랜드에서 진행합니다.

## 조작과 진행

- 이동: PC `WASD`, 모바일 화면 조이스틱. 점프: 스페이스 / 모바일 점프 버튼.
- 미션: 단말기 가까이에서 `E`, 게임패드 `X`, 또는 화면의 터치 버튼.
- 오른쪽 위 **미션지도**에서 현재·완료한 공간으로 이동할 수 있습니다. PC에서는 `M`도 가능합니다.
- 틀린 답은 설명을 보고 다시 선택합니다. 순서 문제는 버튼을 순서대로 누른 뒤 확인합니다.
- 스탬프는 서버에서 각 플레이어별로 계산합니다. 완료한 공간을 복습해도 중복 지급되지 않습니다.
- 미션 도중 닫거나 캐릭터가 다시 생성되면 이번 접속의 완료 단계가 유지됩니다. 재접속하면 처음부터 새 연습을 시작합니다. 영구 저장은 사용하지 않습니다.
- 마지막 미션 이후 수료 화면, 수료 데크, 화면 종이 조각 효과가 나옵니다. Roblox 공식 배지나 실제 보수를 지급하는 기능은 아닙니다.

실제 외부 계정, 업무 시트, DM 발송 서비스에 연결하지 않습니다. 확장프로그램의 실제 설치·세팅은 별도로 전달한 업무 안내서에서 진행합니다.

## 수정과 빌드

- `src/server/Curriculum.json`: 교육 문구·정답·공간 정보
- `src/server/TrainingEngine.lua`: 미션 진행과 채점
- `src/server/TrainingServer.server.lua`: 개인별 진행·단말기·이동·서버 검증
- `src/client/TrainingClient.client.lua`: 한국어 PC/모바일 UI
- `build_map.py`: 외부 모델 없이 기본 도형으로 만드는 맵
- `map/TrainingMap.model.json`: 생성된 3D 공간
- `default.project.json`: Rojo 프로젝트

Python 3와 [Rojo](https://rojo.space/docs/v7/)가 있는 환경에서:

```sh
python build_map.py
rojo build default.project.json -o downloads/SIRIAI_Training_Campus.rbxlx
```

[Luau CLI](https://github.com/luau-lang/luau/releases)로 검증:

```sh
luau-compile --null src/server/TrainingEngine.lua src/server/TrainingServer.server.lua src/client/TrainingClient.client.lua
python tests/run_tests.py --luau /path/to/luau
```

## 확인 범위

Rojo 7.7.1로 파일 빌드, Luau 0.744 구문 검증, 290개 상태·진행 검증, 실제 내보낸 파일의 6개 단말기·스크립트 구조 검증을 완료했습니다. 웹 미리보기는 PC와 모바일 크기로 확인합니다. **Roblox Studio의 실제 플레이 테스트와 Roblox 계정 게시·공개 설정은 이 환경에서 수행하지 않았습니다.**

## 제작 자료

맵의 공간·가구·표지·식물·트로피는 기본 도형으로 직접 제작했습니다. 외부 무료 모델, 메시, 이미지, 음원, 외부 Roblox 에셋 ID를 사용하지 않았습니다. 이후 제3자 자료를 추가하는 경우 해당 자료의 이용 권한을 별도로 확인해주세요.

웹 미리보기만 Three.js 0.180.0(MIT)와 Pretendard(OFL)를 사용합니다. 각 라이선스는 `vendor/THREE-LICENSE.txt`, `assets/Pretendard-LICENSE.txt`에 포함되어 있습니다.
