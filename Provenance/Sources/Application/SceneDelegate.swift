import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties
  
  var window: UIWindow?
  var submitActionProxy: UIAlertAction!
  var textDidChangeObserver: NSObjectProtocol!
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
  
  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivity.addedTagsToTransaction.activityType, let intentResponse = userActivity.interaction?.intentResponse as? AddTagToTransactionIntentResponse, let transaction = intentResponse.transaction?.identifier else { return }
    UpFacade.retrieveTransaction(for: transaction) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          if let tabBarController = self.window?.rootViewController as? TabBarController, let navigationController = tabBarController.selectedViewController as? NavigationController {
            let viewController = TransactionTagsVC(transaction: transaction)
            navigationController.pushViewController(viewController, animated: true)
          }
        case .failure:
          break
        }
      }
    }
  }
  
  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    let completion = handleShortcutItem(shortcutItem: shortcutItem)
    completionHandler(completion)
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

extension SceneDelegate {
  private func checkApiKey() {
    if ProvenanceApp.userDefaults.apiKey.isEmpty {
      let alertController = UIAlertController.noApiKey(self)
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
