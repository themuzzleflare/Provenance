import UIKit
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  // MARK: - Properties

  var window: UIWindow?

  // MARK: - Life Cycle

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    self.window = .provenance(windowScene)

    if let shortcutItem = connectionOptions.shortcutItem {
      self.windowScene(windowScene, performActionFor: shortcutItem) { (_) in }
    }

    connectionOptions.userActivities.forEach { self.scene(scene, continue: $0) }

    self.scene(scene, openURLContexts: connectionOptions.urlContexts)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let incomingURL = userActivity.webpageURL,
       let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
       let path = components.path {
      if path.hasPrefix("/transactions") {
        let transactionId = path.replacingOccurrences(of: "/transactions/", with: "")
        if transactionId == path {
          if let tabBarController = self.window?.rootViewController as? TabBarController {
            tabBarController.selectedIndex = 0
          }
        } else {
          Up.retrieveTransaction(for: transactionId) { (result) in
            switch result {
            case let .success(transaction):
              if let tabBarController = self.window?.rootViewController as? TabBarController,
                 let navigationController = tabBarController.selectedViewController as? NavigationController {
                let viewController = TransactionDetailVC(transaction: transaction)
                navigationController.pushViewController(viewController, animated: true)
              }
            case .failure:
              break
            }
          }
        }
      } else if path.hasPrefix("/accounts") {
        let accountId = path.replacingOccurrences(of: "/accounts/", with: "")
        if accountId == path {
          if let tabBarController = self.window?.rootViewController as? TabBarController {
            tabBarController.selectedIndex = 1
          }
        } else {
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
      } else if path.hasPrefix("/tags") {
        let tagId = path.replacingOccurrences(of: "/tags/", with: "")
        if tagId == path {
          if let tabBarController = self.window?.rootViewController as? TabBarController {
            tabBarController.selectedIndex = 2
          }
        } else {
          Up.listTags { (result) in
            switch result {
            case let .success(tags):
              if let tabBarController = self.window?.rootViewController as? TabBarController,
                 let navigationController = tabBarController.selectedViewController as? NavigationController,
                 let tag = tags.first(where: { $0.id == tagId }) {
                let viewController = TransactionsByTagVC(tag: tag)
                navigationController.pushViewController(viewController, animated: true)
              }
            case .failure:
              break
            }
          }
        }
      } else if path.hasPrefix("/categories") {
        let categoryId = path.replacingOccurrences(of: "/categories/", with: "")
        if categoryId == path {
          if let tabBarController = self.window?.rootViewController as? TabBarController {
            tabBarController.selectedIndex = 3
          }
        } else {
          Up.retrieveCategory(for: categoryId) { (result) in
            switch result {
            case let .success(category):
              if let tabBarController = self.window?.rootViewController as? TabBarController,
                 let navigationController = tabBarController.selectedViewController as? NavigationController {
                let viewController = TransactionsByCategoryVC(category: category)
                navigationController.pushViewController(viewController, animated: true)
              }
            case .failure:
              break
            }
          }
        }
      } else if path.hasPrefix("/about") {
        if let tabBarController = self.window?.rootViewController as? TabBarController {
          tabBarController.selectedIndex = 4
        }
      }
    }
    guard let tabBarController = self.window?.rootViewController as? TabBarController else { return }
    tabBarController.restoreUserActivityState(userActivity)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    URLContexts.forEach { (context) in
      let url = context.url.absoluteString
      if url.hasPrefix("provenance://accounts/") {
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
      } else if url.hasPrefix("provenance://transactions/") {
        let transactionId = url.replacingOccurrences(of: "provenance://transactions/", with: "")
        Up.retrieveTransaction(for: transactionId) { (result) in
          switch result {
          case let .success(transaction):
            if let tabBarController = self.window?.rootViewController as? TabBarController,
               let navigationController = tabBarController.selectedViewController as? NavigationController {
              let viewController = TransactionDetailVC(transaction: transaction)
              navigationController.pushViewController(viewController, animated: true)
            }
          case .failure:
            break
          }
        }
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
    if Store.provenance.apiKey.isEmpty && window?.rootViewController?.presentedViewController == nil {
      let alertController = UIAlertController.noApiKey(self, selector: #selector(textChanged))
      window?.rootViewController?.present(alertController, animated: true)
    } else if !Store.provenance.apiKey.isEmpty, let alertController = window?.rootViewController?.presentedViewController as? UIAlertController {
      alertController.textFields?.first?.text = Store.provenance.apiKey
      alertController.dismiss(animated: true)
    }
  }

  @objc
  private func textChanged() {
    guard let alert = window?.rootViewController?.presentedViewController as? UIAlertController,
          let action = alert.actions.last,
          let text = alert.textFields?.first?.text
    else { return }
    action.isEnabled = text.count >= 1 && text != Store.provenance.apiKey
  }
}
