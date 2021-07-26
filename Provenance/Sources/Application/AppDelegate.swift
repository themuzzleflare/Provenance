import UIKit
import Firebase
import FirebaseAnalytics
import SwiftDate
import SwiftyBeaver
import Rswift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Life Cycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SwiftDate.defaultRegion = .current

        #if DEBUG
        log.addDestination(console)
        #endif

        registerDefaults()
        configureFirebase()

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}

// MARK: - Configuration

private extension AppDelegate {
    private func registerDefaults() {
        do {
            let settingsData = try Data(
                contentsOf: R.file.settingsBundle()!
                    .appendingPathComponent("Root.plist")
            )

            let settingsPlist = try PropertyListSerialization.propertyList(
                from: settingsData,
                format: nil) as? [String: Any]

            let settingsPreferences = settingsPlist?["PreferenceSpecifiers"] as? [[String: Any]]

            var defaults = [String: Any]()

            settingsPreferences?.forEach {
                (preference) in
                if let key = preference["Key"] as? String {
                    defaults[key] = preference["DefaultValue"]
                }
            }

            appDefaults.register(defaults: defaults)

            log.debug("registerDefaults succeeded")
        } catch {
            log.error("registerDefaults failed")

            return
        }
    }

    private func configureFirebase() {
        log.debug("configureFirebase")

        let providerFactory = MyAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        FirebaseApp.configure()
        Analytics.load()
    }
}
