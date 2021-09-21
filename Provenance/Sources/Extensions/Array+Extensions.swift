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
            value: account?.attributes.displayName ?? ""
          ),
          DetailItem(
            id: "Transfer Account",
            value: transferAccount?.attributes.displayName ?? ""
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
            value: transaction.attributes.rawText ?? ""
          ),
          DetailItem(
            id: "Message",
            value: transaction.attributes.message ?? ""
          )
        ]
      ),
      DetailSection(
        id: 3,
        items: [
          DetailItem(
            id: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
            value: transaction.attributes.holdTransValue
          ),
          DetailItem(
            id: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
            value: transaction.attributes.holdForeignTransValue
          ),
          DetailItem(
            id: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
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
            value: transaction.attributes.settlementDate ?? ""
          )
        ]
      ),
      DetailSection(
        id: 5,
        items: [
          DetailItem(
            id: "Parent Category",
            value: parentCategory?.attributes.name ?? ""
          ),
          DetailItem(
            id: "Category",
            value: category?.attributes.name ?? ""
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
            value: transaction?.attributes.description ?? ""
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
  
  var filtered: [DetailSection] {
    return self.filter {
      !$0.items.allSatisfy {
        $0.value.isEmpty || ($0.id == "Tags" && $0.value == "0")
      }
    }.map {
      DetailSection(id: $0.id, items: $0.items.filter {
        !$0.value.isEmpty
      })
    }
  }
}
