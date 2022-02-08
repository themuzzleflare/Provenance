import Foundation

enum FilterMenuAction {
  case category(TransactionCategory)
  case dates
  case grouping(TransactionGroupingEnum)
  case settledOnly(Bool)
}
