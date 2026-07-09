# campaign-guides

SIRIAI 인플루언서 협업 콘텐츠 가이드 모음. 각 캠페인은 하위 폴더의 정적 사이트(단일 `index.html` + `assets/`)로 구성됩니다.

## 가이드 목록

| 캠페인 | 형식 | 경로 |
|---|---|---|
| 제니 유럽 사복 · 젠민수 아이템 | 블로그 / 패션 | [`jennie-europe/`](jennie-europe/) |

루트 [`index.html`](index.html) 은 전체 가이드 인덱스입니다.

## 로컬에서 보기

```bash
python -m http.server 4599
# → http://localhost:4599            (인덱스)
# → http://localhost:4599/jennie-europe/   (제니 가이드)
```

## GitHub Pages

Settings → Pages → Branch `main` / `/root` 로 배포하면
`https://<user>.github.io/campaign-guides/` 에서 인덱스가, `.../jennie-europe/` 에서 개별 가이드가 열립니다.

## 스택

정적 HTML/CSS/JS (빌드 불필요). 폰트는 Google Fonts(Instrument Sans, Noto Sans KR) CDN.

---
제작: SIRIAI · 내부 콘텐츠 가이드 자료
