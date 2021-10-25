import NotificationBannerSwift

extension UIAlertAction {
  /// `UIAlertAction(title: "Dismiss", style: .default)`.
  static var dismiss: UIAlertAction {
    return UIAlertAction(title: "Dismiss", style: .default)
  }

  /// Dismiss action that pops the current view controller from the navigation stack.
  static func dismissAndPop(_ navigationController: UINavigationController?) -> UIAlertAction {
    return UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
      navigationController?.popViewController(animated: true)
    })
  }

  /// `UIAlertAction(title: "Cancel", style: .cancel)`.
  static var cancel: UIAlertAction {
    return UIAlertAction(title: "Cancel", style: .cancel)
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAlertAction {
    return UIAlertAction(title: "Remove", style: .destructive, handler: { (_) in
      Up.modifyTags(removing: tag, from: transaction) { (error) in
        DispatchQueue.main.async {
          if let error = error {
            GrowingNotificationBanner(
              title: "Failed",
              subtitle: error.errorDescription ?? error.localizedDescription,
              style: .danger,
              duration: 2.0
            ).show()
          } else {
            GrowingNotificationBanner(
              title: "Success",
              subtitle: "\(tag.id) was removed from \(transaction.attributes.description).",
              style: .success,
              duration: 2.0
            ).show()
            viewController.fetchTransactions()
          }
        }
      }
    })
  }

  static func removeTagFromTransaction(_ viewController: TransactionTagsVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAlertAction {
    return UIAlertAction(title: "Remove", style: .destructive, handler: { (_) in
      Up.modifyTags(removing: tag, from: transaction) { (error) in
        DispatchQueue.main.async {
          if let error = error {
            GrowingNotificationBanner(
              title: "Failed",
              subtitle: error.errorDescription ?? error.localizedDescription,
              style: .danger,
              duration: 2.0
            ).show()
          } else {
            GrowingNotificationBanner(
              title: "Success",
              subtitle: "\(tag.id) was removed from \(transaction.attributes.description).",
              style: .success,
              duration: 2.0
            ).show()
            viewController.fetchTransaction()
          }
        }
      }
    })
  }

  static func removeTagsFromTransaction(_ viewController: TransactionTagsVC,
                                        removing tags: [TagResource],
                                        from transaction: TransactionResource) -> UIAlertAction {
    return UIAlertAction(title: "Remove", style: .destructive, handler: { (_) in
      Up.modifyTags(removing: tags, from: transaction) { (error) in
        DispatchQueue.main.async {
          if let error = error {
            GrowingNotificationBanner(
              title: "Failed",
              subtitle: error.errorDescription ?? error.localizedDescription,
              style: .danger,
              duration: 2.0
            ).show()
          } else {
            GrowingNotificationBanner(
              title: "Success",
              subtitle: "\(tags.joinedWithComma) \(tags.count == 1 ? "was" : "were") removed from \(transaction.attributes.description).",
              style: .success,
              duration: 2.0
            ).show()
            viewController.fetchTransaction()
          }
        }
      }
    })
  }

  static func submitNewTags(navigationController: UINavigationController?,
                            transaction: TransactionResource,
                            alertController: UIAlertController) -> UIAlertAction {
    let alertAction = UIAlertAction(title: "Next", style: .default, handler: { [weak alertController] (_) in
      if let tags = alertController?.textFields?.tagResources {
        let viewController = AddTagConfirmationVC(transaction: transaction, tags: tags)
        navigationController?.pushViewController(viewController, animated: true)
      }
    })
    alertAction.isEnabled = false
    return alertAction
  }

  static func saveApiKey(alertController: UIAlertController, viewController: SettingsVC) -> UIAlertAction {
    let alertAction = UIAlertAction(title: "Save", style: .default, handler: { [weak alertController] (_) in
      if let textField = alertController?.textFields?.first,
         let text = textField.text {
        if textField.hasText && text != UserDefaults.provenance.apiKey {
          Up.ping(with: text) { (error) in
            DispatchQueue.main.async {
              if let error = error {
                GrowingNotificationBanner(
                  title: "Failed",
                  subtitle: error.errorDescription ?? error.localizedDescription,
                  style: .danger,
                  duration: 2.0
                ).show()
              } else {
                GrowingNotificationBanner(
                  title: "Success",
                  subtitle: "The API Key was verified and saved.",
                  style: .success,
                  duration: 2.0
                ).show()
                UserDefaults.provenance.apiKey = text
                viewController.tableNode.reloadData()
              }
            }
          }
        } else {
          GrowingNotificationBanner(
            title: "Failed",
            subtitle: "The provided API Key was the same as the current one.",
            style: .danger,
            duration: 2.0
          ).show()
        }
      }
    })
    alertAction.isEnabled = false
    return alertAction
  }

  static func noApiKey(sceneDelegate: SceneDelegate, alertController: UIAlertController) -> UIAlertAction {
    let alertAction = UIAlertAction(title: "Save", style: .default, handler: { [weak alertController] (_) in
      if let textField = alertController?.textFields?.first,
         let text = textField.text {
        if textField.hasText && text != UserDefaults.provenance.apiKey {
          Up.ping(with: text) { (error) in
            DispatchQueue.main.async {
              if let error = error {
                let notificationBanner = GrowingNotificationBanner(
                  title: "Failed",
                  subtitle: error.errorDescription ?? error.localizedDescription,
                  style: .danger,
                  duration: 2.0
                )
                let viewController = NavigationController(rootViewController: SettingsVC(displayBanner: notificationBanner))
                sceneDelegate.window?.rootViewController?.present(.fullscreen(viewController), animated: true)
              } else {
                let notificationBanner = GrowingNotificationBanner(
                  title: "Success",
                  subtitle: "The API Key was verified and saved.",
                  style: .success,
                  duration: 2.0
                )
                let viewController = NavigationController(rootViewController: SettingsVC(displayBanner: notificationBanner))
                UserDefaults.provenance.apiKey = text
                sceneDelegate.window?.rootViewController?.present(.fullscreen(viewController), animated: true)
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
          sceneDelegate.window?.rootViewController?.present(.fullscreen(viewController), animated: true)
        }
      }
    })
    alertAction.isEnabled = false
    return alertAction
  }
}
