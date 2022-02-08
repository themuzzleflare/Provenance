import Foundation

enum TransactionGroupingEnum: Int, CaseIterable {
  case all
  case dates
  case transactions
}

// MARK: - CustomStringConvertible

extension TransactionGroupingEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .all:
      return "All"
    case .dates:
      return "Dates"
    case .transactions:
      return "Transactions"
    }
  }
}

// MARK: -

extension Array where Element == TransactionGroupingEnum {
  var names: [String] {
    return self.map { (grouping) in
      return grouping.description
    }
  }
}
