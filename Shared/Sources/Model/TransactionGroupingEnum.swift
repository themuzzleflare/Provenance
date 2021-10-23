import Foundation

enum TransactionGroupingEnum: Int, CaseIterable {
  case all
  case dates
  case transactions
}

extension TransactionGroupingEnum {
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

extension Array where Element == TransactionGroupingEnum {
  var names: [String] {
    return self.map { (grouping) in
      return grouping.description
    }
  }
}
