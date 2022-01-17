import IGListKit

final class SortedTransactionModelAlt {
  let id: Date
  let transactions: [TransactionResource]

  init(id: Date, transactions: [TransactionResource]) {
    self.id = id
    self.transactions = transactions
  }
}

// MARK: - ListDiffable

extension SortedTransactionModelAlt: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    return true
  }
}

// MARK: -

extension SortedTransactionModelAlt {
  var sortedSectionModel: SortedSectionModel {
    return SortedSectionModel(id: self.id)
  }
}
