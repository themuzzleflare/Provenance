import UIKit
import Firebase
import SwiftDate
import AlamofireNetworkActivityIndicator
import Keys

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  // MARK: - Life Cycle

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    NetworkActivityIndicatorManager.shared.isEnabled = true
    SwiftDate.defaultRegion = .current
    configureFirebase()
    registerDefaults()
    return true
  }

  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}

// MARK: - Configuration

extension AppDelegate {
  private func registerDefaults() {
    do {
      let settingsData = try Data(contentsOf: .settingsBundle.appendingPathComponent("Root.plist"))
      let settingsPlist = try PropertyListSerialization.propertyList(from: settingsData, format: nil) as? [String: Any]
      let settingsPreferences = settingsPlist?["PreferenceSpecifiers"] as? [[String: Any]]

      var defaults = [String: Any]()

      settingsPreferences?.forEach { (preference) in
        if let key = preference["Key"] as? String {
          defaults[key] = preference["DefaultValue"]
        }
      }

      UserDefaults.provenance.register(defaults: defaults)
#if DEBUG
      UserDefaults.provenance.apiKey = ProvenanceKeys().upAPIToken
      dump(UserDefaults.provenance.dictionaryWithValues(forKeys: UserDefaults.Keys.all))
#endif
    } catch {
      fatalError(error.localizedDescription)
    }
  }

  private func configureFirebase() {
    let providerFactory = ProvenanceAppCheckProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)
    FirebaseApp.configure()
  }
}
