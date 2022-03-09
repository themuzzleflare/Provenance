import Foundation

enum FilterMenuAction {
  case category(TransactionCategory)
  case grouping(TransactionGroupingEnum)
  case dates
  case settledOnly(Bool)
}
