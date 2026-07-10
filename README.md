# Rainier ☔️

**A native, open-source Rainmeter alternative for macOS.**

Rainier renders *skins* — plain-text INI files describing live desktop widgets —
directly on your desktop: clocks, CPU/RAM/disk monitors, network graphs, battery
meters, output of arbitrary shell commands. No web views, no Electron, no
runtime dependencies; just AppKit and CoreGraphics.

Where [Übersicht](https://github.com/felixhageloh/uebersicht) makes every widget
an HTML/JS mini-app, Rainier follows Rainmeter's model: **measures** (data
sources) + **meters** (visual elements) declared in a shareable text file.

## Quick start

```sh
Scripts/make-app.sh        # builds dist/Rainier.app
open dist/Rainier.app
```

First launch seeds four example skins (Clock, System, Network, Battery) into
`~/Library/Application Support/Rainier/Skins/` and shows them on the desktop.
Use the ☔️ menu bar item to toggle skins, refresh, or open the skins folder.
Drag any skin to reposition it; positions persist across restarts.

Requirements: macOS 13+, Xcode Command Line Tools to build (`swift build` also
works where SwiftPM is healthy; `Scripts/build.sh` compiles with bare `swiftc`).
Run tests with `Scripts/build.sh --tests`.

## Writing a skin

A skin is a folder in the Skins directory containing `skin.ini`:

```ini
[Rainier]
Update=1000                ; refresh interval in ms
BackgroundColor=20,22,30,190
CornerRadius=12
Padding=16
ZPosition=Desktop          ; Desktop | Normal | Top

[Variables]
Accent=120,200,255         ; use as #Accent# anywhere below

[MeasureCPU]
Measure=CPU                ; 0–100 percent

[MeterLabel]
Meter=String
MeasureName=MeasureCPU
Text=CPU %1%               ; %1 = first bound measure
FontSize=12
FontColor=#Accent#

[MeterBar]
Meter=Bar
MeasureName=MeasureCPU
X=0r                       ; r = relative to previous meter's origin
Y=4R                       ; R = relative to previous meter's far edge
W=180
H=6
BarColor=#Accent#
```

### Measures

| `Measure=` | What it reports | Options |
|---|---|---|
| `Time` | formatted date/time | `Format` (strftime, e.g. `%H:%M`), `TimeZone` |
| `CPU` | total CPU % (0–100) | |
| `Memory` | physical memory bytes | `Type=Used\|Free\|Total\|Percent` |
| `Net` | bytes/sec | `Type=In\|Out`, `Interface` (default: all) |
| `Disk` | disk space bytes | `Drive` (path, default `/`), `Type=Free\|Used\|Total\|Percent` |
| `Battery` | battery state | `Type=Percent\|Charging` |
| `Uptime` | time since boot ("3d 4h 12m") | |
| `Shell` | stdout of a command (async) | `Command=uname -r` |
| `Calc` | arithmetic over measures | `Formula=MeasureA + MeasureB / 1024` |

All measures accept `MinValue`, `MaxValue` (for bars/graphs) and
`UpdateDivider` (update every Nth tick).

### Meters

| `Meter=` | Options |
|---|---|
| `String` | `Text` (`%1`…`%9`, inline `[MeasureName]`), `FontFace`, `FontSize`, `FontColor`, `StringStyle=Bold\|Italic`, `StringAlign=Left\|Center\|Right`, `NumOfDecimals`, `AutoScale=1` (bytes → KB/MB/GB), `Prefix`, `Postfix` |
| `Bar` | `BarColor`, `BarOrientation=Horizontal\|Vertical` |
| `Line` | history graph: `LineColor`, `LineWidth`, `AutoScale=1` (scale to own peak) |
| `Image` | `ImageName` (relative to skin folder), `ImageAlpha=0–255` |

All meters accept `X`, `Y` (absolute, or `Nr`/`NR` relative to the previous
meter), `W`, `H`, `SolidColor` (background), `Hidden=1`.

Colors are `R,G,B[,A]` (0–255) or hex `RRGGBB[AA]`.

## Notes

- Skin windows sit above the wallpaper and below your windows (`ZPosition=Desktop`),
  appear on all Spaces, and never steal focus.
- `RAINIER_HOME=/some/dir` overrides the config/skins location (useful for testing).
- `Shell` measures run arbitrary commands from skin files — read skins you
  download before enabling them.

## License

MIT — see [LICENSE](LICENSE).
