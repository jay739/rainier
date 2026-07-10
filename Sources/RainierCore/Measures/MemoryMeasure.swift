import Foundation

/// Physical memory statistics. `Type=Used|Free|Total|Percent` (default Used).
/// Byte types report bytes; String meters with AutoScale=1 format them.
public final class MemoryMeasure: Measure {
    private let type: String
    private static let totalBytes: Double = {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return Double(size)
    }()

    public override init(name: String, options: Options) {
        self.type = options.str("type", default: "Used").lowercased()
        super.init(name: name, options: options)
        if options.str("maxvalue") == nil {
            maxValue = type == "percent" ? 100 : Self.totalBytes
        }
    }

    public override func update() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let pageSize = Double(vm_kernel_page_size)
        // Matches Activity Monitor's "memory used": app + wired + compressed.
        let used = Double(stats.active_count &+ stats.wire_count &+ stats.compressor_page_count) * pageSize
        switch type {
        case "free":    value = Self.totalBytes - used
        case "total":   value = Self.totalBytes
        case "percent": value = Self.totalBytes > 0 ? used / Self.totalBytes * 100 : 0
        default:        value = used
        }
    }
}
