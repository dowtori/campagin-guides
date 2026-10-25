# 배포 자료 출처

- **나루터 따봉 조형물**: 이번 작업에서 직접 설계한 native Part 입체 조형물입니다. 외부 이모지 이미지나 모델을 사용하지 않았습니다. 생성 소스는 `pier_sculpture.py`입니다.

- **시리아이 로고·프로필 6장·설정 캡처**: 사용자가 이 작업에 제공한 기존 자료. 파일별 SHA-256은 `assets/provenance.json`에 기록합니다. 브랜드 이미지 생성으로 대체하지 않았습니다.
- **가상 크리에이터 게시물**: built-in image_gen으로 새로 생성한 3×3 사진 시트에서 잘라 사용했습니다. 생성 프롬프트는 `assets/generation-prompt.json`, 원본은 `assets/creator-contact-sheet.jpg`입니다. 실제 계정이나 실존 인물을 나타내지 않습니다.
- **자연물**: [Kenney Nature Kit](https://kenney.nl/assets/nature-kit), CC0 1.0. 원본 `assets/nature/kenney/License.txt`, 사용한 OBJ와 MTL을 포함합니다. 원본 형상을 실제 정점·면으로 가져옵니다. v6.1에서 잎·줄기·바위의 색을 해안 장면의 팔레트에 맞췄습니다.
- **바람**: [boatbomber/WindShake](https://github.com/boatbomber/WindShake), MIT. 커밋 `c2161ba08c1974fbb7716cb83b643097ba72f896`의 원본 구현을 `src/shared/ThirdParty/WindShake`에 포함했습니다. `WindShake-MIT.txt` 참조.
- **웹 공간 렌더러**: [Three.js](https://github.com/mrdoob/three.js), MIT. `vendor/THREE-LICENSE.txt` 포함.
- **글꼴**: Pretendard / Inter Tight, 각 OFL 라이선스를 `assets/`에 포함했습니다. 웹에 사용하며 Roblox 텍스트는 엔진 기본 글꼴을 사용합니다.

Fisch, Work at a Pizza Place, Bee Swarm Simulator는 플레이 구조와 공간 참고 자료입니다. 해당 게임의 모델·음악·캐릭터·썸네일은 이 배포물에 포함하지 않습니다. 구체적인 참고 범위는 `design-review.md`에 기록했습니다.
