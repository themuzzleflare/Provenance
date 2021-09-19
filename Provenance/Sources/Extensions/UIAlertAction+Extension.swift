import Foundation
import UIKit
import NotificationBannerSwift

extension UIAlertAction {
  static var dismiss: UIAlertAction {
    return UIAlertAction(title: "Dismiss", style: .default)
  }

  /// Cancel action that pops the current view controller from the navigation stack.
  static func dismissAndPop(_ navigationController: UINavigationController?) -> UIAlertAction {
    return UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
      navigationController?.popViewController(animated: true)
    })
  }

  static var cancel: UIAlertAction {
    return UIAlertAction(title: "Cancel", style: .cancel)
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC, removing tag: TagResource, from transaction: TransactionResource) -> UIAlertAction {
    return UIAlertAction(title: "Remove", style: .destructive) { (_) in
      UpFacade.modifyTags(removing: tag, from: transaction) { (error) in
        DispatchQueue.main.async {
          switch error {
          case .none:
            GrowingNotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.description).", style: .success).show()
            viewController.fetchTransactions()
          default:
            GrowingNotificationBanner(title: "Failed", subtitle: error!.description, style: .danger).show()
          }
        }
      }
    }
  }

  static func submitNewTags(_ navigationController: UINavigationController?, transaction: TransactionResource, alertController: UIAlertController) -> UIAlertAction {
    let submitAction = UIAlertAction(
      title: "Next",
      style: .default,
      handler: { (_) in
        if let answers = alertController.textFields?.map { TagResource(id: $0.text ?? "") }.filter { !$0.id.isEmpty } {
          navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: answers), animated: true)
        }
      }
    )
    submitAction.isEnabled = false
    return submitAction
  }
}
