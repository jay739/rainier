import Foundation
import CoreGraphics

/// A loaded, running skin: measures + meters + layout.
public final class Skin {
    public let spec: SkinSpec
    public let folder: URL
    public private(set) var measures: [Measure] = []
    public private(set) var meters: [Meter] = []
    public private(set) var contentSize: CGSize = .zero

    public init(spec: SkinSpec, folder: URL) {
        self.spec = spec
        self.folder = folder

        var byName: [String: Measure] = [:]
        for measureSpec in spec.measures {
            guard let measure = MeasureFactory.make(spec: measureSpec) else { continue }
            measures.append(measure)
            byName[measure.name.lowercased()] = measure
        }
        let resolve: (String) -> Measure? = { byName[$0.lowercased()] }
        for measure in measures { measure.resolver = resolve }

        for meterSpec in spec.meters {
            guard let meter = MeterFactory.make(spec: meterSpec, skinFolder: folder) else { continue }
            meter.measures = meter.measureNames.compactMap(resolve)
            if let stringMeter = meter as? StringMeter { stringMeter.inlineResolver = resolve }
            meters.append(meter)
        }

        tick()
    }

    /// One update cycle: refresh measures, sample meters, recompute layout.
    public func tick() {
        for measure in measures { measure.tick() }
        for meter in meters { meter.update() }
        layout()
    }

    private func layout() {
        var previous = CGRect.zero
        var union = CGRect.zero
        for meter in meters {
            meter.place(after: previous)
            if !meter.hidden {
                previous = meter.frame
                union = union.union(meter.frame)
            }
        }
        let padding = CGFloat(spec.padding)
        if padding > 0 {
            for meter in meters {
                meter.frame = meter.frame.offsetBy(dx: padding, dy: padding)
            }
        }
        contentSize = CGSize(width: max(1, ceil(union.maxX) + padding * 2),
                             height: max(1, ceil(union.maxY) + padding * 2))
    }

    /// Draw into a flipped (top-left origin) context.
    public func draw(in ctx: CGContext) {
        if let background = spec.background {
            let rect = CGRect(origin: .zero, size: contentSize)
            let radius = CGFloat(spec.cornerRadius)
            ctx.setFillColor(background.cgColor)
            if radius > 0 {
                let path = CGPath(roundedRect: rect, cornerWidth: radius,
                                  cornerHeight: radius, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
            } else {
                ctx.fill(rect)
            }
        }
        for meter in meters where !meter.hidden {
            meter.draw(in: ctx)
        }
    }

    public func measure(named name: String) -> Measure? {
        let lower = name.lowercased()
        return measures.first { $0.name.lowercased() == lower }
    }
}

public enum SkinLoadError: Error, CustomStringConvertible {
    case noIniFile(URL)
    public var description: String {
        switch self {
        case .noIniFile(let url): return "no .ini file in \(url.path)"
        }
    }
}

public enum SkinLoader {
    /// Load a skin from a folder containing `skin.ini` (preferred) or any
    /// single `.ini` file.
    public static func load(folder: URL) throws -> Skin {
        let fm = FileManager.default
        let preferred = folder.appendingPathComponent("skin.ini")
        let iniURL: URL
        if fm.fileExists(atPath: preferred.path) {
            iniURL = preferred
        } else {
            let inis = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))?
                .filter { $0.pathExtension.lowercased() == "ini" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
            guard let first = inis.first else { throw SkinLoadError.noIniFile(folder) }
            iniURL = first
        }
        let text = try String(contentsOf: iniURL, encoding: .utf8)
        let spec = SkinSpec.parse(name: folder.lastPathComponent, text: text)
        return Skin(spec: spec, folder: folder)
    }
}
