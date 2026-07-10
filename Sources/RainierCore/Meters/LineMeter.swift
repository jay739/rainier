import Foundation
import CoreGraphics

/// Scrolling history graph of one measure. One sample per skin update.
/// `AutoScale=1` scales to the history's own peak instead of the measure's
/// min/max range.
public final class LineMeter: Meter {
    private let lineColor: SkinColor
    private let lineWidth: CGFloat
    private let autoScale: Bool
    private var history: [Double] = []
    private var capacity: Int

    public override init(name: String, options: Options) {
        self.lineColor = options.color("linecolor") ?? SkinColor(r: 0.3, g: 0.9, b: 0.5)
        self.lineWidth = CGFloat(options.double("linewidth", default: 1))
        self.autoScale = options.bool("autoscale")
        self.capacity = max(2, Int(options.double("w") ?? 120))
        super.init(name: name, options: options)
    }

    public override func desiredSize() -> CGSize {
        CGSize(width: CGFloat(capacity), height: 40)
    }

    public override func update() {
        guard let measure = primaryMeasure else { return }
        history.append(measure.value)
        if history.count > capacity { history.removeFirst(history.count - capacity) }
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        guard history.count > 1 else { return }

        let scaleMax: Double
        if autoScale {
            scaleMax = max(history.max() ?? 1, .leastNonzeroMagnitude)
        } else if let measure = primaryMeasure {
            scaleMax = max(measure.maxValue - measure.minValue, .leastNonzeroMagnitude)
        } else {
            scaleMax = 1
        }
        let baseline = primaryMeasure?.minValue ?? 0

        ctx.saveGState()
        ctx.clip(to: frame)
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineJoin(.round)
        let step = frame.width / CGFloat(capacity - 1)
        // Newest sample at the right edge.
        let offset = CGFloat(capacity - history.count) * step
        for (index, sample) in history.enumerated() {
            let fraction = min(1, max(0, (sample - baseline) / scaleMax))
            let point = CGPoint(
                x: frame.minX + offset + CGFloat(index) * step,
                y: frame.maxY - CGFloat(fraction) * frame.height)
            index == 0 ? ctx.move(to: point) : ctx.addLine(to: point)
        }
        ctx.strokePath()
        ctx.restoreGState()
    }
}
