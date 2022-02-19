import Foundation

struct AccountBalanceModel {
  let id: String
  let displayName: String
  let balance: String
}

// MARK: -

extension AccountBalanceModel {
  static var placeholder: AccountBalanceModel {
    return AccountBalanceModel(id: UUID().uuidString,
                               displayName: "Spending",
                               balance: "$123.95")
  }
}
