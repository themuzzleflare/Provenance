import IGListDiffKit

final class TransactionCellModel: ListDiffable {
  let id: String
  let description: String
  let creationDate: String
  let amount: String
  let colour: TransactionColour
  
  init(transaction: TransactionResource) {
    self.id = transaction.id
    self.description = transaction.attributes.description
    self.creationDate = transaction.attributes.creationDate
    self.amount = transaction.attributes.amount.valueShort
    self.colour = transaction.attributes.amount.transactionType.colour
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TransactionCellModel else { return false }
    return self.id == object.id && self.creationDate == object.creationDate
  }
}

extension TransactionCellModel: Equatable {
  static func == (lhs: TransactionCellModel, rhs: TransactionCellModel) -> Bool {
    return lhs.id == rhs.id && lhs.creationDate == rhs.creationDate
  }
}
