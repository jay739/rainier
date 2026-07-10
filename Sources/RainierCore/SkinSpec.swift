import Foundation

/// Typed access to one section's key/value options after variable substitution.
public struct Options {
    let pairs: [String: String]

    public func str(_ key: String) -> String? { pairs[key.lowercased()] }
    public func str(_ key: String, default def: String) -> String { str(key) ?? def }
    public func int(_ key: String) -> Int? { str(key).flatMap { Int($0) } }
    public func int(_ key: String, default def: Int) -> Int { int(key) ?? def }
    public func double(_ key: String) -> Double? { str(key).flatMap { Double($0) } }
    public func double(_ key: String, default def: Double) -> Double { double(key) ?? def }
    public func bool(_ key: String) -> Bool { (int(key) ?? 0) != 0 }
    public func color(_ key: String) -> SkinColor? { str(key).flatMap { SkinColor($0) } }
}

public struct SectionSpec {
    public let name: String
    public let type: String        // value of Measure= / Meter=
    public let options: Options
}

public struct SkinSpec {
    public var name: String
    public var updateMs: Int
    public var background: SkinColor?
    public var cornerRadius: Double
    public var zPosition: String
    public var padding: Double
    public var measures: [SectionSpec]
    public var meters: [SectionSpec]

    /// Parse INI text into a skin spec, applying #Variable# substitution.
    public static func parse(name: String, text: String) -> SkinSpec {
        let doc = INIParser.parse(text)

        var variables = doc.section(named: "Variables")?.pairs ?? [:]
        // Resolve variables that reference other variables (bounded passes).
        for _ in 0..<10 {
            var changed = false
            for (k, v) in variables {
                let sub = substitute(v, variables: variables)
                if sub != v { variables[k] = sub; changed = true }
            }
            if !changed { break }
        }

        var measures: [SectionSpec] = []
        var meters: [SectionSpec] = []
        var meta: INISection?

        for section in doc.sections {
            let lower = section.name.lowercased()
            if lower == "rainier" || lower == "rainmeter" { meta = section; continue }
            if lower == "variables" { continue }
            var pairs: [String: String] = [:]
            for (k, v) in section.pairs { pairs[k] = substitute(v, variables: variables) }
            let options = Options(pairs: pairs)
            if let type = pairs["measure"] {
                measures.append(SectionSpec(name: section.name, type: type, options: options))
            } else if let type = pairs["meter"] {
                meters.append(SectionSpec(name: section.name, type: type, options: options))
            }
        }

        var metaPairs: [String: String] = [:]
        if let meta { for (k, v) in meta.pairs { metaPairs[k] = substitute(v, variables: variables) } }
        let metaOptions = Options(pairs: metaPairs)

        return SkinSpec(
            name: name,
            updateMs: max(100, metaOptions.int("update", default: 1000)),
            background: metaOptions.color("backgroundcolor"),
            cornerRadius: metaOptions.double("cornerradius", default: 0),
            zPosition: metaOptions.str("zposition", default: "Desktop"),
            padding: metaOptions.double("padding", default: 0),
            measures: measures,
            meters: meters
        )
    }

    /// Replace #VarName# references. Unknown variables are left intact.
    public static func substitute(_ value: String, variables: [String: String]) -> String {
        guard value.contains("#") else { return value }
        var result = ""
        var rest = Substring(value)
        while let open = rest.firstIndex(of: "#") {
            result += rest[..<open]
            let afterOpen = rest.index(after: open)
            guard let close = rest[afterOpen...].firstIndex(of: "#") else {
                result += rest[open...]
                return result
            }
            let name = String(rest[afterOpen..<close]).lowercased()
            if let replacement = variables[name] {
                result += replacement
                rest = rest[rest.index(after: close)...]
            } else {
                // Not a known variable: keep the leading '#' literally and
                // continue scanning from the next character.
                result += String(rest[open])
                rest = rest[afterOpen...]
            }
        }
        result += rest
        return result
    }
}
