import IGListDiffKit

final class SortedTransactionModel {
  let id: Date
  let transactions: [TransactionCellModel]
  
  init(id: Date, transactions: [TransactionCellModel]) {
    self.id = id
    self.transactions = transactions
  }
}

  // MARK: - ListDiffable

extension SortedTransactionModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    return true
  }
}

extension SortedTransactionModel {
  var sortedSectionModel: SortedSectionModel {
    return SortedSectionModel(id: self.id)
  }
}

extension Array where Element: SortedTransactionModel {
  var sortedMixedModel: [ListDiffable] {
    var data = [ListDiffable]()
    self.forEach { (object) in
      data.append(object.sortedSectionModel)
      data.append(contentsOf: object.transactions)
    }
    return data
  }
}
