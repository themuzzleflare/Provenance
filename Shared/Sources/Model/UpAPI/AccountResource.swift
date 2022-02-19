import Foundation
import UIKit

struct AccountResource: Codable, Identifiable {
  /// The type of this resource: `accounts`
  var type = "accounts"

  /// The unique identifier for this account.
  var id: String

  var attributes: AccountAttributes

  var relationships: AccountRelationships

  var links: SelfLink?
}

// MARK: - CustomStringConvertible

extension AccountResource: CustomStringConvertible {
  var description: String {
    return attributes.displayName
  }
}

// MARK: -

extension AccountResource {
  var accountBalanceModel: AccountBalanceModel {
    return AccountBalanceModel(id: self.id,
                               displayName: self.attributes.displayName,
                               balance: self.attributes.balance.valueShort)
  }

  var accountType: AccountType {
    return AccountType(identifier: self.id,
                       display: self.attributes.displayName,
                       subtitle: self.attributes.balance.valueShort,
                       image: nil)
  }
}

// MARK: -

extension Array where Element == AccountResource {
  func filtered(filter: AccountTypeOptionEnum, searchBar: UISearchBar) -> [AccountResource] {
    return self.filter { (account) in
      return !searchBar.searchTextField.hasText ||
      (account.attributes.displayName.localizedStandardContains(searchBar.text!) && account.attributes.accountType == filter.accountTypeEnum)
    }
  }

  var searchBarPlaceholder: String {
    return "Search \(self.count.description) \(self.count == 1 ? "Account" : "Accounts")"
  }

  var accountTypes: [AccountType] {
    return self.map { (account) in
      return account.accountType
    }
  }
}
