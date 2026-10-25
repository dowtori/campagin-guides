# v6.12 — celebration and solid-object criteria (before implementation)

## Decision
Keep the thumb silhouette and palette. Its humour has not been demonstrated; do not label this release a successful absurd/comic redesign. Remove the floating thumbnail and stage-name toast. Prefer a quiet completion treatment; the optional confetti preference is pending.

## Acceptance
- A newly completed basic action has one acknowledgement, in the existing dialog header or objective HUD, for 1.5 seconds. The next action stays usable. No extra popup/thumbnail/toast.
- All seven unique completions produce one centered, content-sized finish card: a check, “첫 캠페인 완료”, “나루터로 가기”, and “챕터 선택”. No automatic teleport, scores, redundant reward prose or replay celebration.
- Only the visible thumb stage and its pedestal collide. Hidden stages cannot create invisible walls. Growth never replaces collision around an avatar standing beside/on the sculpture; wait until the local avatar clears its full growth area.
- Solid architecture, furniture, monitors, physical boards, rock surfaces and tree bark collide with their visible shape. Water, grass, leaves, labels painted on a surface and interaction volumes stay passable.
- The required route, reward arrival and water access stay open. No added broad box colliders.
- Inspect exported properties and exercise all eleven reward states, replay, transitions and completion navigation. Review the two new screen compositions at desktop and mobile sizes.

## Limits
Roblox Studio is unavailable on this host. Exported-property tests and browser UI approximations do not prove engine physics, multiplayer or rendered play. Report that limitation explicitly; actual Studio traversal remains required.

## References
- https://create.roblox.com/docs/workspace/collisions
- https://create.roblox.com/docs/reference/engine/classes/BasePart

## Verification result
- Exported Luau: full existing client/server/gameplay suites pass; 12 completion lifecycle checks and 8,694 reward-state checks pass. No detached reward viewport or notice callback remains.
- Actual exported place: 129,746 collision assertions pass, including physical source-model properties, 46 original rock/tree meshes, two lateral surface rays per model, source/export equivalence and hidden-NPC/soft-surface exclusions.
- All eleven hand shapes remain grounded and inside the pier bounds. The existing 133-stud required route remains clear under the corridor sampler.
- Browser approximation: 152 native-property screens across 1280×720, 1440×900, 390×844 and 844×390 report no measured overflow. Inspected the finish card and same-place acknowledgement. This is not an in-game screenshot.
- Existing water, coast, terrain and lighting configuration tests pass. No natural-environment appearance redesign in this release.
- No extra collision boxes were added. 9,636 existing original rock/bark facets now collide; native solver cost and low-end frame rate still require Studio/device measurement.
- Pending spatial preference: bringing the advanced pavilion closer to the main route versus retaining the right-hand open view. No building relocation is included before resolving that interpretation.
- Quiet celebration is the default used while the optional confetti preference remains unanswered.
