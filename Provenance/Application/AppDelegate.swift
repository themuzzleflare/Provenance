import UIKit
import Firebase
import FirebaseAnalytics
import Rswift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerDefaultsFromSettingsBundle()
        
        FirebaseApp.configure()
        Analytics.load()

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension AppDelegate {
    private func registerDefaultsFromSettingsBundle() {
        let settingsRootPlist = "Root.plist"
        let settingsPreferencesItems = "PreferenceSpecifiers"
        let settingsPreferenceKey = "Key"
        let settingsPreferenceDefaultValue = "DefaultValue"

        let settingsData = try! Data(contentsOf: R.file.settingsBundle()!.appendingPathComponent(settingsRootPlist))
        let settingsPlist = try! PropertyListSerialization.propertyList(
            from: settingsData,
            options: [],
            format: nil) as? [String: Any]
        let settingsPreferences = settingsPlist?[settingsPreferencesItems] as? [[String: Any]]

        var defaultsToRegister = [String: Any]()

        settingsPreferences?.forEach { preference in
            if let key = preference[settingsPreferenceKey] as? String {
                defaultsToRegister[key] = preference[settingsPreferenceDefaultValue]
            }
        }

        appDefaults.register(defaults: defaultsToRegister)
    }
}
