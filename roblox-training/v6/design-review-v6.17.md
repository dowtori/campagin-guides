# v6.17 acceptance criteria — before implementation

- Sheet recording offers one primary action, DM 발송으로 변경, then displays DM 발송 and allows completion. No six-option grid or unsupported dropdown glyph.
- Eligible visible pier thumb supports direct click plus native E/touch prompt; closed/basic-incomplete/king states do not activate it. Existing phone clicks remain deliberate.
- Thumb starts first unfinished advanced challenge. First completion of all three returns to a clear pier viewing spot and reveals existing 10x king. No extra score explanation or modal.
- Phone offers chapter reset and full reset. Confirm scope, cancel without mutation, retain other chapters on partial reset. Clear corresponding drafts, checks, records and reward; stale packets cannot restore prior completion.
- Desktop and small viewport native UI property review, exported Luau callback regressions and actual packaged source verification. Studio rendering, physics and live touch remain unverified on this host.

Implementation references: Roblox ClickDetector and ProximityPrompt official class documentation (create.roblox.com/docs/reference/engine/classes/ClickDetector; /ProximityPrompt).

## Result

- Passed exported-source callback checks: 15 reset/camera, 18 advanced server, 60 advanced client, 9,320 thumb stages/collision/entry checks; existing work, setup, mobile, chapter and world-water regressions passed.
- Reset tests cover cancellation, individual basic/advanced resets, retained other completion, first-screen draft restart, full clear, monotonic revisions/attempt serials, stale messages and forged scope rejection.
- Native UI property approximation: 164 screens at 1280×720, 1440×900, 390×844 and 844×390, zero detected layout audit errors. Shortened the reset confirmation further after screenshot review.
- Saved screenshot evidence: [single recording action](assets/review-v6.17/record-action.png), [changed sheet status](assets/review-v6.17/record.png), [chapter reset](assets/review-v6.17/reset.png). These are browser renders of native properties, not Roblox captures.
- The final first-clear server callback teleports to x=0,z=-326, outside the current thumb and giant bounds, clears the run and sends a view orientation request. Re-clearing an already earned challenge does not repeat the reward trip.
- The existing 10× giant geometry and collision guard remain unchanged. Resetting a chapter recalculates the visible reward from the remaining records.
- Native ProximityPrompt covers E/touch; direct hand ClickDetectors are enabled only on visible earned parts, and disabled while a work panel is open or the king is earned. No Tool.Activated or general left-click binding was added.

## Limits

Roblox Studio is unavailable on this host. Actual font fallback, equipped-tool click routing, camera replication timing, mobile touch, physics and multiplayer play remain unverified. The literal ▾ glyph at the photographed cell was removed; an engine-specific font diagnosis has not been confirmed. This release is a review build, not a claimed live-game play test.
