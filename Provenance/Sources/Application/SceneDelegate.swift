import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  // MARK: - Properties

  var window: UIWindow?
  var submitActionProxy: UIAlertAction!
  var textDidChangeObserver: NSObjectProtocol!

  // MARK: - Life Cycle

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    window = UIWindow(windowScene: windowScene)
    window?.backgroundColor = .systemBackground
    window?.tintColor = .accentColor
    window?.rootViewController = TabBarController()
    window?.makeKeyAndVisible()

    if let shortcutItem = connectionOptions.shortcutItem {
      self.windowScene(windowScene, performActionFor: shortcutItem) { (_) in }
    }

    connectionOptions.userActivities.forEach { self.scene(scene, continue: $0) }

    self.scene(scene, openURLContexts: connectionOptions.urlContexts)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let tabBarController = self.window?.rootViewController as? TabBarController else { return }
    tabBarController.restoreUserActivityState(userActivity)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url.absoluteString else { return }
    let accountId = url.replacingOccurrences(of: "provenance://accounts/", with: "")
    Up.retrieveAccount(for: accountId) { (result) in
      switch result {
      case let .success(account):
        if let tabBarController = self.window?.rootViewController as? TabBarController,
           let navigationController = tabBarController.selectedViewController as? NavigationController {
          let viewController = TransactionsByAccountVC(account: account)
          navigationController.pushViewController(viewController, animated: true)
        }
      case .failure:
        break
      }
    }
  }

  func windowScene(_ windowScene: UIWindowScene,
                   performActionFor shortcutItem: UIApplicationShortcutItem,
                   completionHandler: @escaping (Bool) -> Void) {
    guard let tabBarController = window?.rootViewController as? TabBarController,
          let shortcutType = ShortcutType(rawValue: shortcutItem.type)
    else {
      completionHandler(false)
      return
    }
    tabBarController.selectedIndex = shortcutType.tabBarItem.rawValue
    completionHandler(true)
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    checkApiKey()
    WidgetCenter.shared.reloadAllTimelines()
  }
}

// MARK: - Actions

extension SceneDelegate {
  private func checkApiKey() {
    if App.userDefaults.apiKey.isEmpty {
      let alertController = UIAlertController.noApiKey(self)
      window?.rootViewController?.present(alertController, animated: true)
    }
  }
}
