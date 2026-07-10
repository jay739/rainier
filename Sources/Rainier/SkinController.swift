#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

/// Owns one skin's window and update timer.
final class SkinController: NSObject, NSWindowDelegate {
    let skin: Skin
    let window: SkinWindow
    private let view: SkinView
    private var timer: Timer?
    private var isProgrammaticResize = false
    var onMove: ((String, CGPoint) -> Void)?

    init(skin: Skin, origin: CGPoint?) {
        self.skin = skin
        let size = skin.contentSize
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let start = origin ?? CGPoint(x: screen.minX + 60,
                                      y: screen.maxY - size.height - 60)
        self.window = SkinWindow(contentRect: NSRect(origin: start, size: size))
        self.view = SkinView(frame: NSRect(origin: .zero, size: size))
        super.init()

        view.skin = skin
        window.contentView = view
        window.delegate = self
        if let z = SkinWindow.ZPosition(rawValue: skin.spec.zPosition) {
            window.applyZPosition(z)
        }
        window.orderFrontRegardless()

        let interval = Double(skin.spec.updateMs) / 1000
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = interval * 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func tick() {
        skin.tick()
        let size = skin.contentSize
        if abs(window.frame.width - size.width) > 0.5 ||
           abs(window.frame.height - size.height) > 0.5 {
            // Keep the window's top-left corner fixed while resizing.
            var frame = window.frame
            frame.origin.y = frame.maxY - size.height
            frame.size = size
            isProgrammaticResize = true
            window.setFrame(frame, display: true)
            isProgrammaticResize = false
            view.frame = NSRect(origin: .zero, size: size)
        }
        view.needsDisplay = true
    }

    func close() {
        timer?.invalidate()
        timer = nil
        window.close()
    }

    func windowDidMove(_ notification: Notification) {
        // Content-driven resizes shift the origin too; only user drags count.
        guard !isProgrammaticResize else { return }
        onMove?(skin.spec.name, window.frame.origin)
    }
}
