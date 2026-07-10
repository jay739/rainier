import Foundation
import IOKit.ps

/// Battery state via IOKit power sources. `Type=Percent|Charging` (default
/// Percent). On machines with no battery, Percent reads 100 and the string
/// is "AC".
public final class BatteryMeasure: Measure {
    private let type: String

    public override init(name: String, options: Options) {
        self.type = options.str("type", default: "Percent").lowercased()
        super.init(name: name, options: options)
        if options.str("maxvalue") == nil { maxValue = type == "charging" ? 1 : 100 }
    }

    public override func update() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?
                  .takeUnretainedValue() as? [String: Any] else {
            value = type == "charging" ? 0 : 100
            stringOverride = "AC"
            return
        }
        let capacity = info[kIOPSCurrentCapacityKey] as? Double ?? 0
        let max = info[kIOPSMaxCapacityKey] as? Double ?? 100
        let percent = max > 0 ? capacity / max * 100 : 0
        let charging = (info[kIOPSIsChargingKey] as? Bool) ?? false
        switch type {
        case "charging":
            value = charging ? 1 : 0
            stringOverride = charging ? "Charging" : "On battery"
        default:
            value = percent
            stringOverride = nil
        }
    }
}
