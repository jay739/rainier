import Foundation

/// Persisted app state: which skins are enabled and where their windows sit.
public struct RainierConfig: Codable {
    /// Enabled skin folder names. nil = first run, enable everything found.
    public var enabled: [String]?
    /// Skin name -> [x, y] window origin in screen coordinates.
    public var positions: [String: [Double]]

    public init(enabled: [String]? = nil, positions: [String: [Double]] = [:]) {
        self.enabled = enabled
        self.positions = positions
    }
}

/// Locates the Rainier home directory and loads/saves config.json in it.
/// `RAINIER_HOME` overrides the default Application Support location so dev
/// and test runs never touch real state.
public enum RainierHome {
    public static var url: URL {
        if let override = ProcessInfo.processInfo.environment["RAINIER_HOME"] {
            return URL(fileURLWithPath: override)
        }
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Rainier")
    }

    public static var skinsURL: URL { url.appendingPathComponent("Skins") }
    public static var configURL: URL { url.appendingPathComponent("config.json") }

    public static func loadConfig() -> RainierConfig {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(RainierConfig.self, from: data) else {
            return RainierConfig()
        }
        return config
    }

    public static func save(_ config: RainierConfig) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(config) {
            try? data.write(to: configURL)
        }
    }
}
