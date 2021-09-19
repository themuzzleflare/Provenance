import Foundation

class AccountResource: Codable {
  /// The type of this resource: accounts
  let type = "accounts"

  /// The unique identifier for this account.
  let id: String

  let attributes: AccountAttribute

  let relationships: AccountRelationship?

  let links: SelfLink?

  init(id: String, attributes: AccountAttribute, relationships: AccountRelationship? = nil, links: SelfLink? = nil) {
    self.id = id
    self.attributes = attributes
    self.relationships = relationships
    self.links = links
  }
}

extension AccountResource {
  var accountBalanceModel: AccountBalanceModel {
    return AccountBalanceModel(id: self.id, displayName: self.attributes.displayName, balance: self.attributes.balance.valueShort)
  }
}
