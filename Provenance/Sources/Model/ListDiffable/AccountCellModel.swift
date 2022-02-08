import Foundation
import IGListKit

final class AccountCellModel {
  let id: String
  let balance: String
  let displayName: String

  init(account: AccountResource) {
    self.id = account.id
    self.balance = account.attributes.balance.valueShort
    self.displayName = account.attributes.displayName
  }
}

// MARK: - ListDiffable

extension AccountCellModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? AccountCellModel else { return false }
    return self.displayName == object.displayName && self.balance == object.balance
  }
}
