import Foundation

/// Current date/time formatted with strftime codes, like Rainmeter's Time
/// measure. `Format=%H:%M`, optional `TimeZone=America/New_York`.
public final class TimeMeasure: Measure {
    private let format: String
    private let timeZone: TimeZone?

    public override init(name: String, options: Options) {
        self.format = options.str("format", default: "%H:%M:%S")
        self.timeZone = options.str("timezone").flatMap { TimeZone(identifier: $0) }
        super.init(name: name, options: options)
    }

    public override func update() {
        let now = Date()
        value = now.timeIntervalSince1970
        stringOverride = Self.strftime(format: format, date: now, timeZone: timeZone)
    }

    public static func strftime(format: String, date: Date, timeZone: TimeZone?) -> String {
        var t = time_t(date.timeIntervalSince1970)
        var tm = tm()
        if let timeZone {
            // localtime_r honors the TZ env var; compute manually instead.
            var adjusted = t + time_t(timeZone.secondsFromGMT(for: date))
            gmtime_r(&adjusted, &tm)
        } else {
            localtime_r(&t, &tm)
        }
        var buffer = [CChar](repeating: 0, count: 256)
        let written = Foundation.strftime(&buffer, buffer.count, format, &tm)
        return written > 0 ? String(cString: buffer) : format
    }
}
