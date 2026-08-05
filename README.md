# campaign-guides

SIRIAI 인플루언서 협업 콘텐츠 가이드 모음. 각 캠페인은 하위 폴더의 정적 사이트(단일 `index.html` + `assets/`)로 구성됩니다.

## 가이드 목록

| 캠페인 | 형식 | 경로 |
|---|---|---|
| Deep Divers Club 런칭 (틈결 × 에스더버니) | 릴스 / 런칭 캠페인 | [`deep-divers-club/`](deep-divers-club/) |
| 제니 유럽 사복 · 젠민수 아이템 | 블로그 / 패션 | [`jennie-europe/`](jennie-europe/) |

루트 [`index.html`](index.html) 은 전체 가이드 인덱스입니다.

## 로컬에서 보기

```bash
python -m http.server 4599
# → http://localhost:4599                    (인덱스)
# → http://localhost:4599/deep-divers-club/  (Deep Divers Club 가이드)
# → http://localhost:4599/jennie-europe/     (제니 가이드)
```

## 배포 (Vercel)

빌드가 필요 없는 정적 사이트라 Vercel에 레포만 연결하면 바로 라이브됩니다.

1. [vercel.com/new](https://vercel.com/new) → GitHub 계정 연결 → `dowtori/campagin-guides` **Import**
2. 설정은 손대지 않고 그대로 **Deploy** (루트 [`vercel.json`](vercel.json) 이 프레임워크 없음 / 빌드 없음 / 출력 `.` 으로 고정)
3. 이후 `main` 에 푸시할 때마다 자동 재배포, 다른 브랜치는 프리뷰 URL 생성

배포 후 주소:

```
https://<project>.vercel.app/                    (인덱스)
https://<project>.vercel.app/deep-divers-club/   (Deep Divers Club 가이드)
https://<project>.vercel.app/jennie-europe/      (제니 가이드)
```

커스텀 도메인은 Project → Settings → Domains 에서 연결합니다.

## GitHub Pages (대안)

Settings → Pages → Branch `main` / `/root` 로도 배포할 수 있습니다.
`https://<user>.github.io/campagin-guides/` 에서 인덱스가, `.../deep-divers-club/` 에서 개별 가이드가 열립니다.

## 스택

정적 HTML/CSS/JS (빌드 불필요). 폰트는 Google Fonts(Instrument Sans, Noto Sans KR) CDN.

---
제작: SIRIAI · 내부 콘텐츠 가이드 자료
