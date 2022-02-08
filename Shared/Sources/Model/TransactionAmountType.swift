import Foundation

enum TransactionAmountType: Int {
  case debit
  case credit
  case amount
}

// MARK: - CustomStringConvertible

extension TransactionAmountType: CustomStringConvertible {
  var description: String {
    switch self {
    case .debit:
      return "Debit"
    case .credit:
      return "Credit"
    case .amount:
      return "Amount"
    }
  }
}

// MARK: -

extension TransactionAmountType {
  var colour: TransactionColourEnum {
    switch self {
    case .debit:
      return .primaryLabel
    case .credit:
      return .green
    case .amount:
      return .unknown
    }
  }
}
