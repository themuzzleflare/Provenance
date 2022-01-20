import Foundation

typealias Info = InfoPlist

enum InfoPlist {
  static let cfBundleIdentifier: String = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""

  static let nsHumanReadableCopyright: String = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
}
