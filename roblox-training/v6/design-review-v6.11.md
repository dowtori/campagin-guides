# v6.11 — dialog UX acceptance criteria (set before implementation)

## Diagnosis
The v6.10 native WorkPanel uses 84% of the viewport even for one card or an empty choice screen. Its title always reserves 64 px. Body labels range from 12–20 px while every card value is bold. Four transparent text buttons conceal operational references; the first says “실제 업무 시작할 때” without indicating an action. Reply text is not identified as received vs outgoing. These are layout and interaction faults, not missing decoration.

## Pass criteria
1. Content-driven work dialogs: desktop width at most 560 px, outer safe margin at least 16 px, height bounded by viewport minus 32 px. Brief should be under 400 px at 1280×720; empty setup choice under 320 px. No arbitrary minimum body height.
2. One typography scale: title 30 bold, body 22 regular, supporting text 18 regular, labels 16 regular, actions 20 bold. Line height 1.2–1.25. No automatic shrinking to hide overflow. World SurfaceGui sizes remain separate because they use canvas pixels.
3. One obvious primary action in a fixed footer, secondary actions visibly styled. Close control at least 44×44. Remove all four disclosure buttons. Reference content is short static text or the existing completion-only appendix.
4. 20 px between content and footer; 12 px between body groups. No large blank region on brief, handoff, or completion choice. Scroll only the body when content exceeds available height; title and actions stay visible.
5. Every received / outgoing message has a role label. Fee and settlement amounts have clear hierarchy; retain operational facts from the group-chat audit.
6. Check every native dialog state: campaign brief; profile and extension steps 0–3, choice and handoff; all creator profiles/history; all DM steps; reply; settlement; help; appendix list and all ten entries; phone before/after completion; all optional NPC/scout cases.
7. At 1280×720, 1440×900, 390×844 and 844×390: no offscreen panel/footer, no obscured text or title/close overlap. Phone keeps its large chapter tiles and completion stamps. Mandatory workflow, resumability, optional challenge timing and payout remain unchanged.

## Verification boundary
Use the exported place's actual Luau for callback tests and UI property snapshots. Browser property renders are a typography/layout approximation with Pretendard, not Roblox engine screenshots. Studio is unavailable; do not report actual engine text rendering, play or device performance as verified.

## Inventory
CampusClient: ObjectiveHUD, toast, WorkPanel (brief / setup / discovery / DM / reply / settlement), phone, help, appendix.
AdvancedClient: condition board, three creator/NPC choice boards, challenge console and feedback states.
RewardClient: no dialogue text; preview must not cover mobile work dialogs.


## Results (2026-10-26)
- First dialog: 560×324 px; setup completion choice: 560×252 px in the 1280×720 property render. The v6.10 screenshot showed approximately 453×548 px despite little content.
- 144 native-property states (36 states × four viewports), 110 world-board states (all eight scenario variants, intro/active/answer/timeout), and 32 HUD/notice states reviewed. Browser checks reported no text overflow; dialog bounds and footer/heading separation also passed.
- Direct visual inspection: brief, inbound/outbound reply, both filled setup previews, compact completion choice, landscape DM scrolling, phone completion menu, mobile HUD and notice. The phone accessory row initially appeared clipped; it now groups challenge/appendix actions side by side and sizes desktop cards to available height.
- 459 native layout/event/callback assertions pass, including injected native text/content measurements, resize events, compact windows, fixed footer, medium-height window boundaries and the phone's two-action accessory row. All existing campaign/setup/phone/advanced/reward/server/water tests pass. Exported map geometry, required route, reward clearance and environment serialization checks pass.
- Two regular font roles and bold emphasis are implemented through Gotham / GothamBold with 1.2 line height in native text. The browser uses Pretendard as an approximation; its measurements are not claimed as exact Roblox fallback-font measurements.
- The existing seven-chapter workflow, company profile images, fee/selection rules, resumability, optional 30-second scout and untimed NPC answers are preserved.
- Native layout uses `UIListLayout.AbsoluteContentSize`, `TextLabel.TextBounds`, automatic text height and a bounded scrolling body. Reference: https://create.roblox.com/docs/reference/engine/classes/UIListLayout

## Remaining verification
Roblox Studio is not installed on this host. Actual engine pixel appearance, Korean fallback-font metrics, touch-device rendering and live gameplay are unverified. Public download verification checks that the delivered binary/ZIP match the tested export; it does not publish the place into a Roblox experience.
