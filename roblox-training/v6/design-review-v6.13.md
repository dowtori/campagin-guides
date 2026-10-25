# v6.13 — correct the creator discovery workflow (before implementation)

## Source of truth
The user's correction and dm-partner-guide/#collect: open the reference brand's Tagged tab, inspect tagged content and account suitability, then use IG Lead Saver to save the author to the assigned campaign sheet. Local IG Lead Saver 1.4.0 src/content.js lines 1204–1367 confirms thumbnail author/follower badges and direct save; profile inspection is optional. The prior NPC selection experience replaced the actual job with an invented interaction.

## Acceptance
- Start on a reference brand account. The learner opens Tagged; do not start with a preselected creator profile.
- Display a scrollable tagged-post grid with content, author, follower count and the extension's Save state. Post and profile views are optional and return to the same grid.
- The basic exercise is a guided collection practice, not a three-answer quiz: two eligible sample authors, multiple posts each, no timer or unique correct choice. Suitability edge cases stay in the optional advanced game.
- Saving any listed author changes every post by that author to Saved and adds one visible sheet row with handle, actual followers, campaign and Contact not started status. Duplicate posts never add duplicate rows.
- Opening Tagged or inspecting content alone does not finish the chapter. At least one account must be saved, and the learner explicitly continues after seeing the result.
- DM, reply and settlement continue with the first collected author rather than a hardcoded NPC. Direct chapter entry retains an explicitly supplied sample.
- Remove basic creator NPCs and their photo-shoot props; use one physical collection PC at the existing second stop. Preserve optional answer NPCs and three-stop forward travel.
- Keep established type hierarchy and touch targets; no mandatory profile/history buttons or fabricated automatic suitability filtering in the extension.

## Verification
Exercise direct thumbnail saving, post/profile paths, multiple valid authors, duplicate saving, close/resume, chapter replay, and downstream account identity. Inspect exported geometry and UI at desktop/mobile widths. Studio is unavailable; native rendering/physics remains unverified.

## Results — 2026-10-26
- Exported-source discovery: 38 passing checks, including both direct and optional detail paths, duplicate author state, close/resume, invalid source rejection, and the selected account continuing through DM/reply/selection.
- Existing workflow/client/server/chapters/water/coast suites passed; final UI revision passed discovery and 459 dialog layout checks.
- 160 UI property snapshots across 1280×720, 1440×900, 390×844 and 844×390 were rendered in a browser approximation. Desktop saved-result layout and mobile Tagged grid inspected. Mobile criteria uses a deliberate line break. This is not a native Roblox screenshot.
- Map/export checks: 4 remaining NPCs (manager plus optional answer NPCs), 3 prompts, collection workstation, 133-stud required route. Collision audit: 129678 source/export assertions. The prior three creator NPCs and photo-shoot props are absent.
- No new asset source or external account connection was introduced. Training posts use the existing original practice assets.
- Native Studio rendering, actual thumb/fixture physics and multiplayer remain unverified because Studio is unavailable.
