# Golden sweep (Phase 12)

`design_refs/mobile/` **does not exist** (PLAN open question Q2: the boards have
not been exported from Claude Design). Every `expectMatchesDesign` call
therefore skips, and **no diff percentages could be measured**. Fidelity so far
rests on source-driven verification: each phase read the `.dc.html` CSS and
reviewed its own golden PNGs with `Read`.

Tolerances: mean difference <= 4 %, <= 1.5 % of 4x4-downscaled blocks differing
by > 25 %.

| Screen | Reference needed | Test | Diff % | Status |
|---|---|---|---|---|
| Splash | `0_Splash.png` | `splash_test` | n/a | skipped (no ref) |
| Benefits | `0b_Benefits.png` | `benefits_test` | n/a | skipped (no ref) |
| Title | `1_Title.png` | `title_test` | n/a | skipped (no ref) |
| Tutorial 1-4 | `2_Tutorial_1..4.png` | `tutorial_test` | n/a | skipped (no ref) |
| Levels | `3_Levels.png` | `levels_test` | n/a | skipped (no ref) |
| Game lit / dark | `4_Game_lit.png`, `4_Game_dark.png` | `game_view_test` | n/a | skipped (no ref) |
| Pause | `5_Pause.png` | `secondary_screens_test` | n/a | skipped (no ref) |
| Complete | `6_Complete.png` | `secondary_screens_test` | n/a | skipped (no ref) |
| Transition | `7_Transition_<name>.png` | `transition_test` | n/a | skipped (no ref) |
| Caught | `8_Caught.png` | `secondary_screens_test` | n/a | skipped (no ref) |
| No matches | `9_NoMatches.png` | `secondary_screens_test` | n/a | skipped (no ref) |

## Unverified deviations to re-check once references exist

- Caught: text block starts at 420 (design 470), headline line-height 1.25.
- No matches: text block starts at 430, headline scaled to one line.
- Levels: selection sheet line heights tightened so the CTA fits.
- Game: caught headline wraps to two lines at 44 px.
- Benefits: real content is about 2416 px, not the 1960 px board crop.

## Other Phase 12 checks

- Full suite: `flutter test -j 1 --no-pub` passed, 222 tests.
- `flutter analyze`: no issues.
- `dart format --set-exit-if-changed lib test`: the tree was not formatted; it was
  reformatted in this phase (whitespace only) and is now clean.
- Semantics: every interactive widget is a `PillButton`/`KToggle` or has an
  explicit Persian `Semantics` label; HUD and link tap areas are >= 44 px.
- Remaining markers in `lib/`: only the documented placeholder-maze generator.
