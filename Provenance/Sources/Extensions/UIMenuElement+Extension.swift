import Foundation
import UIKit

extension UIMenuElement {
  static func copyTransactionDescription(transaction: TransactionResource) -> UIAction {
    return UIAction(
      title: "Copy Description",
      image: .textAlignright,
      handler: { (_) in
        UIPasteboard.general.string = transaction.attributes.description
      }
    )
  }

  static func copyTransactionCreationDate(transaction: TransactionResource) -> UIAction {
    return UIAction(
      title: "Copy Creation Date",
      image: .calendarCircle,
      handler: { (_) in
        UIPasteboard.general.string = transaction.attributes.creationDate
      }
    )
  }

  static func copyTransactionAmount(transaction: TransactionResource) -> UIAction {
    return UIAction(
      title: "Copy Amount",
      image: .dollarsignCircle,
      handler: { (_) in
        UIPasteboard.general.string = transaction.attributes.amount.valueShort
      }
    )
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC, removing tag: TagResource, from transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Remove", image: .trash, attributes: .destructive) { (_) in
      let alertController = UIAlertController.removeTagFromTransaction(viewController, removing: tag, from: transaction)
      viewController.present(alertController, animated: true)
    }
  }

  static func copyAttribute(attribute: DetailAttribute) -> UIAction {
    return UIAction(
      title: "Copy \(attribute.id)",
      image: .docOnClipboard,
      handler: { (_) in
        UIPasteboard.general.string = attribute.value
      }
    )
  }

  static func copyCategoryName(category: CategoryResource) -> UIAction {
    return UIAction(
      title: "Copy",
      image: .docOnClipboard,
      handler: { (_) in
        UIPasteboard.general.string = category.attributes.name
      }
    )
  }

  static func copyTagName(tag: TagResource) -> UIAction {
    return UIAction(
      title: "Copy",
      image: .docOnClipboard,
      handler: { (_) in
        UIPasteboard.general.string = tag.id
      }
    )
  }
  
  static func copyAccountBalance(account: AccountResource) -> UIAction {
    return UIAction(
      title: "Copy Balance",
      image: .dollarsignCircle,
      handler: { (_) in
        UIPasteboard.general.string = account.attributes.balance.valueShort
      }
    )
  }

  static func copyAccountDisplayName(account: AccountResource) -> UIAction {
    return UIAction(
      title: "Copy Display Name",
      image: .textAlignright,
      handler: { (_) in
        UIPasteboard.general.string = account.attributes.displayName
      }
    )
  }
}
