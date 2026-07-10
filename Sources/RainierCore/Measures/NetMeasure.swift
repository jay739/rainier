import Foundation

/// Network throughput in bytes/sec via getifaddrs deltas.
/// `Type=In|Out` (default In), optional `Interface=en0` (default: all
/// non-loopback interfaces).
public final class NetMeasure: Measure {
    private let direction: String
    private let interface: String?
    private var previousBytes: UInt64?
    private var previousTime: TimeInterval?

    public override init(name: String, options: Options) {
        self.direction = options.str("type", default: "In").lowercased()
        self.interface = options.str("interface")
        super.init(name: name, options: options)
        if options.str("maxvalue") == nil { autoMax = true; maxValue = 1 }
    }

    public override func update() {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return }
        defer { freeifaddrs(addrs) }

        // Interface byte counters are 32-bit and wrap; sum in 64 bits but
        // track per-call totals so a wrap shows as a huge delta we discard.
        var total: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            defer { cursor = ifa.pointee.ifa_next }
            guard let addr = ifa.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_LINK),
                  let dataPtr = ifa.pointee.ifa_data else { continue }
            let ifName = String(cString: ifa.pointee.ifa_name)
            if let interface {
                guard ifName == interface else { continue }
            } else {
                guard !ifName.hasPrefix("lo") else { continue }
            }
            let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            total &+= UInt64(direction == "out" ? data.ifi_obytes : data.ifi_ibytes)
        }

        let now = Date().timeIntervalSince1970
        if let previousBytes, let previousTime, total >= previousBytes, now > previousTime {
            value = Double(total - previousBytes) / (now - previousTime)
        }
        previousBytes = total
        previousTime = now
    }
}
