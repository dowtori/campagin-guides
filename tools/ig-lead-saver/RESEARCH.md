# 근거와 변경 결정 · 2026-10-23

## 실제 환경에서 확인한 사실

- 설치된 기존 확장 ID `ghakpcjppjjlcmfcalfklciejlbilonn`의 로그인한 Chrome 작업 탭에서 HTTP 429 로그와 `아직 멈추지 않습니다`라는 재시도 로그가 반복되어 있었습니다.
- 같은 실제 화면의 팔로워는 3,744명인데 타일의 팔로워 배지가 비어 있었습니다. 링크 `href`는 `/followers/`가 아닌 `#`이고, 보이는 `팔로워` 라벨과 내부 `title="3744"`로 숫자를 확인할 수 있었습니다.
- 별도의 로그아웃 탭에서는 HTTP 401 로그가 반복되어 있었습니다. 이를 로그인한 작업 탭의 429와 같은 원인으로 취급하지 않았습니다.
- 해당 로그는 열려 있던 실제 탭에서 읽은 실행 로그입니다. 통제된 전후 시간 측정이나 개선판의 실제 API 성공 증거는 아닙니다.

## 최근 공개 근거

1. [OpenCLI issue #2234, 2026-08-04](https://github.com/jackwener/OpenCLI/issues/2234): 일부 비즈니스 계정의 `web_profile_info` 400 및 서버 스키마 오류 보고. [현재 profile 구현](https://github.com/jackwener/OpenCLI/blob/main/clis/instagram/profile.js)은 사용자명 feed 응답의 **루트 user**에서 pk를 얻고 users/info를 조회하는 경로를 사용합니다. 첫 게시물 작성자를 프로필 주인으로 간주하지 않는 점을 반영했습니다. 사용자의 실제 400 발생은 확인하지 않았습니다.
2. [instagram_monitor 릴리스 기록, 2026-09](https://github.com/misiektoja/instagram_monitor/blob/main/RELEASE_NOTES.md): 프로필 조회 경로 문제와 ID 재사용 관련 변경 기록. 모든 인스타그램 계정의 동일 원인이라는 증거는 아닙니다.
3. [Instaloader #2651](https://github.com/instaloader/instaloader/issues/2651): 429·계정/요청 조건 차이 관련 보고. 429라는 사실만으로 계정 전체의 사용량 한도가 정확한 원인이라고 단정할 수 없습니다.
4. [Reddit, 2026-09-09](https://www.reddit.com/r/chrome_extensions/comments/1wbjzl1/igfollow_extension/): 여러 이용자의 확장 프로그램 동작 중단 경험. **팔로워 목록 내보내기**에 대한 내용이므로 이 도구의 팔로워 **수** 조회 문제와 동일한 원인으로 확정하지 않았습니다. 기술 설계는 원본 코드와 공식 문서에 근거했습니다.
5. [Google Apps Script 성능 지침](https://developers.google.com/apps-script/guides/support/best-practices), [Lock 공식 문서](https://developers.google.com/apps-script/reference/lock/lock.html): 조회·저장 경로 분리와 저장 후 flush/잠금 해제에 반영했습니다.
6. [Chrome content_scripts 공식 문서](https://developer.chrome.com/docs/extensions/reference/manifest/content-scripts): MAIN world에서 정상 페이지 응답을 관찰하고, 확장 쪽에서는 필요한 공개 항목만 선별해 재사용하는 구조에 참고했습니다.

## 결정

- 기존 실패 API에 여러 app ID로 재시도하는 경로를 제거했습니다.
- 화면·정상 페이지 응답·캐시를 먼저 사용합니다. 추가 조회에는 탭 내 공용 순차 큐, 중복 요청 합치기, 응답 제한 시간, 429/401 중단을 적용했습니다.
- 추가 조회 경로는 최신 오픈소스에서 확인한 방법을 참고했지만, **이 계정에서 동작이 검증된 우회 경로라고 주장하지 않습니다.**
- 기존 접촉 표시는 Instagram API가 아닌 시트 이력의 로컬 사본에서 그립니다. 게시물의 작성자 자체가 아직 식별되지 않은 경우는 별도 조회/화면 확인이 필요합니다.
- 새 앱 ID 돌려쓰기, 프록시, 쿠키 복사, 자동 DM 발송은 도입하지 않았습니다.
