import UIKit

extension UIAlertController {
  static func alertWithDismissButton(title: String, message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.dismiss)
    return alertController
  }

  static func alertWithDismissPopButton(_ navigationController: UINavigationController?, title: String, message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.dismissAndPop(navigationController))
    return alertController
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC, removing tag: TagResource, from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tag.id) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagFromTransaction(viewController, removing: tag, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeTagFromTransaction(_ viewController: TransactionTagsVC, removing tag: TagResource, from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tag.id) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagFromTransaction(viewController, removing: tag, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeTagsFromTransaction(_ viewController: TransactionTagsVC, removing tags: [TagResource], from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tags.joinedWithComma) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagsFromTransaction(viewController, removing: tags, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func submitNewTags(_ viewController: AddTagTagsSelectionVC, selector: Selector, transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(
      title: "Create Tags",
      message: "You can add a maximum of 6 tags to a transaction.",
      preferredStyle: .alert
    )
    for (idx) in 0...5 {
      alertController.addTextField { (textField) in
        textField.delegate = viewController
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Tag \((idx + 1).description)"
        textField.addTarget(viewController, action: selector, for: .editingChanged)
      }
    }
    alertController.addAction(.cancel)
    alertController.addAction(.submitNewTags(viewController.navigationController, transaction: transaction, alertController: alertController))
    return alertController
  }

  static func saveApiKey(_ viewController: SettingsVC) -> UIAlertController {
    let alertController = UIAlertController(
      title: "API Key",
      message: "Enter a new API Key.",
      preferredStyle: .alert
    )
    alertController.addTextField { (textField) in
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.spellCheckingType = .no
      textField.clearButtonMode = .whileEditing
      textField.textContentType = .password
      textField.text = App.userDefaults.apiKey
      viewController.textDidChangeObserver = NotificationCenter.default.addObserver(
        forName: UITextField.textDidChangeNotification,
        object: textField,
        queue: .main,
        using: { (notification) in
          if let change = notification.object as? UITextField, let text = change.text {
            viewController.submitActionProxy.isEnabled = text.count >= 1 && text != App.userDefaults.apiKey
          } else {
            viewController.submitActionProxy.isEnabled = false
          }
        }
      )
    }
    alertController.addAction(.cancel)
    alertController.addAction(.saveApiKey(alertController: alertController, viewController: viewController))
    return alertController
  }

  static func noApiKey(_ sceneDelegate: SceneDelegate) -> UIAlertController {
    let alertController = UIAlertController(
      title: "API Key Required",
      message: "You don't have an API Key set. You can set one now.",
      preferredStyle: .alert
    )
    alertController.addTextField { (textField) in
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.spellCheckingType = .no
      textField.textContentType = .password
      textField.clearButtonMode = .whileEditing
      sceneDelegate.textDidChangeObserver = NotificationCenter.default.addObserver(
        forName: UITextField.textDidChangeNotification,
        object: textField,
        queue: .main,
        using: { (notification) in
          if let change = notification.object as? UITextField, let text = change.text {
            sceneDelegate.submitActionProxy.isEnabled = text.count >= 1 && text != App.userDefaults.apiKey
          } else {
            sceneDelegate.submitActionProxy.isEnabled = false
          }
        }
      )
    }
    alertController.addAction(.cancel)
    alertController.addAction(.noApiKey(sceneDelegate: sceneDelegate, alertController: alertController))
    return alertController
  }
}
