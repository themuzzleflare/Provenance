import Foundation

extension TransactionResource {
  var cellModel: TransactionCellModel {
    return TransactionCellModel(transaction: self)
  }
}

// MARK: -

extension Array where Element == TransactionResource {
  var cellModels: [TransactionCellModel] {
    return self.map { $0.cellModel }
  }

  var sortedTransactionsModels: [SortedTransactionsModel] {
    return Dictionary(grouping: self, by: { $0.attributes.sortingDate })
      .sorted { $0.key > $1.key }
      .map { SortedTransactionsModel(id: $0.key, transactions: $0.value) }
  }

  var spendTotal: String {
    let sum = self
      .filter { $0.attributes.amount.transactionType == .debit && $0.attributes.amount.currencyCode == "AUD" }
      .map { Double($0.attributes.amount.value)! }
      .reduce(0.00, +)
    return NumberFormatter.currency().string(from: NSNumber(value: sum))!
  }
}
