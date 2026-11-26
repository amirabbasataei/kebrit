# کبریت (Kebrit / "Matches") — Flutter implementation plan

Status: **DRAFT — awaiting approval.** No app code exists yet. This file is the only output of the planning session.

---

## 0. What the design is (inventory)

**Source:** Claude Design artifact "Maze Gameplay — Visual Styles" — https://claude.ai/artifact/A8SJnPHQg2cjFGbrVqCeTs (owner: user, 56 files, no comment threads, **no design system attached**). The other artifact, "Untitled" (…2GaZWPBDpMvzdZqEphZJwA), is an empty design canvas and was ignored.

The canvas has two pages:

| Page | Content | Status in this plan |
|---|---|---|
| **Mobile** (390×844, Persian, RTL) | 11 screens + a roadmap board | **THE TARGET.** Looks like the real, current design. |
| Desktop "first pass" (1280×800, English) | 3 visual directions for the gameplay screen (A *Ember & Stone*, B *Moonlit Diorama*, C *Pixel Crypt*) + Title, LevelSelect, LevelComplete, Transition, Pause, Caught, OutOfMatches | **Out of scope** (assumed superseded; style A "Ember & Stone" was clearly chosen — the mobile set reuses it). Listed in Open questions Q1. |

Files to read per screen (all under `project/` in the artifact; fetch with `Artifact action:"read_file" url:<above> paths:[...]`):

| # | Board | File | Size | Notes |
|---|---|---|---|---|
| 0 | Splash | `MSplash.dc.html` | 390×844 | Animated intro (match ignites, "کبریت" logo, fuse loader 2.4 s, "tap to start"). Tap → Benefits. |
| 0b | Why Kebrit? (first launch) | `MBenefits.dc.html` | 390×**1960** (scrolls) | Hero + 3-step "see/remember/decide" + 8 benefit cards + disclaimer + 2 CTAs. |
| 1 | Title | `MTitle.dc.html` | 390×844 | Continue (L7), Tutorial, Levels, Settings→Pause. |
| 2 | Tutorial | `MTutorial.dc.html` | 390×844 | 4 steps, each with its own looping 4 s mini-animation. Skip / Back / Next. |
| 3 | Level select | `MLevels.dc.html` | 390×844 | 3 chapters × 5 levels, selection bottom sheet. |
| 4 | **Gameplay** | `MGame.dc.html` | 390×844 | The only file containing real game logic (see §0.2). |
| 5 | Pause + settings | `MPause.dc.html` | 390×844 | Blurred maze, 4 toggles, Continue/Restart/Tutorial/Levels. |
| 6 | Level complete | `MComplete.dc.html` | 390×844 | Door glow, 2/3 embers, 3 stats, next-level teaser. |
| 7 | Next-level transition | `MTransition.dc.html` | 390×844 | 9 s looping cinematic (door opens → walk → white flood → black → title card → match strike). |
| 8 | Game over · caught | `MCaught.dc.html` | 390×844 | Hunter with blinking eyes, hint box. |
| 9 | Game over · out of matches | `MNoMatches.dc.html` | 390×844 | Burnt match + smoke. |
| – | Roadmap | `Roadmap.dc.html` | 1280×1040 | Product roadmap (Unity/Godot mentioned — superseded by Flutter). Context only. |
| – | `canvas.json` | | | Board order + coordinates. Flow order = Splash → Benefits → Title → … |

Read `Main.dc.html` (desktop A) only if a detail is missing; `MGame` supersedes it.

### 0.1 Visual language (design tokens to put in `lib/theme/`)

No formal design system exists, so tokens are extracted from the HTML. Everything is a dark "candle-lit stone cellar".

**Colors (hex):**
- Backgrounds: `#0a0706` (page), `#070504` (splash/deep), `#070404` (caught), radial `#1e1611→#0a0706` (tutorial/levels), `#1c140f→#0a0706` (game).
- Stone: floor `#2a211b`, wall top gradient 165° `#6e5a48→#55453a` / `#655243→#4d3f35` / `#74604d→#5a493c` (3 shades picked by `(r*7+c*3)%3`), wall front `#2e231b`, dungeon-wall-tile bg `#3a2d24→#1e1712`.
- Text: primary `#efe3d0`, heading `#f3e6d2`/`#f6ead6`/`#fbf0de`, muted `#bfa688`, dim `#a48d72`, dimmer `#8f7a64`, body `#cdb89c`, serif-sub `#d8c4a6`.
- Accent (flame): `#ffb45a`, `#ff8a2b` (primary button gradient `#ffb45a→#ff8a2b`), `#ffd27a`, deep `#ff6a12`, ember red `#c8402e`.
- Danger: `#ff5a2e`, `#ff7a5a`, `#ff4a2a` (hunter eyes lit), `#5a2a1e` (eyes dormant).
- Match stick `#e0c393`, head `#c8402e`.

**Typography (all Google Fonts, must be bundled — see Phase 0):**
- `Vazirmatn` 400/500/600/700 — UI text (11–17 px).
- `Noto Naskh Arabic` 500/600/700 — headings & numerals-in-display (20–64 px, line-height 1.5).
- `Lalezar` 400 — logo (112 px splash, 104 px title) + eyebrow labels.
- All digits rendered **Persian (۰۱۲۳۴۵۶۷۸۹)** via the `fa()` helper.

**Layout:** 390×844 portrait, side gutters 24 (16 in game HUD), pill buttons radius = height/2, heights 60/58/56/52/50/48/44. Touch targets ≥ 44. Bottom sheet radius 24, bg `#241b15→#120d0a`, 1 px top border `rgba(239,227,208,.12)`. RTL everywhere (`Directionality.rtl`, `fa` locale) — **but the game board itself is not mirrored** (grid x = column).

**Motion (all in the design as CSS keyframes):** flame flicker (scale+rotate, 0.35–0.4 s alternate), light overlay flicker (opacity 1.3 s), splash ignite/spark/fuse, tutorial 4 loops, level-select "current" glow pulse, transition 9 s timeline, caught eye-blink + loom, no-matches ember pulse + smoke. `prefers-reduced-motion` and the in-game "reduce flicker" toggle disable flicker.

### 0.2 Game rules / mechanics (extracted from `MGame.dc.html` script — this is the spec)

- **Board:** 9 cols × 13 rows, cell 40 px, drawn in a 360×520 box at (15,150). 2.5D look: each wall cell = 40×40 top face + 12 px "front" face below it, z-sorted by row (`z = row*10+5`; entities `row*10+6`).
- **Map (level 7)** (`#` wall, `E` exit in the top wall, `.` floor):
  ```
  ####E####
  #.......#
  #.#.#.#.#
  #.#...#.#
  #.###.#.#
  #...#...#
  ###.#.###
  #...#...#
  #.###.#.#
  #.#...#.#
  #.#.###.#
  #.......#
  #########
  ```
  Player start (1,11); hunters start (7,4) and (3,9); match pickup at (1,7) = **+2 matches**, one-time.
- **Input:** touch/drag anywhere (no stick base position fixed). First touch point = joystick origin; knob clamp 30 px; dead-zone 16 px; dominant axis chooses one of 4 directions; the direction fires a step immediately on change, then repeats every **170 ms** while held. HUD buttons stop propagation. Joystick ring 80 px + knob 36 px drawn at touch origin.
- **Light / match:** Level starts **dark** with **6** matches (level-7 mock). Strike: only when not already lit and matches > 0 → matches−1, burn = 100. Burn ticks every **100 ms** by **1.25** (= 8 s). At 0 the flame goes out. Strike button shows remaining seconds while lit (conic ring).
- **Visibility:** lit → radial light around player, radius `R = 200 + 6.5·burn` px (stops 0 / .3R / .72R / R); dark → almost black (visible radius ~48 px, α .985). Warm flicker layer radius `180 + 3·burn`. Door glows (opacity .8 dark, .25 lit).
- **Hunters:** stand still while dark (eyes dim). While lit they **chase**: every **9th tick (900 ms)** each hunter takes one BFS step toward the player over floor cells (exit cell treated as blocked). Alert "!" bubble over hunters while lit. **Caught** = a hunter steps onto the player's cell, or the player steps onto a hunter.
- **Win:** player steps into the `E` cell → "در را پیدا کردی." overlay → Level Complete. **Lose (caught)** → overlay → Caught screen. **Lose (out of matches)**: dark + matches 0 → a link "کبریت تمام شد — تسلیم می‌شوی؟" → NoMatches screen.
- **Hints (Persian strings)** per state: pre-start / lit / dark-with-matches / no-matches (see file).
- **Level table** (matches, hunters) for 15 levels in `MLevels`: L1–5 (12,11,10,9,8 matches; 0 hunters), L6 (7;1), L7 (6;2), L8 (5;3), L9 (5;3), L10 (4;3), L11 (4;4), L12 (4;4), L13 (3;4), L14 (3;5), L15 (2;5). Names and chapters (خانه‌ی کهنه / سرداب‌ها / دخمه‌ها) are in the file. Mock state: current = 7, levels < 7 done, ember stars for done levels derived from `r` column (3,3,2,3,2,1).
- **Settings (toggles on Pause):** sound, haptics, reduced flicker, left-handed strike button (mirror the 92 px strike button to left).

---

## 1. Architecture

**Rendering approach:** pure Flutter widgets + `CustomPainter` (no game engine, no Flame). The design is mostly gradients, rounded rects and radial overlays — all of which map 1:1 onto `Container/BoxDecoration`, `CustomPainter`, `RadialGradient`, `SweepGradient` (CSS `conic-gradient`), `ImageFiltered` (blur), `ClipPath` (clip-path polygon) and implicit/explicit animations. A game engine would add a dependency and make goldens harder.

