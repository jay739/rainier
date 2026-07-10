import Foundation

/// Disk space for a mounted path. `Drive=/` (default), reports bytes:
/// `Type=Free|Used|Total|Percent` (default Free; Percent is used-percent).
public final class DiskMeasure: Measure {
    private let path: String
    private let type: String

    public override init(name: String, options: Options) {
        self.path = options.str("drive", default: "/")
        self.type = options.str("type", default: "Free").lowercased()
        super.init(name: name, options: options)
    }

    public override func update() {
        var fs = statfs()
        guard statfs(path, &fs) == 0 else { return }
        let block = Double(fs.f_bsize)
        let total = Double(fs.f_blocks) * block
        let free = Double(fs.f_bavail) * block
        let used = total - free
        if options.str("maxvalue") == nil {
            maxValue = type == "percent" ? 100 : total
        }
        switch type {
        case "used":    value = used
        case "total":   value = total
        case "percent": value = total > 0 ? used / total * 100 : 0
        default:        value = free
        }
    }
}
