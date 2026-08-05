# campaign-guides

SIRIAI 인플루언서 협업 콘텐츠 가이드 모음. 각 가이드는 빌드가 필요 없는
정적 페이지(단일 `index.html` + `assets/`)입니다.

## 구조

| 경로 | 내용 |
|---|---|
| [`index.html`](index.html) | **루트 = 현재 진행 캠페인 가이드.** 지금은 Deep Divers Club (틈결 × 에스더버니) |
| [`assets/`](assets/) | 루트 가이드용 이미지 |
| [`guides/`](guides/) | 전체 가이드 인덱스 (내부 관리용, 외부 공유 대상 아님) |
| [`jennie-europe/`](jennie-europe/) | 제니 유럽 사복 · 젠민수 아이템 (블로그 / 패션) |
| `deep-divers-club/` | 구 경로. 루트로 리다이렉트만 합니다 |

캠페인 가이드를 외부에 공유할 때는 **루트 주소만** 전달합니다.
뒤 경로를 지워도 상위에 목록이 노출되지 않도록 하기 위한 구조입니다.

## 열람 비밀번호

모든 페이지에 열람 게이트가 걸려 있습니다. 비밀번호는 협업 파트너에게
가이드 링크와 함께 별도로 전달합니다.

한 번 입력하면 브라우저에 기억되어 다시 묻지 않습니다
(`localStorage` 키 `siriai-guide-unlock`).

> 정적 사이트의 클라이언트 사이드 게이트입니다. 링크를 아는 사람이 우연히
> 열어보는 것을 막는 용도이며, 개발자도구로 우회할 수 있습니다. 실제 접근
> 통제가 필요하면 Vercel Project → Settings → **Deployment Protection** 의
> Password Protection(유료 플랜)을 사용해야 합니다.

비밀번호를 바꾸려면 새 값의 SHA-256 해시를 구해
각 `index.html` 의 `var HASH = '...'` 를 교체합니다.

```bash
printf '새비밀번호' | sha256sum
```

## 로컬에서 보기

```bash
python -m http.server 4599
# → http://localhost:4599/               (캠페인 가이드)
# → http://localhost:4599/guides/        (가이드 인덱스)
# → http://localhost:4599/jennie-europe/ (제니 가이드)
```

`crypto.subtle` 은 보안 컨텍스트에서만 동작하므로 `localhost` 또는 https 로 열어야
비밀번호 확인이 정상 작동합니다. (`file://` 로 직접 열면 게이트가 통과되지 않습니다.)

## 배포 (Vercel)

Vercel Git 연동으로 배포됩니다. `main` 에 푸시하면 자동 재배포되고,
다른 브랜치는 프리뷰 URL이 생성됩니다.

```
https://campagin-guides-un3g.vercel.app/                (캠페인 가이드)
https://campagin-guides-un3g.vercel.app/guides/         (가이드 인덱스)
https://campagin-guides-un3g.vercel.app/jennie-europe/  (제니 가이드)
```

빌드가 없는 정적 레포라 `vercel.json` 을 두지 않습니다. Vercel 기본 동작이
디렉터리의 `index.html` 을 그대로 서빙하므로 추가 설정이 필요 없습니다.
(`trailingSlash` 를 켜면 `assets/` 하위 이미지 경로까지 리다이렉트되어
에셋이 깨질 수 있으니 다시 추가하지 마세요.)

커스텀 도메인은 Project → Settings → Domains 에서 연결합니다.

## 새 캠페인 가이드를 올릴 때

1. 현재 루트 가이드를 `<캠페인명>/` 으로 옮기고 `assets/` 도 함께 옮깁니다
2. 새 가이드를 루트에 배치합니다
3. `guides/index.html` 인덱스에 카드를 추가합니다

## 스택

정적 HTML/CSS/JS (빌드 불필요). 폰트는 Google Fonts(Instrument Sans, Noto Sans KR) CDN.

---
제작: SIRIAI · 내부 콘텐츠 가이드 자료