**State management:** Flutter's built-in `ChangeNotifier`/`ValueNotifier` + `ListenableBuilder`, with a tiny `InheritedWidget` ("`AppScope`") for service lookup. Reason: the game is a single small state machine; Riverpod/Bloc would add dependencies and boilerplate for no gain, and plain notifiers are trivial to unit-test.

- **Game logic is pure Dart, no Flutter imports** (`lib/game/`): immutable `GameState`, `GameEngine` with `step(dir)`, `strike()`, `tick()` (100 ms) — deterministic, no timers inside. A `GameController extends ChangeNotifier` owns a `Ticker`/fake-able clock and calls the engine. Tests drive time manually.
- Navigation: plain `Navigator` with named routes + a `FadeRoute`; screen widgets take their data/callbacks as constructor args so every screen is golden-testable in isolation.
- Persistence: `shared_preferences` behind a `ProgressRepository` interface (in-memory fake for tests; `SharedPreferences.setMockInitialValues` also works).

**Packages (kept minimal):**
- `flutter_localizations` (SDK) — `fa` locale / RTL defaults.
- `shared_preferences` — progress & settings.
- dev: `flutter_test` only (custom golden comparator written by hand; no `golden_toolkit`, no `image` package).
- Deferred (decision needed, Q9): an audio package. Not added before the final phase.

**Folder layout**
```
dark/
  pubspec.yaml  analysis_options.yaml  PLAN.md
  assets/fonts/            Vazirmatn-{Regular,Medium,SemiBold,Bold}.ttf, NotoNaskhArabic-{Medium,SemiBold,Bold}.ttf, Lalezar-Regular.ttf (+ OFL license files)
  design_src/mobile/       copies of the M*.dc.html design files (read-only reference, committed)
  design_refs/mobile/      reference PNGs exported from Claude Design (see §3)
  lib/
    main.dart  app.dart  routes.dart
    theme/    tokens.dart  text_styles.dart  app_theme.dart
    game/     grid.dart  level.dart  game_state.dart  game_engine.dart  hunter_ai.dart  game_config.dart
    data/     levels.dart (15 levels + maps)  progress.dart  progress_repository.dart  settings.dart
    ui/kit/   fa_digits.dart  pill_button.dart  flame.dart  match_icon.dart  ember_icon.dart  stone_wall.dart  light_overlay.dart  stone_bg.dart  sheet.dart
    ui/screens/  splash/ benefits/ title/ tutorial/ levels/ game/ pause/ complete/ transition/ caught/ no_matches/
    services/ haptics.dart  audio.dart (stub)
  test/
    helpers/   golden_harness.dart  design_compare.dart  fonts.dart
    unit/ …    widget/ …    golden/ …  (+ test/golden/goldens/*.png)
```
`package name`: `kebrit`.

---

## 2. Dependency graph

```
P0 scaffold+harness
 ├─► P1 game engine (pure Dart) ─► P2 levels+progress+settings (data)
 └─► P3 UI kit ─┬─► P4 Splash+Benefits
                ├─► P5 Title+Tutorial
                ├─► P6 Level select  (needs P2)
                ├─► P7 Game board render (needs P1) ─► P8 Gameplay interaction
                ├─► P9 Pause/Complete/Caught/NoMatches (needs P2; P7 for blurred maze)
                └─► P10 Transition animation
P2,P4,P5,P6,P8,P9,P10 ─► P11 App flow + persistence + haptics/audio
P11 ─► P12 Integration, golden sweep, cleanup
```
P1 and P3 can be done in either order after P0. Order recommended: 0,1,2,3,4,5,6,7,8,9,10,11,12.

---

## 3. Golden-testing strategy

Only `flutter test` is available (no device/emulator), so goldens are the visual safety net.

1. **Surface:** every screen test sets `tester.view.physicalSize = Size(390,844)`, `devicePixelRatio = 1.0` (cheap on 1 core; the Benefits screen uses 390×1960). Text scale 1.0, `Directionality.rtl`, locale `fa`, `debugDisableShadows = false`.
2. **Fonts:** Flutter tests default to the Ahem (boxes) font. `test/helpers/fonts.dart` loads the bundled TTFs from `assets/fonts` with `FontLoader` in `setUpAll` **before** any golden, with the same family names as `pubspec.yaml`. Static weight files only (variable-font axes are unreliable in the test engine). If a golden shows boxes, the harness is wrong — Phase 0 has a canary test for this.
3. **Time freezing:** animated screens accept an `AnimationController`/`progress` or take the "clock" from the test (`tester.pump(Duration)`); goldens are taken at **named timestamps** (e.g. Splash @ 3.4 s settled; Transition @ 0.5/2.5/4.0/6.0 s; Tutorial steps at t = 1.5 s). Infinite flicker is pinned (tests pass `reduceFlicker: true` or a fixed phase).
4. **Two kinds of golden:**
   - **Regression goldens** (`test/golden/goldens/<screen>[_state].png`): generated with `flutter test --update-goldens` **on this machine (Windows Server 2019, same OS that CI-equivalent runs happen on)**, committed, compared with `matchesGoldenFile` using Flutter's default comparator. Never regenerate without looking at the image (Claude `Read`s the PNG to review).
   - **Design-reference comparison** (`design_compare.dart`): renders the screen and compares it to `design_refs/mobile/<Board>.png` with a **custom perceptual comparator**: both images downscaled 4× (box filter), per-pixel RGB distance, pass when **mean difference ≤ 4 %** and **≤ 1.5 % of blocks differ by > 25 %** (initial values; each phase may tune them once and records the final numbers in the test and in handoff notes). Differences are expected because CSS and Skia rasterize blur, gradients and text differently. On failure the comparator writes `test/failures/<name>_{flutter,design,diff}.png` which Claude reads to judge. Screens whose reference is a moving animation are compared only at the named frame; if no matching frame exists the comparison is skipped and recorded in the handoff.
5. **Exporting references:** I cannot render the Claude Design artifact headlessly here. The user exports the mobile boards as PNG (390 px wide, @1x; the Benefits board 390×1960) from the Claude Design canvas into `design_refs/mobile/` using the names `0_Splash.png, 0b_Benefits.png, 1_Title.png, 2_Tutorial_1..4.png, 3_Levels.png, 4_Game_lit.png, 4_Game_dark.png, 5_Pause.png, 6_Complete.png, 7_Transition_<t>.png, 8_Caught.png, 9_NoMatches.png`. Until a reference exists, the phase falls back to *source-driven verification*: the implementer re-reads the `.dc.html`, and `Read`s its own golden to check layout numbers manually; the design-compare test is added as `skip:` with a reason. (Open question Q2.)
6. **Platform lock:** goldens are produced and verified only on this OS. A header comment in each golden test states the OS; do not copy goldens between machines.
7. **Non-golden tests** carry the logic weight: unit tests (engine, BFS, level data, persian digits), widget tests (taps, drag → direction, toggles, navigation) using `tester.pump`.
8. **Performance on 1 core:** run one test file at a time (`flutter test <file> -j 1`), prefer `--no-pub` after Phase 0, never run the whole suite except in Phase 12. Skip `flutter analyze` on whole tree until each phase's end (`flutter analyze lib test` once).

First command of **every** session (PATH is not set in the Claude Code shell):
```powershell
$env:Path = "C:\src\flutter\bin;C:\src\git\cmd;" + $env:Path
Set-Location C:\Users\Administrator\Documents\dark
```

---

## 4. Phases

Conventions: each phase is one Claude Code session (~1–3 h). "Design file(s)" are fetched from the artifact `https://claude.ai/artifact/A8SJnPHQg2cjFGbrVqCeTs` with `Artifact action:"read_file"` (or from `design_src/mobile/` after Phase 0). Every phase ends with `flutter analyze lib test` clean and a commit.

---

### Phase 0 — Scaffold, tokens, fonts, golden harness

1. **Goal:** a compiling empty Flutter app with the theme tokens, bundled fonts and a working golden-test harness proven by a canary test.
2. **Scope:** project creation, pubspec, theme/tokens, font assets, `design_src/` copies, harness (`fonts.dart`, `golden_harness.dart`, `design_compare.dart`), canary golden. **Excluded:** any screen or game logic.
3. **Inputs:** `Roadmap`/`canvas.json` not needed; read `MTitle.dc.html` (token reference). Prior phases: none. Needs internet to download fonts/pub packages.
4. **Files:** `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/theme/{tokens,text_styles,app_theme}.dart`, `assets/fonts/*`, `design_src/mobile/*.dc.html`, `test/helpers/*`, `test/golden/canary_test.dart`, `.gitignore`, `README` snippet in this file's handoff.
5. **Tasks**
   - [ ] Set PATH (see §3). `git init`. `flutter create --org ir.kebrit --project-name kebrit --platforms=android,ios .` (no Windows/web). Remove the default counter test/app. Do **not** run `flutter run`/`build`.
   - [ ] Add `flutter_localizations`, `shared_preferences`; run `flutter pub get` once.
   - [ ] Download fonts (static TTFs, OFL) into `assets/fonts/` from the Google Fonts GitHub repo (`google/fonts` — Vazirmatn is in `rastikerdar/vazirmatn`); declare families `Vazirmatn` (w400/500/600/700), `NotoNaskhArabic` (w500/600/700), `Lalezar` (400) in pubspec; include license files.
   - [ ] Fetch all `project/M*.dc.html` + `canvas.json` into `design_src/mobile/` (plain copies; used by later sessions offline).
   - [ ] `tokens.dart`: all colors/gradients/radii/spacings from §0.1; `text_styles.dart`: named styles (logo, h1-serif, caption, body, button…) with line-height 1.5 for Naskh.
   - [ ] `app.dart`: `MaterialApp` (or `WidgetsApp`) with `locale: fa`, RTL delegates, dark theme, `debugShowCheckedModeBanner:false`, placeholder home.
   - [ ] `fonts.dart`: `loadAppFonts()` using `FontLoader` from `File('assets/fonts/...')`.
   - [ ] `golden_harness.dart`: `pumpScreen(tester, widget, {size, dpr, clockAt})`, `expectGolden(finder, name)`, wrapped in RTL/fa/theme.
   - [ ] `design_compare.dart`: `expectMatchesDesign(tester, finder, refPath, {meanTol=0.04, blockTol=0.015})` per §3.4, writes failure images, skips cleanly when the ref file is missing.
   - [ ] Canary test: a widget showing "کبریت" (Lalezar), a Naskh heading and Persian digits; golden + assert text paints (not Ahem) by checking the golden was generated with non-uniform glyphs (visual check by Claude).
