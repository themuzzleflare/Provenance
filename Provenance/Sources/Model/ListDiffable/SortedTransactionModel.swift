import IGListKit

struct SortedTransactionModel {
  let id: Date
  let transactions: [TransactionCellModel]
}

// MARK: -

extension SortedTransactionModel {
  var sortedSectionModel: SortedSectionModel {
    return SortedSectionModel(id: self.id)
  }
}

// MARK: -

extension Array where Element == SortedTransactionModel {
  var sortedMixedModel: [ListDiffable] {
    var data = [ListDiffable]()
    self.forEach { (object) in
      data.append(object.sortedSectionModel)
      data.append(contentsOf: object.transactions)
    }
    return data
  }
}
