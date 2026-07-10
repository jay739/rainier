import Foundation
import CoreGraphics

/// Fill bar driven by the measure's relative (min…max) value.
/// `BarOrientation=Horizontal|Vertical` (default Horizontal).
public final class BarMeter: Meter {
    private let barColor: SkinColor
    private let vertical: Bool

    public override init(name: String, options: Options) {
        self.barColor = options.color("barcolor") ?? SkinColor(r: 0.3, g: 0.7, b: 1)
        self.vertical = options.str("barorientation", default: "Horizontal")
            .lowercased() == "vertical"
        super.init(name: name, options: options)
    }

    public override func desiredSize() -> CGSize {
        vertical ? CGSize(width: 12, height: 100) : CGSize(width: 100, height: 12)
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        let fraction = CGFloat(primaryMeasure?.relativeValue ?? 0)
        var fill = frame
        if vertical {
            // Grow upward: top-left coordinates, so shift origin down.
            fill.size.height = frame.height * fraction
            fill.origin.y = frame.maxY - fill.size.height
        } else {
            fill.size.width = frame.width * fraction
        }
        ctx.setFillColor(barColor.cgColor)
        ctx.fill(fill)
    }
}
