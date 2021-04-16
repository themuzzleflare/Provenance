import UIKit
import WidgetKit
import Rswift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    weak var submitActionProxy: UIAlertAction?

    private var savedShortCutItem: UIApplicationShortcutItem!
    private var textDidChangeObserver: NSObjectProtocol!

    let viewController = TabBarController()
    let settingsController = SettingsVC(style: .grouped)

    private enum ActionType: String {
        case accountsAction = "cloud.tavitian.provenance.accounts"
        case tagsAction = "cloud.tavitian.provenance.tags"
        case categoriesAction = "cloud.tavitian.provenance.categories"
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortCutItem = shortcutItem
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = viewController
        self.window = window
        window.makeKeyAndVisible()

        initialSetup()
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortCutItem(shortcutItem: shortcutItem)
        completionHandler(handled)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if savedShortCutItem != nil {
            _ = handleShortCutItem(shortcutItem: savedShortCutItem)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        savedShortCutItem = nil
    }
}

extension SceneDelegate {
    private func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let tabcontrol = window?.rootViewController as! TabBarController

        if let actionTypeValue = ActionType(rawValue: shortcutItem.type) {
            switch actionTypeValue {
                case .accountsAction:
                    tabcontrol.selectedIndex = 1
                case .tagsAction:
                    tabcontrol.selectedIndex = 2
                case .categoriesAction:
                    tabcontrol.selectedIndex = 3
            }
        }
        return true
    }

    private func initialSetup() {
        if appDefaults.string(forKey: "dateStyle") == nil {
            appDefaults.setValue("Absolute", forKey: "dateStyle")
        }

        if appDefaults.string(forKey: "apiKey") == "" || appDefaults.string(forKey: "apiKey") == nil {
            let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

            let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
            let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

            let titleAttrString = NSMutableAttributedString(string: "API Key Required", attributes: titleFont)
            let messageAttrString = NSMutableAttributedString(string: "You don't have an API Key set. Set one now.", attributes: messageFont)

            ac.setValue(titleAttrString, forKey: "attributedTitle")
            ac.setValue(messageAttrString, forKey: "attributedMessage")

            ac.addTextField(configurationHandler: { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.isSecureTextEntry = false
                textField.tintColor = R.color.accentColor()
                textField.text = appDefaults.string(forKey: "apiKey") ?? nil

                self.textDidChangeObserver = NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: textField,
                    queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            self.submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.string(forKey: "apiKey")
                        } else {
                            self.submitActionProxy!.isEnabled = false
                        }
                    }
                }
            })

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

            let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                let answer = ac.textFields![0]

                if (answer.text != "" && answer.text != nil) && answer.text != appDefaults.string(forKey: "apiKey") {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!

                    var request = URLRequest(url: url)

                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.addValue("Bearer \(answer.text!)", forHTTPHeaderField: "Authorization")

                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode

                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    appDefaults.set(answer.text!, forKey: "apiKey")

                                    self.window?.rootViewController?.present(NavigationController(rootViewController: self.settingsController), animated: true)

                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                    let messageAttrString = NSMutableAttributedString(string: "The API Key could not be verified.", attributes: messageFont)

                                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                                    ac.setValue(messageAttrString, forKey: "attributedMessage")

                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                                        self.window?.rootViewController?.present(NavigationController(rootViewController: self.settingsController), animated: true)
                                    })

                                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                    ac.addAction(dismissAction)

                                    self.window?.rootViewController?.present(ac, animated: true)

                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "The API Key could not be verified.", attributes: messageFont)

                                ac.setValue(titleAttrString, forKey: "attributedTitle")
                                ac.setValue(messageAttrString, forKey: "attributedMessage")

                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                                    self.window?.rootViewController?.present(NavigationController(rootViewController: self.settingsController), animated: true)
                                })

                                dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                ac.addAction(dismissAction)

                                self.window?.rootViewController?.present(ac, animated: true)

                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                    .resume()
                } else {
                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                    let messageAttrString = NSMutableAttributedString(string: "The provided API Key was the same as the current one.", attributes: messageFont)

                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                    ac.setValue(messageAttrString, forKey: "attributedMessage")

                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                        self.window?.rootViewController?.present(NavigationController(rootViewController: self.settingsController), animated: true)
                    })
                    
                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                    ac.addAction(dismissAction)

                    self.window?.rootViewController?.present(ac, animated: true)

                    WidgetCenter.shared.reloadAllTimelines()
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
}
