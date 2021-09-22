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
        return searchBar.text!.isEmpty || (category.attributes.name.localizedStandardContains(searchBar.text!) && category.categoryTypeEnum == .parent)
      case 1:
        return searchBar.text!.isEmpty || (category.attributes.name.localizedStandardContains(searchBar.text!) && category.categoryTypeEnum == .child)
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
        items: [
          DetailItem(
            id: "Status",
            value: transaction.attributes.statusString
          ),
          DetailItem(
            id: "Account",
            value: account?.attributes.displayName ?? .emptyString
          ),
          DetailItem(
            id: "Transfer Account",
            value: transferAccount?.attributes.displayName ?? .emptyString
          )
        ]
      ),
      DetailSection(
        id: 2,
        items: [
          DetailItem(
            id: "Description",
            value: transaction.attributes.description
          ),
          DetailItem(
            id: "Raw Text",
            value: transaction.attributes.rawText ?? .emptyString
          ),
          DetailItem(
            id: "Message",
            value: transaction.attributes.message ?? .emptyString
          )
        ]
      ),
      DetailSection(
        id: 3,
        items: [
          DetailItem(
            id: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? .emptyString)",
            value: transaction.attributes.holdTransValue
          ),
          DetailItem(
            id: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? .emptyString)",
            value: transaction.attributes.holdForeignTransValue
          ),
          DetailItem(
            id: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? .emptyString)",
            value: transaction.attributes.foreignTransValue
          ),
          DetailItem(
            id: transaction.attributes.amount.transactionType,
            value: transaction.attributes.amount.valueLong
          )
        ]
      ),
      DetailSection(
        id: 4,
        items: [
          DetailItem(
            id: "Creation Date",
            value: transaction.attributes.creationDate
          ),
          DetailItem(
            id: "Settlement Date",
            value: transaction.attributes.settlementDate ?? .emptyString
          )
        ]
      ),
      DetailSection(
        id: 5,
        items: [
          DetailItem(
            id: "Parent Category",
            value: parentCategory?.attributes.name ?? .emptyString
          ),
          DetailItem(
            id: "Category",
            value: category?.attributes.name ?? .emptyString
          )
        ]
      ),
      DetailSection(
        id: 6,
        items: [
          DetailItem(
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
        items: [
          DetailItem(
            id: "Account Balance",
            value: account.attributes.balance.valueLong
          ),
          DetailItem(
            id: "Latest Transaction",
            value: transaction?.attributes.description ?? .emptyString
          ),
          DetailItem(
            id: "Account ID",
            value: account.id
          ),
          DetailItem(
            id: "Creation Date",
            value: account.attributes.creationDate
          )
        ]
      )
    ]
  }
  
  static var diagnosticsSections: [DetailSection] {
    return [
      DetailSection(
        id: 1,
        items: [
          DetailItem(
            id: "Version",
            value: appDefaults.appVersion
          ),
          DetailItem(
            id: "Build",
            value: appDefaults.appBuild
          )
        ]
      )
    ]
  }
  
  var filtered: [DetailSection] {
    return self.filter { (section) in
      !section.items.allSatisfy { (item) in
        item.value.isEmpty || (item.id == "Tags" && item.value == "0")
      }
    }.map { (section) in
      DetailSection(id: section.id, items: section.items.filter { (item) in
        !item.value.isEmpty
      })
    }
  }
}
