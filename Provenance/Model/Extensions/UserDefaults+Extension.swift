import Foundation

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")!

extension UserDefaults {
    @objc dynamic var apiKey: String {
        get {
            return string(forKey: "apiKey") ?? ""
        }
        set {
            set(newValue, forKey: "apiKey")
            print("Set API Key to: \(newValue)")
        }
    }

    @objc dynamic var dateStyle: String {
        get {
            return string(forKey: "dateStyle") ?? "Absolute"
        }
        set {
            set(newValue, forKey: "dateStyle")
            print("Set Date Style to: \(newValue)")
        }
    }

    var appVersion: String {
        get {
            return string(forKey: "appVersion") ?? "Unknown"
        }
    }

    var appBuild: String {
        get {
            return string(forKey: "appBuild") ?? "Unknown"
        }
    }
}
