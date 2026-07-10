#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

final class SkinView: NSView {
    var skin: Skin?

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        skin?.draw(in: ctx)
    }
}
