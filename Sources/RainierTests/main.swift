#if canImport(RainierCore)
import RainierCore
#endif
import Foundation
import CoreGraphics

// Minimal assertion harness: Command Line Tools ship without XCTest, so the
// test suite is a plain executable. Exit code 0 = all passed.
var failures = 0
var count = 0

func expect(_ condition: Bool, _ label: String,
            file: String = #file, line: Int = #line) {
    count += 1
    if !condition {
        failures += 1
        print("FAIL: \(label)  (\((file as NSString).lastPathComponent):\(line))")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String,
                               file: String = #file, line: Int = #line) {
    count += 1
    if actual != expected {
        failures += 1
        print("FAIL: \(label) — got \(actual), expected \(expected)  (\((file as NSString).lastPathComponent):\(line))")
    }
}

// MARK: INI parser

let doc = INIParser.parse("""
; comment line
[Rainier]
Update=500

[MeasureCPU]
Measure=CPU
UpdateDivider = 2

[MeterText]
Meter=String
Text=CPU is %1% ; not a comment here
""")
expectEqual(doc.sections.count, 3, "parses three sections")
expectEqual(doc.section(named: "rainier")?.value("update"), "500", "case-insensitive section+key")
expectEqual(doc.section(named: "MeasureCPU")?.value("updatedivider"), "2", "whitespace around = trimmed")
expectEqual(doc.section(named: "MeterText")?.value("text"), "CPU is %1% ; not a comment here",
            "mid-line semicolon kept")

// MARK: variable substitution

let vars = ["accent": "1,2,3", "size": "12"]
expectEqual(SkinSpec.substitute("color #Accent# end", variables: vars), "color 1,2,3 end",
            "variable replaced case-insensitively")
expectEqual(SkinSpec.substitute("#Unknown# stays", variables: vars), "#Unknown# stays",
            "unknown variable left intact")
expectEqual(SkinSpec.substitute("100% plain", variables: vars), "100% plain",
            "text without variables untouched")
expectEqual(SkinSpec.substitute("#accent##size#", variables: vars), "1,2,312",
            "adjacent variables")

// MARK: colors

expectEqual(SkinColor("255,128,0"), SkinColor(r: 1, g: 128.0/255, b: 0), "decimal RGB")
expectEqual(SkinColor("0,0,0,0")?.a, 0, "alpha component")
expectEqual(SkinColor("FF8000"), SkinColor(r: 1, g: 128.0/255, b: 0), "hex RGB")
expectEqual(SkinColor("FF800080")?.a, 128.0/255, "hex alpha")
expect(SkinColor("1,2") == nil, "two components rejected")
expect(SkinColor("ZZZZZZ") == nil, "bad hex rejected")

// MARK: calc evaluator

func calc(_ f: String, _ vals: [String: Double] = [:]) -> Double? {
    CalcEvaluator.evaluate(f) { vals[$0.lowercased()] }
}
expectEqual(calc("1 + 2 * 3"), 7, "precedence")
expectEqual(calc("(1 + 2) * 3"), 9, "parens")
expectEqual(calc("-4 + 10"), 6, "unary minus")
expectEqual(calc("10 / 4"), 2.5, "division")
expectEqual(calc("10 % 3"), 1, "modulo")
expectEqual(calc("A + B", ["a": 2, "b": 3]), 5, "identifiers resolve")
expect(calc("A + 1") == nil, "unknown identifier fails")
expect(calc("1 +") == nil, "trailing operator fails")
expect(calc("2 3") == nil, "garbage tail fails")
expectEqual(calc("5 / 0"), 0, "divide by zero yields 0")

// MARK: autoscale

expectEqual(AutoScale.format(512, decimals: 0), "512 B", "bytes")
expectEqual(AutoScale.format(2048, decimals: 1), "2.0 KB", "kilobytes")
expectEqual(AutoScale.format(3.5 * 1024 * 1024 * 1024, decimals: 1), "3.5 GB", "gigabytes")
expectEqual(AutoScale.format(-2048, decimals: 1), "-2.0 KB", "negative values")

// MARK: strftime

let fixed = Date(timeIntervalSince1970: 1_752_100_000) // 2025-07-09 22:26:40 UTC
let utc = TimeZone(identifier: "UTC")
expectEqual(TimeMeasure.strftime(format: "%H:%M:%S", date: fixed, timeZone: utc),
            "22:26:40", "time format")
expectEqual(TimeMeasure.strftime(format: "%Y-%m-%d", date: fixed, timeZone: utc),
            "2025-07-09", "date format")

// MARK: skin spec parsing

let spec = SkinSpec.parse(name: "Test", text: """
[Rainier]
Update=250
BackgroundColor=#BG#
ZPosition=Top

[Variables]
BG=10,20,30
W=100

[MeasureA]
Measure=Calc
Formula=1+1

[MeterA]
Meter=Bar
MeasureName=MeasureA
W=#W#
H=10

[MeterB]
Meter=Bar
X=0r
Y=4R
W=#W#
H=10
""")
expectEqual(spec.updateMs, 250, "update interval")
expectEqual(spec.background, SkinColor(r: 10.0/255, g: 20.0/255, b: 30.0/255), "background via variable")
expectEqual(spec.zPosition, "Top", "zposition")
expectEqual(spec.measures.count, 1, "one measure")
expectEqual(spec.meters.count, 2, "two meters")
expectEqual(spec.meters[0].options.double("w"), 100, "variable in meter option")

// MARK: layout (relative coordinates) + calc through a real skin

let skin = Skin(spec: spec, folder: URL(fileURLWithPath: "/tmp"))
expectEqual(skin.measures.first?.value, 2, "calc measure evaluated on load")
let meterA = skin.meters[0], meterB = skin.meters[1]
expectEqual(meterA.frame, CGRect(x: 0, y: 0, width: 100, height: 10), "absolute placement")
expectEqual(meterB.frame, CGRect(x: 0, y: 14, width: 100, height: 10), "0r/4R relative placement")
expectEqual(skin.contentSize, CGSize(width: 100, height: 24), "content size is meter union")

// MARK: min/max update clamp

let minSpec = SkinSpec.parse(name: "T", text: """
[MeasureC]
Measure=Calc
Formula=50
MinValue=0
MaxValue=200
""")
let skin2 = Skin(spec: minSpec, folder: URL(fileURLWithPath: "/tmp"))
expectEqual(skin2.measures[0].relativeValue, 0.25, "relative value against min/max")

// MARK: config round-trip

let home = FileManager.default.temporaryDirectory
    .appendingPathComponent("rainier-test-\(ProcessInfo.processInfo.processIdentifier)")
setenv("RAINIER_HOME", home.path, 1)
var config = RainierConfig()
config.enabled = ["Clock"]
config.positions["Clock"] = [12, 34]
RainierHome.save(config)
let loaded = RainierHome.loadConfig()
expectEqual(loaded.enabled ?? [], ["Clock"], "config enabled round-trip")
expectEqual(loaded.positions["Clock"] ?? [], [12, 34], "config positions round-trip")
try? FileManager.default.removeItem(at: home)

print(failures == 0 ? "OK — \(count) assertions passed"
                    : "\(failures)/\(count) assertions FAILED")
exit(failures == 0 ? 0 : 1)
