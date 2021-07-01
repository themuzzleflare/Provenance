import UIKit
import WidgetKit
import NotificationBannerSwift
import Rswift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?

    private weak var submitActionProxy: UIAlertAction?

    private var savedShortcutItem: UIApplicationShortcutItem!
    private var textDidChangeObserver: NSObjectProtocol!

    // MARK: - Life Cycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortcutItem = shortcutItem
        }

        let window = UIWindow(windowScene: windowScene)

        window.rootViewController = TabController()

        self.window = window

        window.makeKeyAndVisible()

        checkApiKey()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcutItem(shortcutItem: shortcutItem))
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if savedShortcutItem != nil {
            handleShortcutItem(shortcutItem: savedShortcutItem)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if savedShortcutItem != nil {
            savedShortcutItem = nil
        }
    }
}

// MARK: - Actions

private extension SceneDelegate {
    private func checkApiKey() {
        if appDefaults.apiKey.isEmpty {
            let ac = UIAlertController(title: "API Key Required", message: "You don't have an API Key set. You can set one now.", preferredStyle: .alert)

            ac.addTextField { [self] textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColour()

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

            cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")

            let submitAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
                let answer = ac.textFields![0]

                if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                    upApi.ping(with: answer.text!) { error in
                        switch error {
                            case .none:
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)

                                    notificationBanner.duration = 2

                                    appDefaults.apiKey = answer.text!
                                    WidgetCenter.shared.reloadAllTimelines()

                                    let vc = SettingsVC()

                                    vc.displayBanner = notificationBanner

                                    let vcNav = NavigationController(rootViewController: vc)

                                    vcNav.modalPresentationStyle = .fullScreen

                                    window?.rootViewController?.present(vcNav, animated: true)
                                }
                            default:
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                    notificationBanner.duration = 2

                                    let vc = SettingsVC()

                                    vc.displayBanner = notificationBanner

                                    let vcNav = NavigationController(rootViewController: vc)

                                    vcNav.modalPresentationStyle = .fullScreen

                                    window?.rootViewController?.present(vcNav, animated: true)
                                }
                        }
                    }
                } else {
                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)

                    notificationBanner.duration = 2

                    let vc = SettingsVC()

                    vc.displayBanner = notificationBanner

                    let vcNav = NavigationController(rootViewController: vc)

                    vcNav.modalPresentationStyle = .fullScreen

                    window?.rootViewController?.present(vcNav, animated: true)
                }
            }

            submitAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
            submitAction.isEnabled = false
            submitActionProxy = submitAction

            ac.addAction(cancelAction)
            ac.addAction(submitAction)

            window?.rootViewController?.present(ac, animated: true)
        }
    }
    
    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let tabcontroller = window?.rootViewController as? TabController,
           let actionTypeValue = ShortcutType(rawValue: shortcutItem.type) {
            switch actionTypeValue {
                case .transactions:
                    tabcontroller.selectedIndex = 0
                case .accounts:
                    tabcontroller.selectedIndex = 1
                case .tags:
                    tabcontroller.selectedIndex = 2
                case .categories:
                    tabcontroller.selectedIndex = 3
                case .about:
                    tabcontroller.selectedIndex = 4
            }
        }

        return true
    }
}
