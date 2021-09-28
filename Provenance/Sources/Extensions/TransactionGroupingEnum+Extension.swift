import Foundation

extension TransactionGroupingEnum {
  var valueType: Any.Type? {
    switch self {
    case .all:
      return nil
    case .dates:
      return SortedSectionModel.self
    case .transactions:
      return TransactionCellModel.self
    }
  }
}
