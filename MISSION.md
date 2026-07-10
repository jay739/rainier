# MISSION — Rainier

Build **Rainier**: an open-source, native macOS alternative to Rainmeter — a desktop
customization engine that renders user-authored "skins" (declarative INI files) as
always-on-desktop widgets: clocks, CPU/RAM/network monitors, battery meters, etc.

This file is the build spec and acceptance contract. It is written to be reusable
verbatim as a prompt for a cloud/autonomous agent run.

## Why this exists

Rainmeter is Windows-only. The macOS landscape:

- **Übersicht** — open source, but every widget is an HTML/JS mini web app rendered
  in a web view. Powerful, heavy, high-effort to author.
- **GeekTool** — closed source, shell-script geeklets, barely maintained.
- **Nerdtool** — abandoned.

None replicate Rainmeter's actual model: **plain-text declarative skins** made of
*measures* (data sources) and *meters* (visual elements), natively rendered, trivially
shareable. Rainier fills that gap.

## Product requirements

1. **Menu bar app** (no Dock icon). Menu lists discovered skins with on/off toggles,
   Refresh All, Open Skins Folder, Quit.
2. **Skins** live in `~/Library/Application Support/Rainier/Skins/<SkinName>/skin.ini`
   (root overridable via `RAINIER_HOME` env var for dev/testing). First launch seeds
   bundled example skins.
3. **Skin windows** are borderless, transparent-capable, sit at desktop level
   (above wallpaper, below normal windows; configurable), visible on all Spaces,
   draggable, positions persisted across restarts.
4. **INI dialect** (Rainmeter-flavored):
   - `[Rainier]` meta section: `Update` (ms), `BackgroundColor`, `ZPosition`.
   - `[Variables]` with `#VarName#` substitution.
   - Measure sections: `Measure=CPU|Memory|Time|Net|Disk|Battery|Uptime|Shell|Calc`.
   - Meter sections: `Meter=String|Bar|Line|Image`.
   - Common meter keys: `X`, `Y` (with Rainmeter-style `r`/`R` relative suffixes),
     `W`, `H`, `MeasureName`, `SolidColor`, `Hidden`, `UpdateDivider`.
   - Colors as `R,G,B[,A]` (0–255).
5. **Measures**:
   - `Time` — strftime format strings (`%H:%M`), optional `TimeZone`.
   - `CPU` — total CPU % via host tick deltas.
   - `Memory` — used/total/percent via vm statistics (`Type=Used|Free|Total|Percent`).
   - `Net` — per-interface or total bytes/sec in/out via `getifaddrs` deltas
     (`Type=In|Out`).
   - `Disk` — free/used/total for a path via `statfs` (`Type=Free|Used|Total|Percent`).
   - `Battery` — percent / charging state via IOKit power sources.
   - `Uptime` — seconds since boot, formatted.
   - `Shell` — run a shell command on an interval, capture stdout (async, never
     blocks render).
   - `Calc` — arithmetic expression evaluator with `[MeasureName]` references,
     `+ - * / % ( )`, numbers.
   - Common: `MinValue`, `MaxValue`, `UpdateDivider`.
6. **Meters**:
   - `String` — `Text` with `%1`/`[MeasureName]`/`#Var#` substitution, `FontFace`,
     `FontSize`, `FontColor`, `StringAlign` (Left/Center/Right), `NumOfDecimals`,
     `Prefix`/`Postfix`, `AutoScale` (bytes → KB/MB/GB).
   - `Bar` — horizontal/vertical fill from measure's relative value, `BarColor`,
     `BarOrientation`.
   - `Line` — scrolling history graph of a measure, `LineColor`, `AutoScale`,
     `HorizontalLines` optional.
   - `Image` — image file from skin folder, scaled to W/H, optional `ImageAlpha`.
7. **Rendering**: pure CoreGraphics/CoreText in a custom NSView; one timer per skin
   at its `Update` interval. No web views, no Electron. Idle CPU for a typical
   3-skin setup must be negligible (< ~1%).
8. **Bundled example skins** (also serve as documentation): Clock, System (CPU/RAM/
   disk), Network graph, Battery.
9. **Distribution**: `Scripts/make-app.sh` builds a release `Rainier.app` bundle
   (LSUIElement, ad-hoc codesign). `swift build`/`swift run` must work with
   Command Line Tools only (no Xcode, no external dependencies).
10. **Tests**: `swift run RainierTests` — assertion-based test executable (CLT has no
    XCTest) covering INI parsing, variable substitution, color parsing, relative
    positioning, Calc evaluator, autoscale formatting. Exit code 0 = pass.
11. **Docs**: README.md with feature list, install, full skin-format reference and a
    commented example skin. REPORT.md at end of build: what was built, decisions,
    known gaps.

## Constraints & conventions

- All file operations stay inside this repo folder plus `RAINIER_HOME` at runtime.
- Zero runtime dependencies; SwiftPM only; Swift 5 language mode acceptable.
- Targets: `RainierCore` (library: parser, engine, measures — testable),
  `Rainier` (executable: AppKit shell), `RainierTests` (executable test runner).
- Git: author Jayakrishna Konda <contact@jay739.dev>. Local commits only, never push.
  No AI attribution anywhere (no Co-Authored-By, no "generated with" lines).
- Staged milestones, each ending in a compiling, committed state:
  - M0 scaffold → M1 app shell → M2 engine core → M3 full measures/meters →
    M4 skin management → M5 examples + bundle → M6 tests/docs/report.
- License: MIT.

## Acceptance

- `swift build -c release` succeeds with CLT only.
- `swift run RainierTests` exits 0.
- Launching the app with a fresh `RAINIER_HOME` seeds example skins, shows them on
  the desktop, and the menu bar item can toggle them.
- Example skins display live CPU/RAM/network/battery/time data.
- Killing and relaunching restores skin positions and active set.
