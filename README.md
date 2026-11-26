# کبریت (Kebrit / "Matches")

A dark, candle-lit maze game for Android and iOS, built with plain Flutter
widgets and `CustomPainter` (no game engine). UI is Persian and right-to-left;
the game board itself is not mirrored. The implementation plan and per-phase
handoff log live in [PLAN.md](PLAN.md).

## Layout

| Path | Contents |
|---|---|
| `lib/game/` | Pure-Dart engine (no Flutter imports): grid, level, state, engine, hunter BFS, drag classifier |
| `lib/data/` | The 15 levels, progress, settings, repositories, Persian digit helpers |
| `lib/theme/` | Design tokens and text styles |
| `lib/ui/kit/` | Shared widgets and painters, CSS translation helpers (`css.dart`) |
| `lib/ui/screens/` | One folder per screen |
| `lib/app.dart`, `routes.dart`, `app_scope.dart` | App flow, services lookup, persistence wiring |
| `design_src/mobile/` | Read-only copies of the design's `.dc.html` files |
| `docs/golden_sweep.md` | Status of the design-reference comparison per screen |

## Running the tests

The Flutter SDK is not on PATH in every shell. On the development machine:

```powershell
$env:Path = "C:\src\flutter\bin;C:\src\git\cmd;" + $env:Path
```

Run one file at a time on small machines:

```powershell
flutter test test/unit/game -j 1
flutter test test/golden/title_test.dart -j 1 --no-pub
```

The full suite (`flutter test -j 1 --no-pub`, 222 tests) takes about 7 minutes
on one core. Before committing: `flutter analyze` and
`dart format --set-exit-if-changed lib test`.

## Goldens

Regression goldens live in `test/golden/goldens/` and were generated on
Windows Server 2019 (same OS as the test runs). They are platform-specific:
do not copy them between machines. To regenerate one file:

```powershell
flutter test test/golden/<name>_test.dart --update-goldens -j 1
```

Always open the changed PNGs and look at them before committing.

## Comparing against the design

`expectMatchesDesign` (in `test/helpers/design_compare.dart`) compares a
rendered screen to a PNG exported from Claude Design (4x box downscale, mean
difference <= 4 %, <= 1.5 % of blocks differing by > 25 %). It **skips** when
the reference file is missing.

To enable it, export the mobile boards at 390 px wide, @1x, into
`design_refs/mobile/` using these names: `0_Splash`, `0b_Benefits` (390x1960),
`1_Title`, `2_Tutorial_1` to `2_Tutorial_4`, `3_Levels`, `4_Game_lit`,
`4_Game_dark`, `5_Pause`, `6_Complete`, `7_Transition_<name>`, `8_Caught`,
`9_NoMatches`. Failures write `test/failures/<name>_{flutter,design,diff}.png`.

## Known gaps

- Levels 1-6 and 8-15 use generated **placeholder mazes** (only level 7 is from the design).
- Audio is a silent stub (`SilentSoundPlayer`); no assets or package chosen.
- The ember scoring rule is an assumption (`emberRule` in `lib/data/progress.dart`).
- The splash shows the placeholder studio name `[نام استودیو]`.
- No device or emulator run, and no Android/iOS build has been done; touch
  behaviour is only covered by widget tests.
