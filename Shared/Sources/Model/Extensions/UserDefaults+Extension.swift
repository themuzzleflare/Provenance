import Foundation
import WidgetKit

let appDefaults = UserDefaults.provenance

extension UserDefaults {
  /// A `UserDefaults` instance for the application group. Observations should be made on a stored variable of this value.
  static var provenance: UserDefaults {
    return UserDefaults(suiteName: "group.cloud.tavitian.provenance") ?? .standard
  }

  /// The string of the "apiKey" key.
  @objc dynamic var apiKey: String {
    get {
      return string(forKey: Keys.apiKey) ?? ""
    }
    set {
      setValue(newValue, forKey: Keys.apiKey)
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  /// The integer of the "dateStyle" key.
  @objc dynamic var dateStyle: Int {
    get {
      return integer(forKey: Keys.dateStyle)
    }
    set {
      setValue(newValue, forKey: Keys.dateStyle)
      WidgetCenter.shared.reloadTimelines(ofKind: "latestTransactionWidget")
    }
  }

  /// The last selected account for the account balance widget.
  var selectedAccount: String? {
    get {
      return string(forKey: Keys.selectedAccount)
    }
    set {
      setValue(newValue, forKey: Keys.selectedAccount)
    }
  }

  /// The configured `AppDateStyle` enumeration based on the integer of the "dateStyle" key.
  var appDateStyle: AppDateStyle {
    get {
      return AppDateStyle(rawValue: dateStyle) ?? .absolute
    }
    set {
      dateStyle = newValue.rawValue
    }
  }

  /// The short version string of the application.
  var appVersion: String {
    return string(forKey: Keys.appVersion) ?? "Unknown"
  }

  /// The build number of the application.
  var appBuild: String {
    return string(forKey: Keys.appBuild) ?? "Unknown"
  }
}

extension UserDefaults {
  private struct Keys {
    static let apiKey = "apiKey"
    static let dateStyle = "dateStyle"
    static let selectedAccount = "selectedAccount"
    static let appVersion = "appVersion"
    static let appBuild = "appBuild"
  }
}
