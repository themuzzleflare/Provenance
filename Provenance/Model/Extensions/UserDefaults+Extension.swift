import Foundation
import SwiftyBeaver

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")!

extension UserDefaults {
    @objc dynamic var apiKey: String {
        get { string(forKey: "apiKey") ?? "" }
        set {
            setValue(newValue, forKey: "apiKey")
            log.info("set apiKey: \(newValue)")
        }
    }

    @objc dynamic var dateStyle: String {
        get { string(forKey: "dateStyle") ?? "Absolute" }
        set {
            setValue(newValue, forKey: "dateStyle")
            log.info("set dateStyle: \(newValue)")
        }
    }

    var appVersion: String {
        get { string(forKey: "appVersion") ?? "Unknown" }
    }

    var appBuild: String {
        get { string(forKey: "appBuild") ?? "Unknown" }
    }
}
