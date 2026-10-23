# IG Lead Saver · Chrome 웹스토어 운영판

기존에 등록된 [IG Lead Saver](https://chromewebstore.google.com/detail/ghakpcjppjjlcmfcalfklciejlbilonn)의 1.5.0 업데이트 소스입니다. 기준은 제공된 1.4.0 패키지이며, 실제 스토어의 최신 게시 버전은 이번 작업에서 조회하지 못했습니다.

**상태: 제출용 ZIP 생성 완료. 스토어 심사 제출·게시 및 실계정 업데이트 검증 전입니다.**

## 기존 설치자

스토어에 1.5.0이 게시되면 기존 확장 ID로 업데이트받습니다. 웹앱 URL, 저장자, 캠페인, 기본 상태와 표시 옵션을 다시 입력할 필요가 없도록 유지합니다. 업데이트 후 열려 있던 인스타그램 작업 탭을 한 번 새로고침합니다.

업데이트가 늦는 경우 Chrome 확장 관리의 개발자 모드 → 업데이트로 게시된 최신 버전 확인을 요청할 수 있습니다. 새 버전이 실제로 게시되기 전에는 적용되지 않습니다. [Chrome 업데이트 동작](https://developer.chrome.com/docs/extensions/develop/concepts/extensions-update-lifecycle)

## 1.5.0 변경

- 화면의 팔로워 수·정상 페이지 응답·캐시를 우선 활용합니다. 추가 조회는 순차 처리하고 같은 요청을 합칩니다.
- 429 또는 로그인 확인 응답을 받으면 추가 조회를 중단하고 안내합니다.
- 확인된 작성자의 접촉 이력은 로컬 이력에서 먼저 표시합니다. 서버 갱신은 별도로 수행합니다.
- 기존 설정·최근 저장·독 위치를 유지합니다. 유효한 1.4 팔로워 캐시는 원래 시각을 유지해 재사용합니다.
- 1.4의 시트 구분 없는 접촉 캐시는 원본을 한 번 보관한 뒤 현재 시트에서 다시 확인합니다. 운영 시트의 행은 지우거나 옮기지 않습니다.
- 구버전 코드가 남은 탭에서는 팝업에 새로고침을 안내합니다.
- 긴 조회 제한 안내가 화면을 가리지 않도록 패널 폭을 제한했습니다.

추가 API 권한·접속 도메인은 없습니다. 백엔드의 조회 잠금 개선은 관리자가 기존 Apps Script 배포를 업데이트해야 적용됩니다.

## 운영자 자료

- [스토어 버전 업데이트 절차](releases/STORE_UPDATE.md)
- [사용자에게 보낼 업데이트 안내](releases/RELEASE_NOTES_KO.txt)
- [별도 백엔드 업데이트](releases/BACKEND_UPDATE.md)
- [조사 근거](RESEARCH.md) · [검증 범위와 미완료 항목](VERIFICATION.md)

## 개발·패키징

```sh
node --test tests/*.test.cjs
python scripts/build_release.py --output ./dist
```

스토어 제출용 ZIP은 `manifest.json`이 ZIP 최상위에 있으며 실행 파일만 포함합니다. 테스트·문서·Apps Script는 확장 ZIP에 넣지 않습니다. 백엔드 ZIP은 운영자가 별도로 적용하는 파일입니다.
