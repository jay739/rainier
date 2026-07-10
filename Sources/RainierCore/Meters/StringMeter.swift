import Foundation
import AppKit

/// Text display. `Text=CPU %1` with %1…%9 for bound measures, plus inline
/// `[MeasureName]` references. AutoScale=1 formats byte values.
public final class StringMeter: Meter {
    private let template: String
    private let decimals: Int
    private let autoScale: Bool
    private let prefix: String
    private let postfix: String
    private let align: String
    private let font: NSFont
    private let color: SkinColor

    /// Skin-provided lookup for inline [MeasureName] references.
    var inlineResolver: ((String) -> Measure?)?

    public override init(name: String, options: Options) {
        self.template = options.str("text", default: "%1")
        self.decimals = options.int("numofdecimals", default: 0)
        self.autoScale = options.bool("autoscale")
        self.prefix = options.str("prefix", default: "")
        self.postfix = options.str("postfix", default: "")
        self.align = options.str("stringalign", default: "Left").lowercased()
        self.color = options.color("fontcolor") ?? SkinColor(r: 1, g: 1, b: 1)

        let size = CGFloat(options.double("fontsize", default: 12))
        let style = options.str("stringstyle", default: "Normal").lowercased()
        var base: NSFont
        if let face = options.str("fontface"), !face.isEmpty,
           let named = NSFont(name: face, size: size) {
            base = named
        } else {
            // Monospaced digits keep live values from jittering as they tick.
            base = NSFont.monospacedDigitSystemFont(
                ofSize: size, weight: style.contains("bold") ? .semibold : .regular)
        }
        if style.contains("bold"), !base.fontDescriptor.symbolicTraits.contains(.bold) {
            base = NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
        }
        if style.contains("italic") {
            base = NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
        }
        self.font = base
        super.init(name: name, options: options)
    }

    private func formatted(_ measure: Measure) -> String {
        if let text = measure.stringOverride { return text }
        if autoScale { return AutoScale.format(measure.value, decimals: decimals) }
        return String(format: "%.\(decimals)f", measure.value)
    }

    func resolvedText() -> String {
        var text = template
        for (index, measure) in measures.enumerated().reversed() {
            text = text.replacingOccurrences(of: "%\(index + 1)", with: formatted(measure))
        }
        // Inline [MeasureName] references.
        while let open = text.firstIndex(of: "["),
              let close = text[open...].firstIndex(of: "]") {
            let inner = String(text[text.index(after: open)..<close])
            guard let measure = inlineResolver?(inner) else { break }
            text.replaceSubrange(open...close, with: formatted(measure))
        }
        return prefix + text + postfix
    }

    private func attributed() -> NSAttributedString {
        NSAttributedString(string: resolvedText(), attributes: [
            .font: font,
            .foregroundColor: NSColor(srgbRed: color.r, green: color.g,
                                      blue: color.b, alpha: color.a),
        ])
    }

    public override func desiredSize() -> CGSize {
        let size = attributed().size()
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    public override func anchorOffset(for size: CGSize) -> CGFloat {
        switch align {
        case "right":  return -size.width
        case "center": return -size.width / 2
        default:       return 0
        }
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        attributed().draw(at: frame.origin)
    }
}
