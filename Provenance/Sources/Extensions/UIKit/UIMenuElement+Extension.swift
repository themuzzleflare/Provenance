import UIKit

extension UIMenuElement {
  static func copyGeneric(title: String, string: String) -> UIAction {
    return UIAction(title: "Copy \(title)", image: .docOnClipboard, handler: { (_) in
      UIPasteboard.general.string = string
    })
  }

  static func copyTransactionDescription(transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Copy Description", image: .textAlignright, handler: { (_) in
      UIPasteboard.general.string = transaction.attributes.description
    })
  }

  static func copyTransactionDescription(transaction: String) -> UIAction {
    return UIAction(title: "Copy Description", image: .textAlignright, handler: { (_) in
      UIPasteboard.general.string = transaction
    })
  }

  static func copyTransactionCreationDate(transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Copy Creation Date", image: .calendarCircle, handler: { (_) in
      UIPasteboard.general.string = transaction.attributes.creationDate
    })
  }

  static func copyTransactionCreationDate(transaction: String) -> UIAction {
    return UIAction(title: "Copy Creation Date", image: .calendarCircle, handler: { (_) in
      UIPasteboard.general.string = transaction
    })
  }

  static func copyTransactionAmount(transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Copy Amount", image: .dollarsignCircle, handler: { (_) in
      UIPasteboard.general.string = transaction.attributes.amount.valueShort
    })
  }

  static func copyTransactionAmount(transaction: String) -> UIAction {
    return UIAction(title: "Copy Amount", image: .dollarsignCircle, handler: { (_) in
      UIPasteboard.general.string = transaction
    })
  }

  static func editCategory(_ viewController: TransactionDetailVC) -> UIAction {
    return UIAction(title: "Edit", image: .pencil, handler: { (_) in
      viewController.editCategory()
    })
  }

  static func copyAttribute(attribute: DetailItem) -> UIAction {
    return UIAction(title: "Copy \(attribute.id)", image: .docOnClipboard, handler: { (_) in
      UIPasteboard.general.string = attribute.value
    })
  }

  static func copyCategoryName(category: CategoryResource) -> UIAction {
    return UIAction(title: "Copy", image: .docOnClipboard, handler: { (_) in
      UIPasteboard.general.string = category.attributes.name
    })
  }

  static func copyTagName(tag: TagResource) -> UIAction {
    return UIAction(title: "Copy", image: .docOnClipboard, handler: { (_) in
      UIPasteboard.general.string = tag.id
    })
  }

  static func copyAccountBalance(account: AccountResource) -> UIAction {
    return UIAction(title: "Copy Balance", image: .dollarsignCircle, handler: { (_) in
      UIPasteboard.general.string = account.attributes.balance.valueShort
    })
  }

  static func copyAccountDisplayName(account: AccountResource) -> UIAction {
    return UIAction(title: "Copy Display Name", image: .textAlignright, handler: { (_) in
      UIPasteboard.general.string = account.attributes.displayName
    })
  }

  static func removeCategory(_ viewController: TransactionDetailVC,
                             from transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Remove", image: .trash, attributes: .destructive) { (_) in
      let alertController = UIAlertController.removeCategory(viewController, from: transaction)
      viewController.present(alertController, animated: true)
    }
  }

  static func removeCategory(_ viewController: TransactionsByCategoryVC,
                             from transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Remove", image: .trash, attributes: .destructive) { (_) in
      let alertController = UIAlertController.removeCategory(viewController, from: transaction)
      viewController.present(alertController, animated: true)
    }
  }

  static func removeTagFromTransaction(_ viewController: TransactionsByTagVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Remove", image: .trash, attributes: .destructive) { (_) in
      let alertController = UIAlertController.removeTagFromTransaction(viewController, removing: tag, from: transaction)
      viewController.present(alertController, animated: true)
    }
  }

  static func removeTagFromTransaction(_ viewController: TransactionTagsVC,
                                       removing tag: TagResource,
                                       from transaction: TransactionResource) -> UIAction {
    return UIAction(title: "Remove", image: .trash, attributes: .destructive) { (_) in
      let alertController = UIAlertController.removeTagFromTransaction(viewController, removing: tag, from: transaction)
      viewController.present(alertController, animated: true)
    }
  }
}
