import Foundation
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
    let alertController = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)
    alertController.addAction(.removeTagFromTransaction(viewController, removing: tag, from: transaction))
    alertController.addAction(.cancel)
    return alertController
  }

  static func submitNewTags(_ viewController: AddTagWorkflowTwoVC, selector: Selector, transaction: TransactionResource) -> UIAlertController {
    let alertController = UIAlertController(
      title: "Create Tags",
      message: "You can add a maximum of 6 tags to a transaction.",
      preferredStyle: .alert
    )
    for (_) in 0...5 {
      alertController.addTextField { (textField) in
        textField.delegate = viewController
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addTarget(viewController, action: selector, for: .editingChanged)
      }
    }
    alertController.addAction(.cancel)
    alertController.addAction(.submitNewTags(viewController.navigationController, transaction: transaction, alertController: alertController))
    return alertController
  }
}
