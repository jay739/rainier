#if canImport(RainierCore)
import RainierCore
#endif
import AppKit

/// Discovers skins in the Rainier home, seeds bundled examples on first run,
/// and keeps controllers + config in sync.
final class SkinManager {
    private(set) var available: [String] = []          // skin folder names
    private var controllers: [String: SkinController] = [:]
    private var config = RainierHome.loadConfig()
    private var cascadeCount = 0

    var activeNames: Set<String> { Set(controllers.keys) }

    func start() {
        seedIfNeeded()
        discover()
        let enabled = config.enabled ?? available   // first run: enable all
        for name in available where enabled.contains(name) {
            load(name: name)
        }
        persistEnabled()
    }

    private func seedIfNeeded() {
        let fm = FileManager.default
        let skinsDir = RainierHome.skinsURL
        let existing = (try? fm.contentsOfDirectory(atPath: skinsDir.path)) ?? []
        guard existing.isEmpty else { return }
        guard let bundled = bundledSkinsURL() else { return }
        try? fm.createDirectory(at: skinsDir, withIntermediateDirectories: true)
        for entry in (try? fm.contentsOfDirectory(at: bundled, includingPropertiesForKeys: nil)) ?? [] {
            let target = skinsDir.appendingPathComponent(entry.lastPathComponent)
            try? fm.copyItem(at: entry, to: target)
        }
    }

    /// Bundled skins ship in the app bundle's Resources/Skins; when running
    /// the bare binary from the repo, fall back to a Skins directory found
    /// next to (or above) the executable.
    private func bundledSkinsURL() -> URL? {
        let fm = FileManager.default
        if let resources = Bundle.main.resourceURL {
            let inBundle = resources.appendingPathComponent("Skins")
            if fm.fileExists(atPath: inBundle.path) { return inBundle }
        }
        var dir = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath().deletingLastPathComponent()
        for _ in 0..<4 {
            let candidate = dir.appendingPathComponent("Skins")
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        return nil
    }

    func discover() {
        let fm = FileManager.default
        let entries = (try? fm.contentsOfDirectory(
            at: RainierHome.skinsURL, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        available = entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { $0.lastPathComponent }
            .sorted()
    }

    func load(name: String) {
        guard controllers[name] == nil else { return }
        let folder = RainierHome.skinsURL.appendingPathComponent(name)
        guard let skin = try? SkinLoader.load(folder: folder) else {
            NSLog("Rainier: failed to load skin '%@'", name)
            return
        }
        var origin = config.positions[name].flatMap {
            $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil
        }
        if origin == nil {
            // Cascade skins that have never been placed so they don't stack.
            let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            origin = CGPoint(x: screen.minX + 60 + CGFloat(cascadeCount) * 40,
                             y: screen.maxY - skin.contentSize.height - 60 - CGFloat(cascadeCount) * 60)
            cascadeCount += 1
        }
        let controller = SkinController(skin: skin, origin: origin)
        controller.onMove = { [weak self] name, point in
            guard let self else { return }
            self.config.positions[name] = [point.x, point.y]
            RainierHome.save(self.config)
        }
        controllers[name] = controller
    }

    func unload(name: String) {
        controllers[name]?.close()
        controllers[name] = nil
    }

    func toggle(name: String) {
        controllers[name] != nil ? unload(name: name) : load(name: name)
        persistEnabled()
    }

    func refreshAll() {
        let names = Array(controllers.keys)
        for name in names { unload(name: name) }
        discover()
        for name in names where available.contains(name) { load(name: name) }
    }

    private func persistEnabled() {
        config.enabled = available.filter { controllers[$0] != nil }
        RainierHome.save(config)
    }
}
