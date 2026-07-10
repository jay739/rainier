import Foundation

/// Total CPU usage percent (0–100) from host tick deltas.
public final class CPUMeasure: Measure {
    private var previous: (busy: UInt64, total: UInt64)?

    public override init(name: String, options: Options) {
        super.init(name: name, options: options)
        if options.str("maxvalue") == nil { maxValue = 100 }
    }

    public override func update() {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let user = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2)
        let nice = UInt64(info.cpu_ticks.3)
        let busy = user + system + nice
        let total = busy + idle
        if let previous, total > previous.total {
            let dBusy = Double(busy - previous.busy)
            let dTotal = Double(total - previous.total)
            value = dTotal > 0 ? dBusy / dTotal * 100 : 0
        }
        previous = (busy, total)
    }
}