6. **Verification:** `flutter test test/golden/canary_test.dart --update-goldens -j 1` then `flutter test test/golden/canary_test.dart -j 1` (second run must pass without update). Claude `Read`s `test/golden/goldens/canary.png` and confirms real Persian glyphs (no boxes). `flutter analyze lib test` clean. Done = canary green twice, git committed.
7. **Handoff notes:** record the font file names actually used, the final harness API signatures, the `expectMatchesDesign` default tolerances, whether `design_refs/` exists yet, Flutter/Dart versions in use.
8. **Starting prompt:**
   > Read `C:\Users\Administrator\Documents\dark\PLAN.md` (sections 0–3 and Phase 0). Implement **Phase 0 only**: scaffold the Flutter project `kebrit` in the current directory, add pubspec deps, bundle the fonts, copy the design sources to `design_src/mobile/` (Artifact `read_file` on https://claude.ai/artifact/A8SJnPHQg2cjFGbrVqCeTs), write theme tokens from PLAN §0.1, and build the golden harness + canary test. First set PATH: `$env:Path = "C:\src\flutter\bin;C:\src\git\cmd;" + $env:Path`. Machine has 1 core: run only the single canary test file with `-j 1`. Do not build apps. Finish with the verification in the plan, commit, and update the Handoff block of Phase 0 in PLAN.md.

---

### Phase 1 — Core game engine (pure Dart, no UI)

1. **Goal:** a deterministic, fully unit-tested implementation of the rules in §0.2.
2. **Scope:** grid/map parsing, level model, player movement, strike/burn, pickups, hunter BFS chase, caught/escaped/out-of-matches detection, a drag-to-direction classifier. **Excluded:** widgets, timers, persistence, level data other than the level-7 map (kept as a test fixture).
3. **Inputs:** `MGame.dc.html` (script block). Requires Phase 0.
4. **Files:** `lib/game/{game_config,grid,level,game_state,game_engine,hunter_ai,drag_input}.dart`; `test/unit/game/*_test.dart`.
5. **Tasks**
   - [ ] `GameConfig`: `cellSize=40`, `tickMs=100`, `burnPerTick=1.25`, `hunterEveryTicks=9`, `stepMs=170`, `deadZone=16`, `knobMax=30`, `matchSeconds=8`.
   - [ ] `Grid.parse(List<String>)`: cells wall/floor/exit/start/hunter/pickup markers; `isWall`, bounds-safe.
   - [ ] `Level` (id, name, chapter, startMatches, grid, playerStart, hunterStarts, pickups).
   - [ ] `GameState` (immutable; px,py, hunters, matches, burn, lit, pickedUp set, `result` enum {playing, escaped, caught, outOfMatches}, tick counter, stats: matchesStruck, elapsed ticks, steps).
   - [ ] `GameEngine.strike()`, `.tick()` (burn, hunter step every 9th tick only while lit, flame-out), `.step(Dir)` (walls, exit, pickup +2, caught-by-stepping-onto-hunter), `outOfMatches` rule = dark & matches==0 & not finished (player may "give up" — emitted as state flag, not auto-lose).
   - [ ] `HunterAi.nextStep(grid, from, target)`: BFS with exit blocked, same tie-break order as the JS `[[1,0],[-1,0],[0,1],[0,-1]]`, unreachable → stay.
   - [ ] `DragClassifier`: given origin + pointer → `{direction?, knobOffset}` per dead-zone/clamp rules.
   - [ ] Unit tests port every rule incl. edge cases: strike while lit is a no-op; strike with 0 matches no-op; hunters frozen when dark; catch on both sides; pickup once; exit stops engine.
6. **Verification:** `flutter test test/unit/game -j 1` all green; coverage not required but each rule above has a named test. Done = green + analyze clean + commit.
7. **Handoff notes:** public API of `GameEngine`/`GameState`, enum names, how stats are exposed (needed by Complete/Caught screens: matches left, elapsed time, distance-to-door in steps via BFS helper `stepsToExit`).
8. **Starting prompt:**
   > Read PLAN.md sections 0.2 and Phase 1, plus the script in `design_src/mobile/MGame.dc.html`. Implement Phase 1: the pure-Dart engine under `lib/game/` with thorough unit tests under `test/unit/game/`. No Flutter imports in `lib/game`. Run tests one directory at a time with `-j 1`. Update the Phase 1 handoff block when done and commit.

---

### Phase 2 — Level catalogue, progress and settings (data layer)

1. **Goal:** all 15 levels as data, plus persistent progress (unlocks, best embers) and the four settings.
2. **Scope:** `levels.dart`, `Progress`, `AppSettings`, `ProgressRepository` (+ `SharedPreferences` impl & in-memory fake), ember scoring rule, unlock rule, "continue" pointer. **Excluded:** UI.
3. **Inputs:** `MLevels.dc.html` (names, chapters, matches/hunters table), `MPause.dc.html` (settings keys), `MComplete.dc.html` (stats). Requires Phase 1. **Blocked by decisions** Q3 (level maps), Q4 (ember rule) — see Open questions; implement the assumed defaults and keep them isolated.
4. **Files:** `lib/data/{levels,progress,progress_repository,settings}.dart`, `test/unit/data/*`.
5. **Tasks**
   - [ ] Define all 15 `LevelMeta` (number, Persian name, chapter index, matches, hunters count). Level 7 uses the real map; levels 1–6 and 8–15 get **placeholder maps** produced by a small deterministic generator or hand-written mazes (decision Q3), marked `// PLACEHOLDER`, each validated solvable by a test (BFS from start to exit).
   - [ ] `Progress`: `currentLevel`, `Map<int,int> embers (0–3)`, `isUnlocked(n)` (= n ≤ current), `complete(n, embers)` (advances current).
   - [ ] Ember rule (assumed): 3 = finish using ≤ ⌈start/3⌉ strikes... *(replace with the user's answer to Q4)*.
   - [ ] `AppSettings {sound, haptics, reduceFlicker, leftHanded}` with defaults from the design (sound on, haptics on, others off).
   - [ ] `ProgressRepository` interface + `PrefsProgressRepository` (JSON in one key) + `InMemoryProgressRepository`.
   - [ ] Persian formatting helpers moved here/kit: `fa(int)`, `faTime(Duration)` ("۱:۴۲").
6. **Verification:** `flutter test test/unit/data -j 1` green incl. "every level solvable", "level 1 unlocked on fresh install", "round-trip save/load". Done = green + commit.
7. **Handoff notes:** which levels have placeholder maps, final ember rule, repository API used by later screens.
8. **Starting prompt:**
   > Read PLAN.md (§0.2, Phase 2, Open questions Q3/Q4). Implement Phase 2 (data layer) using the table in `design_src/mobile/MLevels.dc.html`. Use placeholder mazes for levels other than 7 unless I told you otherwise, and test that each is solvable. Run `flutter test test/unit/data -j 1`. Update Phase 2 handoff and commit.

---

### Phase 3 — UI kit (shared widgets & painters)

1. **Goal:** every reusable visual primitive from the design as a golden-tested widget.
2. **Scope:** `StoneBackground` (grid-line wall bg), `PillButton` (primary gradient / outline / text variants), `Flame` (flicker, pausable), `MatchIcon`/`MatchStick`, `EmberIcon` (lit/unlit), `StoneWall` cell painter (top + front face + 3 shades), `LightOverlay` (CSS-style radial gradient with px stops), `WarmFlicker`, `FaText` digit helper, `BottomSheetPanel`, `DoorGlow`, toggle switch. **Excluded:** full screens.
3. **Inputs:** `MTitle`, `MLevels`, `MGame`, `MPause`, `MComplete`. Requires Phase 0.
4. **Files:** `lib/ui/kit/*`, `test/widget/kit/*`, `test/golden/kit_*_test.dart`.
5. **Tasks**
   - [ ] CSS→Flutter translations (documented in file headers): `radial-gradient(circle at x y, stop px…)` → `RadialGradient(center, radius=R, stops=px/R)`; `conic-gradient` → `SweepGradient` (start −90°); `clip-path: polygon` → `ClipPath`; `box-shadow` → `BoxShadow` list; `filter: blur` → `ImageFiltered`.
   - [ ] `Flame`: gradient shape `BorderRadius.elliptical` 62%/38%, glow shadow, optional flicker via controller (reduce-flicker aware).
   - [ ] `PillButton`: heights 60/58/56/52/50/48/44, primary gradient + glow, outline (border `rgba(239,227,208,.26)`), text link; focus/pressed states.
   - [ ] `StoneWallCell` / `MazeWallsPainter` signature that Phase 7 will reuse.
   - [ ] Toggle row matching MPause (48×28 track, 22 knob).
   - [ ] Goldens: one "kit sheet" per group (buttons, flame sizes, match/ember icons, wall cells, overlay lit/dark).
6. **Verification:** `flutter test test/widget/kit test/golden/kit_buttons_test.dart ... -j 1` (run each file separately); goldens reviewed against the corresponding regions of design refs (e.g. 1_Title buttons) via `expectMatchesDesign` on cropped regions if refs exist, else by visual comparison of the `Read` PNG with the HTML values. Done = green, analyze clean, commit.
7. **Handoff notes:** public widget APIs, translation helpers, any CSS feature that couldn't be matched (e.g. `inset` shadows) and the substitute used.
8. **Starting prompt:**
   > Read PLAN.md §0.1, §3 and Phase 3. Build the shared UI kit under `lib/ui/kit/` with widget tests and golden tests, translating CSS from `design_src/mobile/*` precisely (see Phase 3 translation notes). One test file per run, `-j 1`. Review every generated golden PNG with Read before accepting it. Update Phase 3 handoff, commit.

---

### Phase 4 — Splash + "Why Kebrit?" (first-launch) screens

1. **Goal:** the intro animation and the long scrolling benefits page, pixel-faithful.
2. **Scope:** `SplashScreen` (ignite, sparks, flicker, fuse loader, tagline, tap-to-start pulse; tap → next), `BenefitsScreen` (390×1960 content in a `SingleChildScrollView`, 8 benefit cards from the item table, 3-step diagram with dashed connectors, disclaimer, CTAs). **Excluded:** routing logic (just callbacks `onStart`, `onPlay`, `onTutorial`).
3. **Inputs:** `MSplash.dc.html`, `MBenefits.dc.html`; Phase 3.
4. **Files:** `lib/ui/screens/splash/*`, `lib/ui/screens/benefits/*`, `lib/ui/screens/benefits/benefit_items.dart` (8 items with SVG icon paths → `Path` via `parseSvgPathData`-equivalent written by hand or `CustomPainter` strokes), tests.
5. **Tasks**
   - [ ] Splash timeline as one `AnimationController` (≈ 3.4 s) with `Interval`s matching CSS delays (sparks .4–.9 s, ignite .5 s, glow .6 s, logo 1.2 s, tagline 1.8 s, loader 0.2–2.6 s, tap hint 2.9 s).
   - [ ] SVG icons: implement a small SVG-path-data parser (M/L/H/V/C/S/Q/A/Z, relative variants) in `lib/ui/kit/svg_path.dart` **or** convert the 8+3 icons to `Path` code by hand — decide based on effort (avoid adding `flutter_svg`).
   - [ ] Benefits page layout with exact paddings; text uses Persian digits (۰۱–۰۸).
   - [ ] Goldens: Splash @ 0.3 s, 1.0 s, 3.4 s; Benefits full 390×1960 (and a viewport-height scroll-offset one).
6. **Verification:** `flutter test test/golden/splash_test.dart -j 1`, `flutter test test/golden/benefits_test.dart -j 1`; design compare against `0_Splash.png`, `0b_Benefits.png` (if exported). Done = both green, tap callback widget test passes.
7. **Handoff notes:** SVG helper API, splash durations, the `onStart`/`onPlay` contract.
8. **Starting prompt:**
   > Read PLAN.md Phase 4 and `design_src/mobile/MSplash.dc.html` + `MBenefits.dc.html`. Implement SplashScreen and BenefitsScreen with goldens at the named timestamps. No flutter_svg: write/port icon paths as described. Use `-j 1`, one file per run. Update handoff, commit.

---

### Phase 5 — Title screen + Tutorial (4 animated steps)

1. **Goal:** main menu and the 4-step tutorial with its looping mini-animations.
2. **Scope:** `TitleScreen` (flicker, held match, logo, 3 buttons + settings link), `TutorialScreen` (progress dots, back/next/skip, last step CTA, per-step animation widgets s1–s4). **Excluded:** actual navigation wiring.
3. **Inputs:** `MTitle.dc.html`, `MTutorial.dc.html`; Phase 3.
4. **Files:** `lib/ui/screens/title/*`, `lib/ui/screens/tutorial/{tutorial_screen,step_drag,step_match,step_hunters,step_door}.dart`, tests.
5. **Tasks**
   - [ ] Title: tilted match (10° about top), flame, vignette + flicker, "Continue — مرحله‌ی ۷ · سرداب زیرین" subtitle driven by `Progress`.
   - [ ] Tutorial state (step 0–3), dots (22 px active / 6 px), disabled "قبلی" on first step, last-step button text "ورود به اولین اتاق".
   - [ ] Step animations as one 4 s repeating controller per step: finger-drag (joystick ring + knob + hand SVG), strike (lit/unlit overlay swap, tap ripple), hunters chase (eyes color keyframes), door + "+۲ کبریت".
   - [ ] Reduced-motion: freeze at a representative frame.
   - [ ] Goldens: Title; Tutorial step 1–4 at t=1.5 s (+ step 2 at t=3 s lit state).
6. **Verification:** `flutter test test/golden/title_test.dart -j 1`; `flutter test test/golden/tutorial_test.dart -j 1`; widget test: next/back/skip callbacks, dot state. Design compare vs `1_Title.png`, `2_Tutorial_1..4.png`.
7. **Handoff notes:** controller-clock injection pattern used for animated goldens (reuse in Phases 9–10).
8. **Starting prompt:**
   > Read PLAN.md Phase 5 and `design_src/mobile/MTitle.dc.html`, `MTutorial.dc.html`. Implement TitleScreen and TutorialScreen with animated steps and goldens at fixed timestamps. `-j 1`, one test file per run, review PNGs with Read. Update handoff, commit.

---

### Phase 6 — Level select

1. **Goal:** chapters grid + selection bottom sheet.
2. **Scope:** `LevelsScreen` (header with back arrow, "۶ از ۱۵ اتاق / ۱۴ از ۴۵ اخگر", 3 chapter rows of 5 tiles — done/current/locked, hunted eye dot, embers, current glow pulse; bottom sheet with stats grid, note, CTA or locked message). **Excluded:** starting a game.
3. **Inputs:** `MLevels.dc.html`; Phases 2 and 3.
4. **Files:** `lib/ui/screens/levels/{levels_screen,level_tile}.dart`, tests.
5. **Tasks**
   - [ ] Tile visual: 58×54 top + 10 px front, 3 states, selected ring `#ffd27a` inset 2px + glow.
   - [ ] Selection state local to screen; default selected = current level.
   - [ ] Sheet content per state (done: "بازی دوباره" + "بهترین ۲ از ۳"; current: hunters note; locked: dashed box).
   - [ ] Semantics labels (`aria-label` equivalents) in Persian.
   - [ ] Goldens: default (L7 selected), a done level selected, a locked level selected.
6. **Verification:** `flutter test test/golden/levels_test.dart -j 1`, `flutter test test/widget/levels_test.dart -j 1`; design compare vs `3_Levels.png`.
7. **Handoff notes:** `LevelsScreen` constructor (progress, callbacks), how the pulse is paused for goldens.
8. **Starting prompt:**
   > Read PLAN.md Phase 6 and `design_src/mobile/MLevels.dc.html`. Implement LevelsScreen against the Progress/Levels data from Phase 2 (see handoff). Tests with `-j 1`. Update handoff, commit.

---

### Phase 7 — Gameplay board rendering (static, no input)

1. **Goal:** the full gameplay screen drawn from a `GameState`, matching the lit and dark designs.
2. **Scope:** `GameBoard` (360×520 box: floor grid, 2.5D walls with z-order, exit door glow, pickup, player + flame, hunters w/ eyes + "!" bubble, light overlay + warm layer), `GameHud` (pause button, level title, match count, burn bar 3 px, hint text, finger icon line), `StrikeButton` (92 px, conic ring, label/seconds, lefty mirror), `JoystickOverlay` (ring + knob), result overlays (escaped / caught / "give up?" link). **Excluded:** timers and gestures.
3. **Inputs:** `MGame.dc.html`; Phases 1, 3.
4. **Files:** `lib/ui/screens/game/{game_screen_view,board_painter,hud,strike_button,joystick,overlays}.dart`, tests.
5. **Tasks**
   - [ ] Paint order: floor → (walls + entities sorted by row via z) → pickup → overlay → warm → door glow → HUD. Use `CustomPainter` for board (walls + overlay) and positioned widgets for player/hunters (so implicit animations: player `.15 s linear`, hunters `.5 s ease`).
   - [ ] Light overlay parameters exactly per §0.2 (`R = 200 + 6.5·burn`, dark radius 48).
   - [ ] HUD in RTL with the 44 px touch targets; Persian match count; semantic labels.
   - [ ] `GameScreenView(state, drag, settings, callbacks)` is stateless → testable from fabricated states.
   - [ ] Goldens: lit 72 % burn / 5 matches (the "preview" state), dark / 6 matches, dark / 0 matches (with give-up link), escaped overlay, caught overlay, lefty variant, joystick visible.
6. **Verification:** `flutter test test/golden/game_view_test.dart -j 1`; design compare lit/dark vs `4_Game_lit.png`, `4_Game_dark.png`. Done = both comparisons within tolerance (or visually confirmed) + commit.
7. **Handoff notes:** coordinate mapping helpers (grid→px), what `GameScreenView` expects, tuning of overlay gradient stops.
8. **Starting prompt:**
   > Read PLAN.md §0.2 and Phase 7, and `design_src/mobile/MGame.dc.html`. Build the stateless gameplay view (board painter, HUD, strike button, joystick, overlays) driven by Phase 1's `GameState`. Goldens for the listed states, one file per run with `-j 1`. Update handoff, commit.

---

### Phase 8 — Gameplay interaction & loop

1. **Goal:** playable level 7 in widget tests — drag to move, strike to light, hunters chase, win/lose.
2. **Scope:** `GameController` (ChangeNotifier) + `GameScreen` that wires engine ↔ view: 100 ms tick via injectable clock/`Ticker`, 170 ms repeat step while dragging, pointer capture rules (HUD buttons swallow pointers), begin-on-first-interaction, pause/resume, haptics hook on hunter move, result transitions. **Excluded:** navigation between screens (callbacks only).
3. **Inputs:** `MGame.dc.html`; Phases 1, 7.
4. **Files:** `lib/ui/screens/game/{game_controller,game_screen}.dart`, `lib/services/haptics.dart` (interface), `test/widget/game_screen_test.dart`.
5. **Tasks**
   - [ ] Fake-able clock: `GameController(engine, {Clock})`; widget tests use `tester.pump(Duration)` to advance.
   - [ ] Pointer logic via `Listener`: down = joystick origin, move → `DragClassifier`, up clears; setPointerCapture equivalent not needed in Flutter.
   - [ ] Strike behaviour and timer lifecycle identical to JS (timer stops on result or flame-out; restarts on strike).
   - [ ] Pause API (`pause()`, `resume()` keeps burn); app lifecycle observer pauses when backgrounded.
   - [ ] Haptics: on hunter step while lit (if setting on).
   - [ ] Widget tests: drag right moves 1 cell then repeats every 170 ms; wall blocks; pickup +2; strike twice no-op while lit; flame out after 8 s; hunter converges and catches; reaching exit → `onEscaped(stats)`; caught → `onCaught(stats)`; dark+0 matches shows give-up link → `onGiveUp`.
6. **Verification:** `flutter test test/widget/game_screen_test.dart -j 1`; re-run `flutter test test/golden/game_view_test.dart -j 1` to ensure no visual regression. Done = green + commit.
7. **Handoff notes:** controller API, stats object fields (matches left, elapsed, steps to door), how screens receive the level.
8. **Starting prompt:**
   > Read PLAN.md Phase 8 and the script in `design_src/mobile/MGame.dc.html`. Implement GameController + GameScreen wiring the Phase 1 engine to the Phase 7 view with an injectable clock; write the widget tests listed in the plan. `-j 1`, one file per run. Update handoff, commit.

---

### Phase 9 — Pause/Settings, Level complete, Caught, Out of matches

1. **Goal:** the four secondary game screens, pixel-faithful.
2. **Scope:** `PauseScreen` (blurred board snapshot behind, status line with remaining seconds/matches, 4 toggles bound to `AppSettings`, Continue/Restart/Tutorial/Levels), `LevelCompleteScreen` (door + silhouette, embers 0–3, stats row, next-level teaser, 3 buttons), `CaughtScreen` (looming hunter, blinking eyes, 2 stats, hint box), `NoMatchesScreen` (burnt match, ember pulse, smoke particles, match row empty). **Excluded:** transition animation.
3. **Inputs:** `MPause`, `MComplete`, `MCaught`, `MNoMatches`; Phases 2, 3, 7.
4. **Files:** `lib/ui/screens/{pause,complete,caught,no_matches}/*`, tests.
5. **Tasks**
   - [ ] Pause: reuse `MazeWallsPainter` with `ImageFiltered(blur 3)`; toggles update settings live (widget test).
   - [ ] Complete: stats from `GameStats` (۳ از ۶ / ۱:۴۲ / ۲ از ۲), ember count param; "تکرار برای ۳ اخگر" label depends on current embers.
   - [ ] Caught: loom animation (translateY −5 px, 5 s), blink (scaleY .1 at 50%); stats "۴ از ۶", "۶ قدم".
   - [ ] NoMatches: six empty match sticks, smoke via 3 delayed fading radial blobs, ember glow pulse.
   - [ ] Goldens: each screen at t=0 pinned; Pause with each toggle state; Complete with 0/2/3 embers.
6. **Verification:** one file per run: `flutter test test/golden/pause_test.dart -j 1`, `.../complete_test.dart`, `.../caught_test.dart`, `.../no_matches_test.dart`; widget tests for toggles and button callbacks; design compare vs `5_Pause.png`, `6_Complete.png`, `8_Caught.png`, `9_NoMatches.png`.
7. **Handoff notes:** screen constructors / callbacks table used by the router in Phase 11.
8. **Starting prompt:**
   > Read PLAN.md Phase 9 and `design_src/mobile/{MPause,MComplete,MCaught,MNoMatches}.dc.html`. Implement the four screens with goldens and callback widget tests. One test file per run, `-j 1`; review each PNG with Read. Update handoff, commit.

---

### Phase 10 — Next-level transition animation

1. **Goal:** the 9 s cinematic between levels, driven by a single controller and golden-tested at key frames.
2. **Scope:** `TransitionScreen` with timeline (door open 5–16 %, walk 13–30 %, white flood 25–47 %, black 38–93 %, title/level/meta text 46–90 %, match strike + sparks + glow 65–90 %), skip button, `onDone` callback at the end (design loops; the app should **not** loop). **Excluded:** routing.
3. **Inputs:** `MTransition.dc.html`; Phase 3, clock-injection pattern from Phase 5.
4. **Files:** `lib/ui/screens/transition/*`, `test/golden/transition_test.dart`, `test/widget/transition_test.dart`.
5. **Tasks**
   - [ ] Express CSS keyframe percentages as `Interval`/`TweenSequence` on a 9 s controller.
   - [ ] Parameters: chapter label, level number, level name, matches & hunters text, flavor line.
   - [ ] Goldens at 0.4 s, 1.5 s, 2.7 s, 3.6 s, 5.0 s, 6.5 s.
   - [ ] Skip ("رد شدن") calls `onDone` immediately; natural end calls it once.
6. **Verification:** `flutter test test/golden/transition_test.dart -j 1`, `flutter test test/widget/transition_test.dart -j 1`; compare any exported frames `7_Transition_<t>.png`.
7. **Handoff notes:** duration constant, that `onDone` fires exactly once.
8. **Starting prompt:**
   > Read PLAN.md Phase 10 and `design_src/mobile/MTransition.dc.html`. Implement TransitionScreen as one 9 s controller with the keyframe percentages from the CSS, goldens at the listed times, skip + onDone tests. `-j 1`. Update handoff, commit.

---

### Phase 11 — App flow, persistence wiring, haptics/audio, settings

1. **Goal:** the full navigation graph running on real data, with progress saved.
2. **Scope:** `routes.dart`/`app.dart` flow, `AppScope` (repository, settings, haptics, audio stub), first-launch rule (Splash → Benefits first time, else Splash → Title), Title ↔ Tutorial ↔ Levels ↔ Game ↔ Pause ↔ Complete ↔ Transition ↔ next Game, Caught/NoMatches retry/levels, level completion writes progress/embers, settings persisted, left-handed layout applied. Audio: a `SoundPlayer` interface with a silent implementation (real package decision Q9). **Excluded:** real audio assets.
3. **Inputs:** `canvas.json` (order) + all `href`s in the M*.dc.html files (they define the flow); all prior phases.
4. **Files:** `lib/main.dart`, `lib/app.dart`, `lib/routes.dart`, `lib/app_scope.dart`, `lib/services/*`, `test/widget/flow_test.dart`.
5. **Tasks**
   - [ ] Flow table (from hrefs): Splash→Benefits; Benefits→Title ("کبریت را روشن کن") / Tutorial; Title→Game(continue)/Tutorial/Levels/Pause(settings); Tutorial→Game ("ورود…", "رد شدن"); Levels→Title(back)/Game(level); Game→Pause→Game(resume | restart)/Tutorial/Levels; Game→Complete→Transition→Game(next) | Game(repeat) | Levels; Game→Caught→Game(retry)/Levels; Game→NoMatches→same.
   - [ ] Restart semantics (fresh engine) vs continue (resume mid-level only when paused; otherwise start the level) — see Q7.
   - [ ] Save `Progress` on `onEscaped`; unlock next level; compute embers via Phase 2 rule.
   - [ ] Settings toggles persist; haptics respect setting; reduce-flicker passed to all flame widgets.
   - [ ] Hardware Back (Android) behaviour: Game→Pause, Pause→Game, Levels→Title.
   - [ ] Full-flow widget tests using in-memory repository and a fake clock.
6. **Verification:** `flutter test test/widget/flow_test.dart -j 1` covering: fresh install path; win level 7 → progress saved → level 8 unlocked → transition → game 8; lose → retry; settings persisted across a rebuilt app with the same repository. `flutter analyze lib test`. Done = green + commit.
7. **Handoff notes:** the route table, anything left stubbed (audio), decisions on Q7/Q8.
8. **Starting prompt:**
   > Read PLAN.md Phase 11 and the earlier phases' handoff blocks. Wire all screens into the app flow with persistence per the flow table, plus the haptics/sound interfaces. Write `test/widget/flow_test.dart` for the listed paths. Run only that file (`-j 1`) plus `flutter analyze lib test`. Update handoff, commit.

---

### Phase 12 — Integration, golden sweep, cleanup

1. **Goal:** everything verified together, documented and clean.
2. **Scope:** run the entire test suite once, re-review every golden against its design reference, fix residual visual diffs, accessibility/semantics pass, dead-code removal, README with the runbook. **Excluded:** new features.
3. **Inputs:** all phases; `design_refs/` fully populated if possible.
4. **Files:** any; `README.md`, `test/golden/sweep_test.dart` (optional table-driven design-compare over all refs).
5. **Tasks**
   - [ ] `flutter test -j 1 --no-pub` (full suite, expect several minutes — run in background).
   - [ ] Table-driven design-compare sweep; list screens above tolerance, fix or document each.
   - [ ] Semantics check on all interactive widgets (labels in Persian), min tap target 44.
   - [ ] Remove placeholders/TODOs or list them; `flutter analyze` whole tree; `dart format --set-exit-if-changed lib test`.
   - [ ] Update README (how to run tests, regenerate goldens, export design refs), final PLAN.md status.
6. **Verification:** full suite green; sweep report committed as `docs/golden_sweep.md` (screen → diff % → status). Done = suite green, analyze clean, report written.
7. **Handoff notes:** known gaps (levels with placeholder maps, audio, real-device untested, Android/iOS build never exercised).
8. **Starting prompt:**
   > Read PLAN.md Phase 12 and all handoff blocks. Run the full test suite once in the background (`flutter test -j 1`), perform the golden sweep against `design_refs/mobile`, fix residual diffs, tidy and document. Report failures honestly. Commit.

---

## 5. Risks

1. **No visual ground truth in the repo until the user exports PNGs** — design-compare tests would be skipped; fidelity then depends on careful reading of CSS. Mitigation: Q2, ask for exports before Phase 3.
2. **CSS ≠ Skia rasterization** (text shaping of Persian, gradient dithering, blur): exact pixel matches are impossible → perceptual tolerance, not equality.
3. **Persian text in tests:** font loading must happen before first frame; variable fonts unreliable → static TTFs; ligature/shaping differences between Vazirmatn builds.
4. **Level content:** only one real map exists; 14 more levels need design (placeholders may feel wrong and change the difficulty table).
5. **1-core machine:** Flutter test startup is slow (30–90 s per file); the full suite in Phase 12 may take many minutes. Avoid parallelism, keep per-phase test commands narrow.
6. **PATH:** `flutter` and `git` are not on PATH in the Claude Code PowerShell session — prepend them each session (command in §3). First `flutter pub get` and font downloads need internet (reachable).
7. **Animated screens** can't be compared frame-for-frame with static exports unless the user exports specific frames.
8. **Flutter 3.50.1 / newer Dart:** package versions pinned at Phase 0 by `pub get`; API drift (e.g. `ThemeData`, `Color.withOpacity` deprecations) possible.
9. **Scope drift:** the roadmap board mentions future features (daily challenge, chapters, leaderboards) — explicitly out of scope.
10. **No device ever run:** touch behaviour (multi-touch, scroll conflicts on Benefits) is only verified through widget tests.

## 6. Open questions (design leaves these unclear — need your answer before the named phase)

- **Q1 (Phase 0)** Is the **mobile Persian set** the only target (desktop 1280×800 boards, English, "first pass", are ignored)? Roadmap says Unity/Godot — I assume Flutter replaces that.
- **Q2 (Phase 0/3)** Can you export the mobile boards as PNG into `design_refs/mobile/` (names in §3.5), including a few frames for animated boards? Otherwise design-compare tests stay skipped.
- **Q3 (Phase 2)** Only level 7 has a maze. Do you have maps/generators for the other 14 levels, or should I invent placeholders (solvable mazes with the matches/hunters counts from the table)? Do later levels use different grid sizes and pickups?
- **Q4 (Phase 2)** How are **embers (0–3)** earned? (matches left? time? "گریز ۲ از ۲" on the complete screen — what is "2 of 2"? hunters evaded?) Also what is "بهترین" (best) on the level sheet — best embers only?
- **Q5 (Phase 1)** Confirm hunter rules: do hunters ever move while it is **dark**? (Tutorial says they stand still in the dark; engine does that.) Do they move toward the player's position or toward the flame's origin? (Code: toward the player.) Speed increase on later chapters? Roadmap mentions "patrolling and listening" hunters for later chapters — in or out of v1?
- **Q6 (Phase 2)** Level state at start: 6 matches in level 7 mock, but the level table says L7 has 6 — confirm "matches" = starting matches, and the preview start (5 matches, 72 % burn, lit) is only a design mockup state.
- **Q7 (Phase 11)** Semantics of Title **"ادامه"**: resume an in-progress run (mid-level, saved state) or start the current level fresh? And of Pause "ادامه" vs "از نو"?
- **Q8 (Phase 11)** First-launch rule: show Benefits only on the first launch (assumed). Any settings entry point beyond Pause (Title "تنظیمات" currently links to the Pause screen)? Is the Pause screen reachable from Title without a game running (what is behind the blur then)?
- **Q9 (Phase 11)** Audio: no audio assets or spec in the design (settings say "footsteps, match, hunters breathing"). Provide assets and a package choice, or ship silent v1? Studio name on splash is a placeholder `[نام استودیو]` — real name?
- **Q10 (Phase 12)** Target platforms: Android (+iOS) only; any store-specific needs (Cafe Bazaar/Myket in roadmap) — out of scope for this plan.
- **Q11** Is the disclaimer/health-claims copy on the Benefits screen final? (It makes cognitive-benefit claims; I will implement it verbatim.)

---

## 7. Phase handoff log (filled in by each implementing session)

| Phase | Status | Commit | Notes |
|---|---|---|---|
| 0 | **done** | (see git log) | Flutter 3.50.1 / Dart 3.14.0. Fonts: Vazirmatn-{Regular,Medium,SemiBold,Bold}.ttf (rastikerdar), NotoNaskhArabic-{Medium,SemiBold,Bold}.ttf (notofonts static), Lalezar-Regular.ttf + OFL-*.txt. Flutter 3.50 template uses `material_ui`; project uses `package:flutter/widgets.dart` + `WidgetsApp` only (material_ui/cupertino removed from pubspec). Harness: `loadAppFonts()`; `pumpScreen(tester, widget, {size=390x844, dpr=1, clockAt})` wraps in RTL/fa/KebritTheme + RepaintBoundary `goldenKey`; `expectGolden(Finder? finder, name)` → `test/golden/goldens/<name>.png`; `expectMatchesDesign(tester, finder, refPath, {meanTol=.04, blockTol=.015})` (block threshold .25, 4× box downscale; skips when ref missing). `design_refs/` does not exist yet (Q2). Design sources in `design_src/mobile/` (13 files incl. canvas.json, Roadmap). Tokens: `Kc` (tokens.dart), `KText`/`KFonts` (text_styles.dart), `KebritTheme`. |
| 1 | **done** | (see git log) | Pure Dart under `lib/game/` (only `dart:math`/`dart:collection`); 40 tests in `test/unit/game/` green, `flutter analyze lib test` clean. **Types:** `Cell(x,y)` (value-equal, `+`), `enum Dir {up,down,left,right}` with `dx/dy`, `enum CellType {wall,floor,exit}`, `Grid.parse(rows)` (`cols`, `rows`, `exit`, `isWall(x,y)`, `isExit(x,y)`, `typeAt`; OOB = wall; throws `FormatException` on bad maps), `Level(id,name,chapter,startMatches,grid,playerStart,hunterStarts,pickups=[])`, `GameConfig` statics (+`fullBurn=100`, `pickupMatches=2`). **`GameEngine(Level)`** / `.fromState(s)`: `state` getter (immutable `GameState`, replaced on every call), `strike()`, `tick()` (call every 100 ms), `step(Dir)`, `giveUp()`. No timers inside; the controller (Phase 8) owns the clock, the 170 ms repeat and "fire on direction change". **`GameState`**: `level, player, hunters, matches, burn (0..100), lit, pickedUp, result, ticks, litTicks, matchesStruck, steps`; getters `isPlaying`, `isOutOfMatches`, `secondsLeft` (= ceil(burn/100·8), 0 when dark), `elapsedTicks`, `elapsedMs`; `copyWith`. **`enum GameResult {playing, escaped, caught, outOfMatches}`**. **Rules decisions:** (1) `outOfMatches` is a *flag* `state.isOutOfMatches` (dark, 0 matches, still playing); `result` becomes `GameResult.outOfMatches` only via `engine.giveUp()` (no-op unless the flag is set), which the "تسلیم" link should call before navigating to NoMatches. (2) `ticks`/`elapsedMs` count every tick while playing (lit or dark) so Complete/Caught can show real time; `litTicks` is the per-flame counter that drives the every-9th-tick hunter step and resets on each strike (the JS resets its `n` per timer start). (3) On the tick where burn reaches 0 the flame goes out and hunters do not move (as in JS). (4) Strike/tick/step are no-ops once `result != playing`. **Stats for Complete/Caught:** matches left = `state.matches`, matches used = `matchesStruck`, time = `elapsedMs`, steps taken = `steps`, par = `stepsToExit(level.grid, level.playerStart)` (top-level fn in `hunter_ai.dart`, returns `int?`, level 7 = 16). **Other:** `HunterAi.distances(grid, from, {allowExit})`, `HunterAi.nextStep(grid, from, target)`; `DragClassifier.classify(ox,oy,px,py) → DragResult(direction: Dir?, knobDx, knobDy)` (dead zone strict `> 16`, knob clamp 30, dominant axis, **tie → vertical** as in JS). Test fixtures: `test/unit/game/fixtures.dart` (`level7()`, `corridor(...)`). Level 7 name/chapter taken from MLevels: «سرداب زیرین» / «سرداب‌ها». Preview mock state of the JS (lit, 72 burn, 5 matches) is NOT reproduced; `GameState.initial` starts dark with `startMatches`. |
| 2 | **done** | (see git log) | `lib/data/`; 29 tests in `test/unit/data/` green (+40 game tests), analyze clean. `shared_preferences` was already in pubspec. **Levels (`levels.dart`):** `Levels.all` / `Levels.byId(1..15)` return Phase 1 `Level` (no separate LevelMeta); `Levels.count=15`, `Levels.placeholderIds` (= all except 7), `chapters` (`Chapter(label,name)`), `chapterIndexOf(id)`, `levelsPerChapter=5`, `level7Rows`. Hunter count = `level.hunterStarts.length`. **PLACEHOLDER mazes: levels 1-6 and 8-15** (deterministic generator: 9x13, recursive backtracker on odd lattice with row 1 fully open, exit (4,0), player start (1,11), hunters on random floor cells >= 8 BFS steps away, no pickups); level 7 is the real map. Test fixture `fixtures.dart` keeps its own copy of the level-7 map and a test cross-checks it. Tests: every level solvable via `stepsToExit` and by walking it with the engine. **Progress (`progress.dart`):** immutable `Progress({currentLevel=1, embers})`; `isUnlocked(n)`, `isDone(n)`, `bestEmbers(n)`, `completedCount`, `totalEmbers` (design mock gives 6 rooms / 14 embers), `statusOf(n)` -> `LevelStatus {done,current,locked}` (current level counts as done once finished, so level 15 works), `complete(n, embers)` (ignores locked levels, clamps 1..3, keeps best, advances `currentLevel` only when n == current), `toJson/fromJson` (tolerant). **Ember rule (ASSUMED, Q4, isolated):** `emberRule(startMatches:, matchesStruck:)`: 3 if struck <= ceil(start/3), 2 if <= ceil(2*start/3), else 1. Matches the mock (3 of 6 left -> 2 embers). Note level 15 (2 matches) can only score 1 by striking more than it starts with (needs a pickup). The Complete screen's "گریز ۲ از ۲" is assumed = hunters evaded (hunter count) and "کبریت مانده ۳ از ۶" = `state.matches` of `level.startMatches`. **Settings (`settings.dart`):** `AppSettings{sound=true, haptics=true, reduceFlicker=false, leftHanded=false}`, `copyWith`, JSON. **Repository (`progress_repository.dart`):** `abstract ProgressRepository {loadProgress, saveProgress, loadSettings, saveSettings}` (all async); `PrefsProgressRepository(SharedPreferences)` + `PrefsProgressRepository.open()` (keys `kebrit.progress.v1`, `kebrit.settings.v1`, corrupt data -> defaults); `InMemoryProgressRepository({progress, settings})`. **Formatting (`persian.dart`):** `fa(int)`, `faTime(Duration)` -> «۱:۴۲». "Continue" pointer = `Progress.currentLevel`. First-launch/Benefits flag not stored yet (Phase 11, Q8). |
| 3 | **done** | (see git log; 3a + 3b commits) | UI kit under `lib/ui/kit/`, all goldens reviewed by `Read`. **Harness fix (Phase 0 bug):** `pumpScreen` listed `DefaultWidgetsLocalizations` before `GlobalWidgetsLocalizations`, so `Localizations` forced **LTR** inside the outer RTL; now only the Global delegate is used, canary golden regenerated (paragraphs right-aligned). Every earlier-style golden must be RTL-correct now. `Kc.wallTop` now uses the exact CSS 165° alignments (∓0.317, ∓1.183). `persian.dart` gained `faDigits(String)` (`fa` calls it). **Translation helpers (`css.dart`, rules in its header):** `rgba()`, `CssStop(color, at)`, `cssStops` (premultiplied-alpha resampling – CSS fades to `rgba(0,0,0,0)` without darkening), `cssRadialPx` (px stops, R = last), `cssRadialFarthestCorner` (% stops, CSS default size), `cssEllipse` / `cssEllipseFarthestCorner`, `cssLinear(deg, box, …)` (exact CSS gradient line), `cssConicProgress(on, off, degrees)` (SweepGradient from −90°, hard stop), `CssShadow(dx,dy,blur,spread,color)` → `toBoxShadow()` / `paintCssShadow(canvas, rrect, s)` (CSS blur B = σ B/2; Flutter BoxShadow σ = r·0.57735+0.5, `cssBlurToRadius` inverts it), `cssBoxShadows`, `CssBlur(px, child)` (ImageFiltered, decal), `PolygonClipper(points as fractions)`, `pctRRect(rect, topH,topV,bottomH,bottomV)`. **Widgets:** `StoneBackground({baseColor, gradientAngle, gradientColors})` + `.complete()` (MTitle/MComplete wall with 48/96 px joints), `RadialBackdrop({center, inner, outer, stopFraction})` + `.levels()` (game/levels vignette), `BottomSheetPanel({child, padding, height})`, `PillButton({label, subLabel, onPressed, variant: PillVariant.primary/outline/text, height 44–60 (asserted), fontSize, fontWeight, icon, expand, borderColor, fillColor, glowBlur, glowAlpha, autofocus…})` (+ `kOutlineFillTitle`, `ChevronIcon`), `KToggle(value)` and `ToggleRow({label, description, value, onChanged})`, `FaText(String)` / `FaText.number(int)`, `FlickerScope(reduce, child)` (set from `AppSettings.reduceFlicker`; Phase 11), `FlickerBuilder`, `FlickerProfile.game/title`, `FlickerOpacity`, `Flame` / `Flame.title/.player/.strikeButton` (+ `FlameStyle`; params `flicker`, `reduceFlicker`, `phase` to pin a frame), `MatchIcon` (HUD 5×20), `MatchStrikeIcon({lit})` (10×30), `MatchStick({lit})` (40×200 title hero), `EmberIcon.small/.large({lit})`, `EmberRow({count, total, size})`, `LightOverlay.lit({center, burn})/.dark({center})/.title()/.pause()` (+ custom `LightOverlay(center, stops px)`), `WarmFlicker.game({center, burn})/.title()`, `DoorGlow({opacity})`. **Phase 7 API (`stone_wall.dart`):** `WallStyle.maze/.flat/.levelTile`, `wallShade(row,col)`, `paintStoneWall(canvas, topRect, style, gradient)`, `MazeWallsPainter(grid, {style, fromRow, toRow, cell=40})` / `MazeWalls(...)` (paints wall **and** exit cells, row-major; use `fromRow == toRow == r` to interleave with entities of row r (z: wall r < entity r < wall r+1); it paints up to 12 px above its box – don't clip), `StoneWallCell({width, topHeight, shade, style, topGradient})`, `MazeFloor(cols, rows)`, `ExitDoor` (20×44 at board (170,−4)), `ExitDoorLight` (70×50 at (145,38)). **Positions** are the design's CSS pixel positions, applied by the caller (see `test/helpers/kit_scene.dart` = MGame board composition). **CSS not matchable / substitutes:** `inset` box-shadows → 1 px top highlight / 2 px bottom strips painted over the wall top (identical for zero-blur); `border-top` on a rounded sheet → DRRect; CSS “no shadow under the box” clipping not done (only visible on translucent boxes, none in design); `repeating-linear-gradient` joints → 1 px non-AA rects; hover/pressed states are *derived* (design has only `a:hover{color}` and `:focus-visible` outline): pressed = scale .97 + 12 % darker gradient / row-hover fill / `#ffd27a` text, focus ring = 2 px `#ffd27a` outline offset 3 (keyboard focus only). Reduced flicker rests the flame at the neutral mid pose (phase .5) and opacity layers at 1. Visible differences from the browser are not yet verifiable (no `design_refs/`, Q2); goldens were judged against the CSS values. **Tests:** `test/widget/kit/{css,pill_button,toggle_row,flicker}_test.dart` (31 tests), goldens `kit_{buttons,surfaces,flame,icons,walls,overlay}_test.dart` → `kit_buttons`, `kit_buttons_pressed`, `kit_backgrounds`, `kit_sheet`, `kit_flame`, `kit_icons`, `kit_wall_cells`, `kit_maze`, `kit_overlay_{lit,lit_low,dark,menus}`. |
| 4 | **done** | (see git log) | **SVG helper (`lib/ui/kit/svg_path.dart`):** `parseSvgPath(String d) → Path` (M L H V C S Q T A Z, relative, implicit repeat, compact numbers, packed arc flags; arcs via `Path.arcToPoint`), `SvgIconData(paths, {circles: [(cx,cy,r)]})`, `SvgIcon(data, {color, size=24, strokeWidth=1.8})` (viewBox 24). **`lib/ui/kit/dashed.dart`:** `DashedBorderBox({color,width,radius,padding,child})`, `DashedLine({color,width})` (Chromium dash 3N/gap 2N). **Splash:** `SplashScreen({onStart, time, reduceFlicker})` – tap anywhere → `onStart`; animation is a pure function of seconds in `SplashScene(t, reduceFlicker)`; live uses a Ticker (stops after 3.4 s when reduced), `time:` pins a frame for goldens. `kSplashSettleSeconds = 3.4`. Fuse grows from the right (RTL). Scaled with `FittedBox(contain)` to the 390×844 design. **Benefits:** `BenefitsScreen({onPlay, onTutorial, controller, flamePhase, reduceFlicker})` (play = «کبریت را روشن کن», tutorial = «اول آموزش را ببینم»); copy/icons in `benefit_items.dart` (`benefitItems` ×8, `benefitSteps` ×3). **Finding:** the design's `min-height:1960` is only the canvas crop; real content is ≈2416 px and scrolls, so goldens: `benefits_board` (390×1960 = export crop), `benefits_full` (390×2420), `benefits_scrolled` (offset 900). Splash goldens: `splash_{0_3s,0_7s,1_0s,2_0s,3_4s}`. Disabled-looking buttons in goldens mean `onPressed == null` (pass callbacks). Tests: `test/widget/kit/svg_path_test.dart`, `test/widget/intro_screens_test.dart`. Design compares skipped (no `design_refs/`, Q2); `expectMatchesDesign` needs the full path `design_refs/mobile/<name>.png`. Studio name still placeholder `[نام استودیو]` (Q9). |
| 5 | **done** | (see git log) | **Title:** `TitleScreen({progress?, onContinue, onTutorial, onLevels, onSettings, flickerPhase, reduceFlicker})` (null progress = level 1; subtitle «مرحله‌ی N · name» from `Levels.byId(progress.currentLevel)`); stone + `LightOverlay.title` + `WarmFlicker.title` + `MatchStick` + logo block + `PillButton` menu; `flickerPhase` pins flame and warm layer (0 = full light). **Tutorial:** `TutorialScreen({initialStep=0, onSkip, onDone, time, reduceFlicker})`, step state inside the screen, copy in `tutorialSteps` (`TutorialCopy`), dots have keys `dot-0..3`. Step visuals in `lib/ui/screens/tutorial/`: `StepDrag/StepMatch/StepHunters(p, pinned)`, `StepDoor(breath)`, shared `tutorial_parts.dart` (`TutorialStage` 342×380, `Slab`, `TutorialPlayer`, `TutorialHunter`/`HunterPainter(eyes 0..1)` – reusable for the Caught screen, `playerFlame`, `track(p, keys)` = CSS keyframes with per-interval ease-in-out, `kTutorialLoop` 4 s). **Clock-injection pattern:** visuals are pure functions of time/phase; screens take `time` (pinned, = time since the step appeared) or run a `Ticker`; the ticker restarts per step (CSS re-mount) and stops under reduced flicker, which freezes each demo at `_frozenPhase` [.6,.5,.45,0]. `breathOpacity(seconds)` is the door's separate 3 s loop. Own «قبلی» button (only its text dims when disabled, like the design). Goldens: `title`, `tutorial_1`, `tutorial_2_dark` (t=.5 s), `tutorial_2_lit`, `tutorial_3`, `tutorial_4` (all t=1.5 s unless noted). Tests: `test/widget/title_tutorial_test.dart` (callbacks, dots, step switching, ticker, `track`). Design compares skipped (no `design_refs/`, Q2). Open: the title/tutorial «تنظیمات»/skip targets are wired in Phase 11. |
| 6 | **done** | (see git log) | **`LevelsScreen({required Progress progress, initialSelected, onBack, onPlay(int level), pulsePhase, reduceFlicker})`** in `lib/ui/screens/levels/levels_screen.dart`; selection is local (starts at `progress.currentLevel`), tiles in `level_tile.dart` (`LevelTile`, `pulseShadow(phase)`). Copy/stats derive from `Levels`/`Progress` (header = `completedCount`/`totalEmbers`; best = `bestEmbers`); CTA «بازی دوباره» (done) / «ورود به اتاق» (current), locked = dashed box. **Pulse:** 1.8 s Ticker, pinned with `pulsePhase` (goldens use 0 / .5), stopped under reduced flicker (`FlickerScope` or `reduceFlicker`, rests at phase 0). As in the CSS, the pulse *replaces* the selection ring, so a selected current tile shows no ring (default view). Tile semantics: «مرحله‌ی N، name، گذرانده‌شده/مرحله‌ی فعلی/قفل», selected + button. **Deviation:** the design's sheet content (56 px number at line-height 1.5, stats, 2-line note, CTA) is taller than its 300 px box, which pushes the CTA off screen, so line heights are tightened (1.1/1.3/1.4) and 16 px gaps are 10 px; content sits in an `OverflowBox`. Goldens: `levels`, `levels_done_selected` (pulse .5), `levels_locked_selected`. Tests: `test/widget/levels_test.dart` (6). Design compare skipped (no `design_refs/`, Q2). |
| 7 | **done** | (see git log) | `lib/ui/screens/game/`. **`GameScreenView({required GameState state, started=true, JoystickDrag? drag, AppSettings settings, flickerPhase, animate=true, onPause, onStrike, onContinueEscaped, onContinueCaught, onGiveUp})`** — stateless, FittedBox-scaled 390×844. `started` = the design's `init` (false before first touch/strike: only changes the hint and keeps the strike button enabled). Give-up link shows when `started && state.isOutOfMatches`; result overlays show for `GameResult.escaped/caught`. `flickerPhase` pins every flame/warm flicker (goldens use .5), `animate:false` removes the sprite slide (tests). **Files:** `board_painter.dart` (`GameBoard`, `PlayerSprite`, `HunterSprite`, `MatchPickup`, helpers `boardOrigin`=(15,150), `kCell`=40, `cellCenter(x,y)`, `lightCenter(Cell)` = cell centre −12 px), `hud.dart` (`GameTopBar`, `BurnBar`, `GameHint`, `GiveUpLink`, `hintFor(state, started:)`), `strike_button.dart` (`StrikeButton`; `canStrike` = playing ∧ matches>0 ∧ ¬(lit ∧ started); view passes `onStrike` through only when it can strike, else the tap is inert), `joystick.dart` (`JoystickDrag(ox, oy, [kx, ky])` in design space, `JoystickOverlay`), `overlays.dart` (`ResultOverlay(kind, levelId, onContinue)`). **Stacking:** one flat keyed `Stack` sorted by CSS z (wall row r = 10r+5, entities 10r+6, door 7; floor, door light, pickup underneath) so a sprite changing row is re-ordered without losing its `AnimatedPositioned` state (player .15 s linear, hunters .5 s ease). Walls use Phase 3's `MazeWalls(fromRow: r, toRow: r)`. Door/door-glow/pickup positions are derived from `grid.exit` / `level.pickups` (identical to the design's hard-coded px for level 7). Reuses `HunterPainter` from the tutorial (eyes 1 = lit); the "!" bubble is shown while lit. **Deviations:** left-handed also moves the hint block to the right (otherwise it collides with the mirrored button); give-up link and pause button get ≥44 px tap areas; HUD buttons are plain `GestureDetector`s — pointer-stopping vs. the full-screen drag Listener is Phase 8's job. Goldens: `game_lit` (72 %/5 matches), `game_dark` (not started), `game_no_matches`, `game_escaped`, `game_caught`, `game_lefty`, `game_joystick`. Tests: `test/widget/game_view_test.dart` (11). Design compare for `4_Game_lit/dark` skipped (no `design_refs/`, Q2). The caught headline wraps to two lines at 44 px/326 px width (probably also in the browser; unverified). |
| 8 | **done** | (see git log) | `lib/ui/screens/game/{game_controller,game_screen,pointer_claim}.dart`, `lib/services/haptics.dart`. **`GameController(Level, {haptics=NoopHaptics, settings, timerFactory})`** (ChangeNotifier; `timerFactory` = `Timer.periodic`-like, default real, tests use `tester.pump`): `state`, `started` (design `init`), `paused`, `drag` (JoystickDrag), `stats` (`GameStats`), `begin()`, `strike()`, `giveUp()`, `pause()`, `resume()` (burn/hunters kept), `pointerDown/Move(x,y design-space)`, `pointerUp()`, `settings=`, `dispose()`. Tick timer (100 ms) runs from first interaction until result/pause (also in the dark, for elapsed time); the 170 ms repeat timer only while a finger is down; direction change fires a step immediately (as JS). **`GameStats`** {level, startMatches, matchesLeft, matchesStruck, elapsed, steps, stepsToDoor (BFS from current cell), hunters}. **`GameScreen({level? | controller?, settings, haptics, timerFactory, flickerPhase, animate, onPause, onEscaped(stats), onCaught(stats), onGiveUp(stats)})`**: screen-wide `Listener` maps pointers to design space (FittedBox-aware); HUD buttons (pause, strike, give-up) are wrapped in `PointerClaim` (inner listener records the pointer id in a `PointerClaims` set, the outer drag listener skips it = JS `stop`). `onEscaped/onCaught` fire from the overlay «ادامه» button, `onGiveUp` from the link (after `engine.giveUp()`), `onPause` after `controller.pause()` (also when the app goes to the background; the owner calls `controller.resume()`). Passing `controller:` means the caller owns/disposes it (Phase 11 needs this to resume after Pause); with `level:` the screen owns it. Haptics (`Haptics.hunterStep`, `SystemHaptics` = selectionClick) fire when hunters move while lit and `settings.haptics`; `AppSettings` come from the screen prop. Tests: `test/widget/game_screen_test.dart` (14); game view tests/goldens unchanged and green. |
| 9 | not started | | |
| 10 | not started | | |
| 11 | not started | | |
| 12 | not started | | |
