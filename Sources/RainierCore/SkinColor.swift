import Foundation
import CoreGraphics

/// Color in Rainmeter notation: "R,G,B[,A]" with 0–255 components, or a
/// hex string "RRGGBB[AA]".
public struct SkinColor: Equatable {
    public var r: Double, g: Double, b: Double, a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(",") {
            let parts = trimmed.split(separator: ",").map {
                Double($0.trimmingCharacters(in: .whitespaces))
            }
            guard parts.count >= 3, parts.allSatisfy({ $0 != nil }) else { return nil }
            let v = parts.compactMap { $0 }
            self.init(r: v[0] / 255, g: v[1] / 255, b: v[2] / 255,
                      a: v.count > 3 ? v[3] / 255 : 1)
            return
        }
        let hex = trimmed.uppercased()
        guard hex.count == 6 || hex.count == 8,
              hex.allSatisfy({ $0.isHexDigit }) else { return nil }
        func byte(_ i: Int) -> Double {
            let start = hex.index(hex.startIndex, offsetBy: i * 2)
            let end = hex.index(start, offsetBy: 2)
            return Double(UInt8(hex[start..<end], radix: 16) ?? 0) / 255
        }
        self.init(r: byte(0), g: byte(1), b: byte(2),
                  a: hex.count == 8 ? byte(3) : 1)
    }

    public var cgColor: CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
}
