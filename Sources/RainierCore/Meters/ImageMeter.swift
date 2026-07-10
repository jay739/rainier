import Foundation
import AppKit

/// Draws an image from the skin folder. `ImageName=logo.png`,
/// optional `ImageAlpha=0…255`.
public final class ImageMeter: Meter {
    private let image: NSImage?
    private let alpha: CGFloat

    public init(name: String, options: Options, skinFolder: URL) {
        if let imageName = options.str("imagename") {
            let url = skinFolder.appendingPathComponent(imageName)
            self.image = NSImage(contentsOf: url)
        } else {
            self.image = nil
        }
        self.alpha = CGFloat(options.double("imagealpha", default: 255)) / 255
        super.init(name: name, options: options)
    }

    public override func desiredSize() -> CGSize {
        image?.size ?? CGSize(width: 32, height: 32)
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        image?.draw(in: frame, from: .zero, operation: .sourceOver,
                    fraction: alpha, respectFlipped: true, hints: nil)
    }
}
