import IGListDiffKit

final class SortedTransactionModel: ListDiffable {
  let id: Date
  let transactions: [TransactionCellModel]
  
  init(id: Date, transactions: [TransactionCellModel]) {
    self.id = id
    self.transactions = transactions
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? SortedTransactionModel else { return false }
    return self.id == object.id && self.transactions == object.transactions
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
