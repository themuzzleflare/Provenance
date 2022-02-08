import Foundation

extension TransactionGroupingEnum {
  var valueType: Any.Type? {
    switch self {
    case .all:
      return nil
    case .dates:
      return DateHeaderModel.self
    case .transactions:
      return TransactionCellModel.self
    }
  }
}
