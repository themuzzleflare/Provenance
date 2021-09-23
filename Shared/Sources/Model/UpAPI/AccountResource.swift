import UIKit

class AccountResource: Codable {
    /// The type of this resource: accounts
  let type = "accounts"
  
    /// The unique identifier for this account.
  let id: String
  
  let attributes: AccountAttribute
  
  let relationships: AccountRelationship
  
  let links: SelfLink?
  
  init(id: String, attributes: AccountAttribute, relationships: AccountRelationship, links: SelfLink? = nil) {
    self.id = id
    self.attributes = attributes
    self.relationships = relationships
    self.links = links
  }
}

extension AccountResource {
  var accountBalanceModel: AccountBalanceModel {
    return AccountBalanceModel(
      id: self.id,
      displayName: self.attributes.displayName,
      balance: self.attributes.balance.valueShort
    )
  }
  
  var accountType: AccountType {
    return AccountType(
      identifier: self.id,
      display: self.attributes.displayName,
      subtitle: self.attributes.balance.valueShort,
      image: nil
    )
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
  
  var accountTypes: [AccountType] {
    return self.map { (account) in
      return account.accountType
    }
  }
}
