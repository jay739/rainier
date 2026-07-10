import Foundation
import CoreGraphics

/// A visual element. Coordinates are top-left based (the skin view is
/// flipped), matching Rainmeter.
open class Meter {
    public let name: String
    public let options: Options

    /// Raw X/Y specs; support Rainmeter relative forms "10r" (offset from the
    /// previous meter's origin) and "10R" (offset from its far edge).
    let xSpec: String
    let ySpec: String
    public let hidden: Bool
    let solidColor: SkinColor?
    let measureNames: [String]

    public internal(set) var frame: CGRect = .zero
    /// Resolved by the owning skin before update/draw.
    public internal(set) var measures: [Measure] = []

    public init(name: String, options: Options) {
        self.name = name
        self.options = options
        self.xSpec = options.str("x", default: "0")
        self.ySpec = options.str("y", default: "0")
        self.hidden = options.bool("hidden")
        self.solidColor = options.color("solidcolor")
        var names: [String] = []
        if let first = options.str("measurename") { names.append(first) }
        for i in 2...9 {
            if let extra = options.str("measurename\(i)") { names.append(extra) }
        }
        self.measureNames = names
    }

    var primaryMeasure: Measure? { measures.first }

    /// Size when W/H are absent. Subclasses override.
    open func desiredSize() -> CGSize { CGSize(width: 100, height: 12) }

    open func size() -> CGSize {
        let desired = desiredSize()
        return CGSize(width: options.double("w") ?? desired.width,
                      height: options.double("h") ?? desired.height)
    }

    /// Horizontal anchor shift (String alignment). 0 = none.
    open func anchorOffset(for size: CGSize) -> CGFloat { 0 }

    /// Called once per skin tick after measures update (e.g. graph sampling).
    open func update() {}

    open func draw(in ctx: CGContext) {
        if let solidColor {
            ctx.setFillColor(solidColor.cgColor)
            ctx.fill(frame)
        }
    }

    static func resolveCoordinate(_ spec: String, previous: CGRect,
                                  near: CGFloat, far: CGFloat) -> CGFloat {
        if spec.hasSuffix("R") {
            return far + CGFloat(Double(spec.dropLast()) ?? 0)
        }
        if spec.hasSuffix("r") {
            return near + CGFloat(Double(spec.dropLast()) ?? 0)
        }
        return CGFloat(Double(spec) ?? 0)
    }

    public func place(after previous: CGRect) {
        let size = size()
        var origin = CGPoint(
            x: Self.resolveCoordinate(xSpec, previous: previous,
                                      near: previous.minX, far: previous.maxX),
            y: Self.resolveCoordinate(ySpec, previous: previous,
                                      near: previous.minY, far: previous.maxY))
        origin.x += anchorOffset(for: size)
        frame = CGRect(origin: origin, size: size)
    }
}

public enum MeterFactory {
    public static func make(spec: SectionSpec, skinFolder: URL) -> Meter? {
        switch spec.type.lowercased() {
        case "string": return StringMeter(name: spec.name, options: spec.options)
        case "bar":    return BarMeter(name: spec.name, options: spec.options)
        case "line":   return LineMeter(name: spec.name, options: spec.options)
        case "image":  return ImageMeter(name: spec.name, options: spec.options,
                                         skinFolder: skinFolder)
        default:       return nil
        }
    }
}
