#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

/// Borderless, transparent window that hosts one skin on the desktop.
final class SkinWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        applyZPosition(.desktop)
    }

    enum ZPosition: String {
        case desktop = "Desktop"   // above wallpaper, below icons and windows
        case normal = "Normal"
        case top = "Top"
    }

    func applyZPosition(_ z: ZPosition) {
        switch z {
        case .desktop:
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        case .normal:
            level = .normal
        case .top:
            level = .floating
        }
    }

    // Borderless windows refuse key status by default; allow it so drags and
    // clicks behave, but never steal focus on show.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
