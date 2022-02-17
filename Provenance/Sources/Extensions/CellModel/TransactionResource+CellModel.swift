import Foundation

extension TransactionResource {
  var cellModel: TransactionCellModel {
    return TransactionCellModel(transaction: self)
  }
}

// MARK: -

extension Array where Element == TransactionResource {
  var cellModels: [TransactionCellModel] {
    return self.map { (transaction) in
      return transaction.cellModel
    }
  }

  var sortedTransactionsModels: [SortedTransactionsModel] {
    return Dictionary(grouping: self, by: { $0.attributes.sortingDate }).sorted { $0.key > $1.key }.map { (section) in
      return SortedTransactionsModel(id: section.key, transactions: section.value)
    }
  }
}
