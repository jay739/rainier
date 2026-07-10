import Foundation

/// Seconds since boot, displayed as "3d 4h 12m".
public final class UptimeMeasure: Measure {
    public override func update() {
        var boot = timeval()
        var len = MemoryLayout<timeval>.size
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        guard sysctl(&mib, 2, &boot, &len, nil, 0) == 0 else { return }
        let seconds = Date().timeIntervalSince1970 - Double(boot.tv_sec)
        value = seconds
        let days = Int(seconds) / 86400
        let hours = Int(seconds) % 86400 / 3600
        let minutes = Int(seconds) % 3600 / 60
        stringOverride = days > 0
            ? "\(days)d \(hours)h \(minutes)m"
            : (hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
    }
}
