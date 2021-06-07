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

    private enum ShortcutAction: String {
        case transactions = "transactionsShortcut"
        case accounts = "accountsShortcut"
        case tags = "tagsShortcut"
        case categories = "categoriesShortcut"
    }

    // MARK: - Life Cycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
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
        if savedShortcutItem != nil {
            _ = handleShortcutItem(shortcutItem: savedShortcutItem)
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
            let ac = UIAlertController(title: "API Key Required", message: "You don't have an API Key set. Set one now.", preferredStyle: .alert)
            ac.addTextField { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColour()
                self.textDidChangeObserver = NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: textField,
                    queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            self.submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.apiKey
                        } else {
                            self.submitActionProxy!.isEnabled = false
                        }
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
            let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned self] _ in
                let answer = ac.textFields![0]
                if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.allHTTPHeaderFields = [
                        "Accept": "application/json",
                        "Authorization": "Bearer \(answer.text!)"
                    ]
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)
                                    notificationBanner.duration = 2
                                    appDefaults.apiKey = answer.text!
                                    window?.rootViewController?.present({let vc = NavigationController(rootViewController: {let vc = SettingsVC(style: .grouped);vc.displayBanner = notificationBanner;return vc}());vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The API Key could not be verified.", style: .danger)
                                    notificationBanner.duration = 2
                                    window?.rootViewController?.present({let vc = NavigationController(rootViewController: {let vc = SettingsVC(style: .grouped);vc.displayBanner = notificationBanner;return vc}());vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let notificationBanner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "The API Key could not be verified.", style: .danger)
                                notificationBanner.duration = 2
                                window?.rootViewController?.present({let vc = NavigationController(rootViewController: {let vc = SettingsVC(style: .grouped);vc.displayBanner = notificationBanner;return vc}());vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
                            }
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .resume()
                } else {
                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)
                    notificationBanner.duration = 2
                    window?.rootViewController?.present({let vc = NavigationController(rootViewController: {let vc = SettingsVC(style: .grouped);vc.displayBanner = notificationBanner;return vc}());vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
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
        let tabcontroller = window?.rootViewController as! TabBarController
        if let actionTypeValue = ShortcutAction(rawValue: shortcutItem.type) {
            switch actionTypeValue {
                case .transactions:
                    tabcontroller.selectedIndex = 0
                case .accounts:
                    tabcontroller.selectedIndex = 1
                case .tags:
                    tabcontroller.selectedIndex = 2
                case .categories:
                    tabcontroller.selectedIndex = 3
            }
        }
        return true
    }
}
