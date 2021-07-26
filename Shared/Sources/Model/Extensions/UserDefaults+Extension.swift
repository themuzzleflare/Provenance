import Foundation
import WidgetKit
import SwiftyBeaver

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")
    ?? .standard

extension UserDefaults {
    @objc dynamic var apiKey: String {
        get { return string(forKey: "apiKey") ?? "" }
        set {
            setValue(
                newValue,
                forKey: "apiKey"
            )

            WidgetCenter.shared.reloadAllTimelines()

            log.info("set apiKey: \(newValue)")
        }
    }

    @objc dynamic var dateStyle: String {
        get { return string(forKey: "dateStyle") ?? "Absolute" }
        set {
            setValue(
                newValue,
                forKey: "dateStyle"
            )

            WidgetCenter.shared.reloadTimelines(ofKind: "latestTransactionWidget")

            log.info("set dateStyle: \(newValue)")
        }
    }

    var appVersion: String { return string(forKey: "appVersion") ?? "Unknown" }

    var appBuild: String { return string(forKey: "appBuild") ?? "Unknown" }
}
