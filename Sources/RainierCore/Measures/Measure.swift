import Foundation

/// A data source. Subclasses set `value` (and optionally `stringOverride`)
/// in `update()`.
open class Measure {
    public let name: String
    public let options: Options

    public internal(set) var value: Double = 0
    /// Non-nil when the measure is naturally textual (Time, Shell, …).
    public internal(set) var stringOverride: String?

    public var minValue: Double
    public var maxValue: Double
    /// When true, maxValue grows to the largest value seen (Net-style).
    var autoMax = false

    private let updateDivider: Int
    private var tickCount = 0

    /// Set by the owning Skin so Calc (and friends) can read sibling measures.
    public var resolver: ((String) -> Measure?)?

    public init(name: String, options: Options) {
        self.name = name
        self.options = options
        self.minValue = options.double("minvalue", default: 0)
        self.maxValue = options.double("maxvalue", default: 1)
        self.updateDivider = max(1, options.int("updatedivider", default: 1))
    }

    public final func tick() {
        defer { tickCount += 1 }
        guard tickCount % updateDivider == 0 else { return }
        update()
        if autoMax && value > maxValue { maxValue = value }
    }

    open func update() {}

    /// Value scaled into 0…1 against min/max, for bars and graphs.
    public var relativeValue: Double {
        let span = maxValue - minValue
        guard span > 0 else { return 0 }
        return min(1, max(0, (value - minValue) / span))
    }
}

public enum MeasureFactory {
    public static func make(spec: SectionSpec) -> Measure? {
        switch spec.type.lowercased() {
        case "cpu":      return CPUMeasure(name: spec.name, options: spec.options)
        case "memory":   return MemoryMeasure(name: spec.name, options: spec.options)
        case "time":     return TimeMeasure(name: spec.name, options: spec.options)
        case "net":      return NetMeasure(name: spec.name, options: spec.options)
        case "disk":     return DiskMeasure(name: spec.name, options: spec.options)
        case "battery":  return BatteryMeasure(name: spec.name, options: spec.options)
        case "uptime":   return UptimeMeasure(name: spec.name, options: spec.options)
        case "shell":    return ShellMeasure(name: spec.name, options: spec.options)
        case "calc":     return CalcMeasure(name: spec.name, options: spec.options)
        default:         return nil
        }
    }
}
