import Foundation

/// One `[Section]` of an INI file. Keys are stored lowercased; lookups are
/// case-insensitive like Rainmeter's.
public struct INISection {
    public let name: String
    public var pairs: [String: String]

    public func value(_ key: String) -> String? { pairs[key.lowercased()] }
}

public struct INIDocument {
    /// Sections in file order (Rainmeter meter order is file order).
    public var sections: [INISection]

    public func section(named name: String) -> INISection? {
        let lower = name.lowercased()
        return sections.first { $0.name.lowercased() == lower }
    }
}

public enum INIParser {
    public static func parse(_ text: String) -> INIDocument {
        var sections: [INISection] = []
        var currentName: String?
        var currentPairs: [String: String] = [:]

        func flush() {
            if let name = currentName {
                sections.append(INISection(name: name, pairs: currentPairs))
            }
            currentPairs = [:]
        }

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(";") { continue }
            if line.hasPrefix("["), let close = line.firstIndex(of: "]") {
                flush()
                currentName = String(line[line.index(after: line.startIndex)..<close])
                continue
            }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            if !key.isEmpty, currentName != nil {
                currentPairs[key] = value
            }
        }
        flush()
        return INIDocument(sections: sections)
    }
}
