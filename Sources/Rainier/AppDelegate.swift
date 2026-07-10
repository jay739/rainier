#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let manager = SkinManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "☔️"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        manager.start()
    }

    // Rebuild the menu each time it opens so the skin list stays current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(withTitle: "Rainier \(RainierVersion.string)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        manager.discover()
        if manager.available.isEmpty {
            menu.addItem(withTitle: "No skins found", action: nil, keyEquivalent: "")
        }
        for name in manager.available {
            let item = NSMenuItem(title: name, action: #selector(toggleSkin(_:)), keyEquivalent: "")
            item.target = self
            item.state = manager.activeNames.contains(name) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let refresh = NSMenuItem(title: "Refresh All", action: #selector(refreshAll), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        let openFolder = NSMenuItem(title: "Open Skins Folder", action: #selector(openSkinsFolder), keyEquivalent: "o")
        openFolder.target = self
        menu.addItem(openFolder)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Rainier", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func toggleSkin(_ sender: NSMenuItem) {
        manager.toggle(name: sender.title)
    }

    @objc private func refreshAll() {
        manager.refreshAll()
    }

    @objc private func openSkinsFolder() {
        try? FileManager.default.createDirectory(at: RainierHome.skinsURL,
                                                 withIntermediateDirectories: true)
        NSWorkspace.shared.open(RainierHome.skinsURL)
    }
}
