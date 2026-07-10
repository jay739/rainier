import Foundation

public enum AutoScale {
    /// Format a byte (or byte/sec) count as "1.2 GB" style text, 1024-based.
    public static func format(_ value: Double, decimals: Int) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var v = abs(value)
        var unit = 0
        while v >= 1024, unit < units.count - 1 {
            v /= 1024
            unit += 1
        }
        let sign = value < 0 ? "-" : ""
        return sign + String(format: "%.\(decimals)f %@", v, units[unit])
    }
}
