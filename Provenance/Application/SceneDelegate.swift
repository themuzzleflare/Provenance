import UIKit
import WidgetKit
import NotificationBannerSwift
import SwiftyBeaver
import Rswift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?

    private var submitActionProxy: UIAlertAction?
    private var textDidChangeObserver: NSObjectProtocol!
    private var savedShortcutItem: UIApplicationShortcutItem!

    // MARK: - Life Cycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortcutItem = shortcutItem
        }

        let window = UIWindow(windowScene: windowScene)

        window.rootViewController = TabBarController()

        self.window = window

        window.makeKeyAndVisible()

        checkApiKey()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcutItem(shortcutItem: shortcutItem))
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        log.debug("sceneDidBecomeActive")

        if savedShortcutItem != nil {
            handleShortcutItem(shortcutItem: savedShortcutItem)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        log.debug("sceneWillResignActive")

        if savedShortcutItem != nil {
            savedShortcutItem = nil
        }
    }
}

// MARK: - Actions

private extension SceneDelegate {
    private func checkApiKey() {
        log.verbose("checkApiKey")

        if appDefaults.apiKey.isEmpty {
            let ac = UIAlertController(title: "API Key Required", message: "You don't have an API Key set. You can set one now.", preferredStyle: .alert)

            ac.addTextField { [self] textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColor()

                textDidChangeObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { notification in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.apiKey
                        } else {
                            submitActionProxy!.isEnabled = false
                        }
                    }
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

            let submitAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
                let answer = ac.textFields![0]

                if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                    Up.ping(with: answer.text!) { error in
                        DispatchQueue.main.async {
                            switch error {
                                case .none:
                                    let nb = GrowingNotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)

                                    nb.duration = 2

                                    appDefaults.apiKey = answer.text!

                                    let vcNav = NavigationController(rootViewController: SettingsVC(displayBanner: nb))

                                    vcNav.modalPresentationStyle = .fullScreen

                                    window?.rootViewController?.present(vcNav, animated: true)
                                default:
                                    let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                    nb.duration = 2

                                    let vcNav = NavigationController(rootViewController: SettingsVC(displayBanner: nb))

                                    vcNav.modalPresentationStyle = .fullScreen

                                    window?.rootViewController?.present(vcNav, animated: true)
                            }
                        }
                    }
                } else {
                    let nb = GrowingNotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)

                    nb.duration = 2

                    let vcNav = NavigationController(rootViewController: SettingsVC(displayBanner: nb))

                    vcNav.modalPresentationStyle = .fullScreen

                    window?.rootViewController?.present(vcNav, animated: true)
                }
            }

            submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
            submitAction.isEnabled = false
            submitActionProxy = submitAction

            ac.addAction(cancelAction)
            ac.addAction(submitAction)

            window?.rootViewController?.present(ac, animated: true)
        }
    }
    
    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        log.info("handleShortcutItem(shortcutItem: \(shortcutItem.localizedTitle))")
        
        if let tbc = window?.rootViewController as? TabBarController,
           let actionTypeValue = ShortcutType(rawValue: shortcutItem.type) {
            switch actionTypeValue {
                case .transactions:
                    tbc.selectedIndex = 0
                case .accounts:
                    tbc.selectedIndex = 1
                case .tags:
                    tbc.selectedIndex = 2
                case .categories:
                    tbc.selectedIndex = 3
                case .about:
                    tbc.selectedIndex = 4
            }
        }

        return true
    }
}
