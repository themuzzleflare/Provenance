import Foundation

struct LatestTransactionModel {
  let id: String
  let description: String
  let creationDate: String
  let amount: String
  let colour: TransactionColourEnum
}

// MARK: -

extension LatestTransactionModel {
  static var placeholder: LatestTransactionModel {
    return LatestTransactionModel(id: UUID().uuidString,
                                  description: "Officeworks",
                                  creationDate: "21 hours ago",
                                  amount: "-$79.95",
                                  colour: .primaryLabel)
  }
}
