import UIKit
import WidgetKit
import NotificationBannerSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  // MARK: - Properties

  var window: UIWindow?
  private var submitActionProxy: UIAlertAction!
  private var textDidChangeObserver: NSObjectProtocol!
  private var savedShortcutItem: UIApplicationShortcutItem!

  // MARK: - Life Cycle

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    if let shortcutItem = connectionOptions.shortcutItem {
      savedShortcutItem = shortcutItem
    }
    window = UIWindow(windowScene: windowScene)
    window?.backgroundColor = .systemBackground
    window?.tintColor = .accentColor
    window?.rootViewController = TabBarController()
    window?.makeKeyAndVisible()
    checkApiKey()
  }

  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    let handled = handleShortcutItem(shortcutItem: shortcutItem)
    completionHandler(handled)
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    if savedShortcutItem != nil {
      _ = handleShortcutItem(shortcutItem: savedShortcutItem)
    }
    WidgetCenter.shared.reloadAllTimelines()
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
      let alertController = UIAlertController(
        title: "API Key Required",
        message: "You don't have an API Key set. You can set one now.",
        preferredStyle: .alert
      )
      alertController.addTextField { [self] (textField) in
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textDidChangeObserver = NotificationCenter.default.addObserver(
          forName: UITextField.textDidChangeNotification,
          object: textField,
          queue: .main,
          using: { (notification) in
            if let change = notification.object as? UITextField, let text = change.text {
              submitActionProxy.isEnabled = text.count >= 1 && text != appDefaults.apiKey
            } else {
              submitActionProxy.isEnabled = false
            }
          }
        )
      }
      let submitAction = UIAlertAction(
        title: "Save",
        style: .default,
        handler: { [self] (_) in
          if let answer = alertController.textFields?.first?.text {
            if !answer.isEmpty && answer != appDefaults.apiKey {
              UpFacade.ping(with: answer) { (error) in
                DispatchQueue.main.async {
                  switch error {
                  case .none:
                    let notificationBanner = GrowingNotificationBanner(
                      title: "Success",
                      subtitle: "The API Key was verified and saved.",
                      style: .success,
                      duration: 2.0
                    )
                    appDefaults.apiKey = answer
                    let viewController = NavigationController(rootViewController: SettingsVC(displayBanner: notificationBanner))
                    viewController.modalPresentationStyle = .fullScreen
                    window?.rootViewController?.present(viewController, animated: true)
                  default:
                    let notificationBanner = GrowingNotificationBanner(
                      title: "Failed",
                      subtitle: error!.description,
                      style: .danger,
                      duration: 2.0
                    )
                    let viewController = NavigationController(rootViewController: SettingsVC(displayBanner: notificationBanner))
                    viewController.modalPresentationStyle = .fullScreen
                    window?.rootViewController?.present(viewController, animated: true)
                  }
                }
              }
            } else {
              let notificationBanner = GrowingNotificationBanner(
                title: "Failed",
                subtitle: "The provided API Key was the same as the current one.",
                style: .danger,
                duration: 2.0
              )
              let viewController = NavigationController(rootViewController: SettingsVC(displayBanner: notificationBanner))
              viewController.modalPresentationStyle = .fullScreen
              window?.rootViewController?.present(viewController, animated: true)
            }
          }
        }
      )
      submitAction.isEnabled = false
      submitActionProxy = submitAction
      alertController.addAction(.cancel)
      alertController.addAction(submitAction)
      window?.rootViewController?.present(alertController, animated: true)
    }
  }

  private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
    if let tabBarController = window?.rootViewController as? TabBarController, let shortcutType = ShortcutType(rawValue: shortcutItem.type) {
      tabBarController.selectedIndex = shortcutType.tabBarItem.rawValue
    }
    return true
  }
}
