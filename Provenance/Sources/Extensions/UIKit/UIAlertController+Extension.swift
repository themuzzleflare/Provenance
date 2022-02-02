import UIKit

extension UIAlertController {
  static func alertWithDismissButton(title: String,
                                     message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.dismiss)
    return alertController
  }

  static func alertWithDismissPopButton(_ navigationController: UINavigationController?,
                                        title: String,
                                        message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.dismissAndPop(navigationController))
    return alertController
  }

  static func removeCategory(_ viewController: TransactionDetailVC,
                             from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove the category from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeCategory(viewController, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeCategory(_ viewController: TransactionsByCategoryVC,
                             from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove the category from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeCategory(viewController, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tag.id) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagFromTransaction(viewController, removing: tag, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeTagFromTransaction(_ viewController: TransactionTagsVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tag.id) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagFromTransaction(viewController, removing: tag, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func removeTagsFromTransaction(_ viewController: TransactionTagsVC,
                                        removing tags: [TagResource],
                                        from transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(tags.joinedWithComma) from \(transaction.attributes.description)?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagsFromTransaction(viewController, removing: tags, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func submitNewTags(_ viewController: AddTagTagsSelectionVC,
                            selector: Selector,
                            transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(
      title: "Create Tags",
      message: "You can add a maximum of 6 tags to a transaction.",
      preferredStyle: .alert
    )
    for (idx) in 0...5 {
      alertController.addTextField { (textField) in
        textField.addTarget(viewController, action: selector, for: .editingChanged)
        textField.delegate = viewController
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Tag \((idx + 1).description)"
      }
    }
    alertController.addAction(.cancel)
    alertController.addAction(.submitNewTags(navigationController: viewController.navigationController, transaction: transaction, alertController: alertController))
    return alertController
  }

  static func saveApiKey(_ viewController: SettingsVC,
                         selector: Selector) -> UIAlertController {
    let alertController = UIAlertController(
      title: "API Key",
      message: "Enter a new API Key.",
      preferredStyle: .alert
    )
    alertController.addTextField { (textField) in
      textField.addTarget(viewController, action: selector, for: .editingChanged)
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.spellCheckingType = .no
      textField.clearButtonMode = .whileEditing
      textField.textContentType = .password
      textField.text = Store.provenance.apiKey
    }
    alertController.addAction(.cancel)
    alertController.addAction(.saveApiKey(alertController: alertController, viewController: viewController))
    return alertController
  }

  static func noApiKey(_ sceneDelegate: SceneDelegate,
                       selector: Selector) -> UIAlertController {
    let alertController = UIAlertController(
      title: "API Key Required",
      message: "You don't have an API Key set. You can set one now.",
      preferredStyle: .alert
    )
    alertController.addTextField { (textField) in
      textField.addTarget(sceneDelegate, action: selector, for: .editingChanged)
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.spellCheckingType = .no
      textField.textContentType = .password
      textField.clearButtonMode = .whileEditing
    }
    alertController.addAction(.cancel)
    alertController.addAction(.noApiKey(sceneDelegate: sceneDelegate, alertController: alertController))
    return alertController
  }
}
