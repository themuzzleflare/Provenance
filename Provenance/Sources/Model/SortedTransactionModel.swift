import Foundation
import IGListKit

struct SortedTransactionModel {
  let id: Date
  let transactions: [TransactionResource]
}

// MARK: -

extension SortedTransactionModel {
  var dateHeaderModel: DateHeaderModel {
    return DateHeaderModel(id: self.id)
  }
}

// MARK: -

extension Array where Element == SortedTransactionModel {
  var diffablesObject: [ListDiffable] {
    var data = [ListDiffable]()
    self.forEach { (object) in
      data.append(object.dateHeaderModel)
      data.append(contentsOf: object.transactions.transactionCellModels)
    }
    return data
  }

  var supplementaryObject: [Any] {
    var data = [Any]()
    self.forEach { (object) in
      data.append(object.dateHeaderModel)
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
