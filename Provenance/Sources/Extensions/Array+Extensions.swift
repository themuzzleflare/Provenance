import Foundation
import UIKit

extension Array where Element: TransactionResource {
  func filtered(searchBar: UISearchBar) -> [TransactionResource] {
    return self.filter { (transaction) in
      searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchBar.text!)
    }
  }
}

extension Array where Element: AccountResource {
  func filtered(searchBar: UISearchBar) -> [AccountResource] {
    return self.filter { (account) in
      switch searchBar.selectedScopeButtonIndex {
      case 0:
        return searchBar.text!.isEmpty || (account.attributes.displayName.localizedStandardContains(searchBar.text!) && account.attributes.accountType == .transactional)
      case 1:
        return searchBar.text!.isEmpty || (account.attributes.displayName.localizedStandardContains(searchBar.text!) && account.attributes.accountType == .saver)
      default:
        return searchBar.text!.isEmpty || account.attributes.displayName.localizedStandardContains(searchBar.text!)
      }
    }
  }
}

extension Array where Element: TagResource {
  func filtered(searchBar: UISearchBar) -> [TagResource] {
    return self.filter { (tag) in
      searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchBar.text!)
    }
  }
}

extension Array where Element: CategoryResource {
  func filtered(searchBar: UISearchBar) -> [CategoryResource] {
    return self.filter { (category) in
      switch searchBar.selectedScopeButtonIndex {
      case 0:
        return searchBar.text!.isEmpty || (category.attributes.name.localizedStandardContains(searchBar.text!) && category.isParent == true)
      case 1:
        return searchBar.text!.isEmpty || (category.attributes.name.localizedStandardContains(searchBar.text!) && category.isParent == false)
      default:
        return searchBar.text!.isEmpty || category.attributes.name.localizedStandardContains(searchBar.text!)
      }
    }
  }
}

extension Array where Element == DetailSection {
  static func transactionDetailSections(transaction: TransactionResource, account: AccountResource?, transferAccount: AccountResource?, parentCategory: CategoryResource?, category: CategoryResource?) -> [DetailSection] {
    return [
      DetailSection(
        id: 1,
        attributes: [
          DetailAttribute(
            id: "Status",
            value: transaction.attributes.statusString
          ),
          DetailAttribute(
            id: "Account",
            value: account?.attributes.displayName ?? ""
          ),
          DetailAttribute(
            id: "Transfer Account",
            value: transferAccount?.attributes.displayName ?? ""
          )
        ]
      ),
      DetailSection(
        id: 2,
        attributes: [
          DetailAttribute(
            id: "Description",
            value: transaction.attributes.description
          ),
          DetailAttribute(
            id: "Raw Text",
            value: transaction.attributes.rawText ?? ""
          ),
          DetailAttribute(
            id: "Message",
            value: transaction.attributes.message ?? ""
          )
        ]
      ),
      DetailSection(
        id: 3,
        attributes: [
          DetailAttribute(
            id: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
            value: transaction.attributes.holdTransValue
          ),
          DetailAttribute(
            id: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
            value: transaction.attributes.holdForeignTransValue
          ),
          DetailAttribute(
            id: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
            value: transaction.attributes.foreignTransValue
          ),
          DetailAttribute(
            id: transaction.attributes.amount.transactionType,
            value: transaction.attributes.amount.valueLong
          )
        ]
      ),
      DetailSection(
        id: 4,
        attributes: [
          DetailAttribute(
            id: "Creation Date",
            value: transaction.attributes.creationDate
          ),
          DetailAttribute(
            id: "Settlement Date",
            value: transaction.attributes.settlementDate ?? ""
          )
        ]
      ),
      DetailSection(
        id: 5,
        attributes: [
          DetailAttribute(
            id: "Parent Category",
            value: parentCategory?.attributes.name ?? ""
          ),
          DetailAttribute(
            id: "Category",
            value: category?.attributes.name ?? ""
          )
        ]
      ),
      DetailSection(
        id: 6,
        attributes: [
          DetailAttribute(
            id: "Tags",
            value: transaction.relationships.tags.data.count.description
          )
        ]
      )
    ]
  }

  static func accountDetailSections(account: AccountResource, transaction: TransactionResource?) -> [DetailSection] {
    return [
      DetailSection(
        id: 1,
        attributes: [
          DetailAttribute(
            id: "Account Balance",
            value: account.attributes.balance.valueLong
          ),
          DetailAttribute(
            id: "Latest Transaction",
            value: transaction?.attributes.description ?? ""
          ),
          DetailAttribute(
            id: "Account ID",
            value: account.id
          ),
          DetailAttribute(
            id: "Creation Date",
            value: account.attributes.creationDate
          )
        ]
      )
    ]
  }
  
  var filtered: [DetailSection] {
    return self.filter {
      !$0.attributes.allSatisfy {
        $0.value.isEmpty || ($0.id == "Tags" && $0.value == "0")
      }
    }.map {
      DetailSection(id: $0.id, attributes: $0.attributes.filter {
        !$0.value.isEmpty
      })
    }
  }
}
