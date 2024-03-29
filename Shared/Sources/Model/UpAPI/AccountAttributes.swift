import Foundation

struct AccountAttributes: Codable {
  /// The name associated with the account in the Up application.
  var displayName: String

  /// The bank account type of this account.
  var accountType: AccountTypeEnum

  /// The ownership structure for this account.
  var ownershipType: OwnershipTypeEnum

  /// The available balance of the account, taking into account any amounts that are currently on hold.
  var balance: MoneyObject

  /// The date-time at which this account was first opened.
  var createdAt: String
}

// MARK: -

extension AccountAttributes {
  var creationDate: String {
    return Utils.formatDate(for: createdAt)
  }
}
