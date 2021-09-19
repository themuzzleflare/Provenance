import Foundation

class AccountAttribute: Codable {
  let creationDate: String

  /// The name associated with the account in the Up application.
  let displayName: String

  /// The bank account type of this account.
  let accountType: AccountTypeEnum

  /// The available balance of the account, taking into account any amounts that are currently on hold.
  let balance: MoneyObject

  /// The date-time at which this account was first opened.
  let createdAt: String

  enum CodingKeys: String, CodingKey {
    case displayName
    case accountType
    case balance
    case createdAt
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    displayName = try values.decode(String.self, forKey: .displayName)
    accountType = try values.decode(AccountTypeEnum.self, forKey: .accountType)
    balance = try values.decode(MoneyObject.self, forKey: .balance)
    createdAt = try values.decode(String.self, forKey: .createdAt)
    creationDate = formatDate(for: createdAt, dateStyle: appDefaults.appDateStyle)
  }
}
