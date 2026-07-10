#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var placeholder: SkinWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "☔️"
        statusItem.menu = buildMenu()
        showPlaceholder()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Rainier \(RainierVersion.string)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Rainier", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private func showPlaceholder() {
        let window = SkinWindow(contentRect: NSRect(x: 80, y: 200, width: 220, height: 60))
        let label = NSTextField(labelWithString: "Rainier is running")
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.frame = NSRect(x: 16, y: 18, width: 200, height: 24)
        let view = NSView(frame: window.contentLayoutRect)
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor(gray: 0, alpha: 0.55)
        view.layer?.cornerRadius = 10
        view.addSubview(label)
        window.contentView = view
        window.orderFrontRegardless()
        placeholder = window
    }
}
