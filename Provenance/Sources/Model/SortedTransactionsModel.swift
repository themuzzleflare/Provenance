import Foundation
import IGListKit

struct SortedTransactionsModel {
  let id: Date
  let transactions: [TransactionResource]
}

// MARK: -

extension SortedTransactionsModel {
  var dateHeaderModel: DateHeaderModel {
    return DateHeaderModel(id: id,
                           dateString: Utils.formatDateHeader(for: id),
                           spendTotal: transactions.spendTotal)
  }
}

// MARK: -

extension Array where Element == SortedTransactionsModel {
  var diffablesObject: [ListDiffable] {
    var data = [ListDiffable]()
    self.forEach { (object) in
      data.append(object.dateHeaderModel)
      data.append(contentsOf: object.transactions.cellModels)
    }
    return data
  }
}
