import UIKit
import Firebase
import FirebaseAnalytics
import Rswift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerDefaults()
        configureFirebase()

        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - Configuration

private extension AppDelegate {
    private func registerDefaults() {
        do {
            let settingsData = try Data(contentsOf: R.file.settingsBundle()!.appendingPathComponent("Root.plist"))
            let settingsPlist = try PropertyListSerialization.propertyList(from: settingsData, format: nil) as? [String: Any]
            let settingsPreferences = settingsPlist?["PreferenceSpecifiers"] as? [[String: Any]]
            
            var defaultsToRegister = [String: Any]()

            settingsPreferences?.forEach { preference in
                if let key = preference["Key"] as? String {
                    defaultsToRegister[key] = preference["DefaultValue"]
                }
            }

            appDefaults.register(defaults: defaultsToRegister)
        } catch {
            return
        }
    }

    private func configureFirebase() {
        FirebaseApp.configure()
        Analytics.load()
    }
}
