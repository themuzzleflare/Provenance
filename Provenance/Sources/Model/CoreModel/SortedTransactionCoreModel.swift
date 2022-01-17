import Foundation

struct SortedTransactionCoreModel {
  let id: Date
  let transactions: [TransactionResource]
}

// MARK: -

extension SortedTransactionCoreModel {
  var sortedSectionCoreModel: SortedSectionCoreModel {
    return SortedSectionCoreModel(id: self.id)
  }
}

// MARK: -

extension Array where Element == SortedTransactionCoreModel {
  var sortedMixedCoreModel: [Any] {
    var data = [Any]()
    self.forEach { (object) in
      data.append(object.sortedSectionCoreModel)
      data.append(contentsOf: object.transactions)
    }
    return data
  }
}

// MARK: -

extension Array {
  var transactionResources: [TransactionResource] {
    return self.compactMap { (element) in
      return element as? TransactionResource
    }
  }
}
