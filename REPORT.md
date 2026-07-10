# REPORT — Rainier autonomous build

Built 2026-07-10 in a single autonomous session. All acceptance criteria from
MISSION.md are met.

## What was built

A native macOS Rainmeter alternative: menu bar app + skin engine rendering
declarative INI skins as desktop widgets.

- **Engine** (`Sources/RainierCore`): Rainmeter-flavored INI parser with
  case-insensitive keys and `#Variable#` substitution; 9 measures (Time, CPU,
  Memory, Net, Disk, Battery, Uptime, Shell, Calc); 4 meters (String, Bar,
  Line, Image); Rainmeter-style `r`/`R` relative layout; auto-sized windows.
- **App** (`Sources/Rainier`): menu bar item with per-skin toggles, Refresh
  All, Open Skins Folder; borderless desktop-level windows on all Spaces;
  drag-to-move with position persistence; first-run seeding of bundled skins.
- **Examples** (`Skins/`): Clock, System (CPU/RAM/disk with bar + graph),
  Network (in/out graphs), Battery.
- **Tests** (`Sources/RainierTests`): 43 assertions — parser, variables,
  colors, Calc evaluator, autoscale, strftime, spec parsing, layout, config
  round-trip. `Scripts/build.sh --tests` exits 0.
- **Distribution**: `Scripts/make-app.sh` → ad-hoc-signed `Rainier.app`
  (LSUIElement) with skins in Resources.

## Verification performed

- Release build + tests green on macOS 26 / Swift 6.4 / arm64.
- Launch smoke tests (bare binary and .app) with fresh `RAINIER_HOME`: app
  stays alive, seeds 4 skins, writes config.
- Window-server check via `CGWindowListCopyWindowInfo`: 4 windows at desktop
  level with content-driven sizes; position restore verified (window appears
  at configured [300,300]); enabled-list filtering verified (only Clock loads).
- Screenshot verification was **not** possible: `screencapture` is blocked
  without Screen Recording permission for the terminal. Visual appearance is
  unverified — worth a quick look at the example skins on first launch.

## Decisions & deviations

- **SwiftPM broken on this machine** (CLT missing `BuildServerProtocol`
  framework; `swift build` dies in dyld). Kept `Package.swift` for healthy
  toolchains and added `Scripts/build.sh` that compiles the same sources with
  bare `swiftc`; app sources guard imports with `#if canImport(RainierCore)`.
  `swift build` is therefore **untested**.
- Milestones M2–M4 landed as one commit: measures are referenced by one
  factory, so splitting them would have meant committing stubs.
- Tests are a plain assert executable (CLT ships no XCTest).
- Windows use `kCGDesktopWindowLevel + 1`: above wallpaper, below desktop
  icons and app windows.
- Monospaced-digit system font by default so ticking values don't jitter.
- Programmatic resizes are excluded from position persistence (else the
  clock's changing text width would rewrite config.json every second).

## Known gaps (honest list)

- No DynamicVariables / bangs / mouse actions (`LeftMouseUpAction` etc.).
- No per-meter `UpdateDivider` (measures only), no MeterStyle inheritance.
- Line meter: single line per meter (Rainmeter allows N).
- `TimeZone` uses a fixed offset from the zone (DST-correct at evaluation
  time, but `%Z` prints UTC).
- Skin INI changes require Refresh All (no file watching).
- Multi-monitor: new skins cascade on the main screen only; saved positions
  on disconnected screens are restored off-screen.
- `Shell` measures execute arbitrary commands — documented in README; an
  allowlist/prompt would be a good v0.2 hardening item.

## Suggested next steps

1. Look at the skins visually; tweak example styling to taste.
2. Mouse actions + `!Refresh`/`!Toggle` bangs (the community-skin enabler).
3. File watching for live skin editing.
4. GitHub publish with screenshots (you push; repo has no remote configured).
