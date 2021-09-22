import Foundation
import Intents

extension TransactionType {
  convenience init(id: String, description: String, creationDate: String, amount: String) {
    self.init(identifier: id, display: description, subtitle: [amount, creationDate].joined(separator: ", "), image: nil)
    self.transactionDescription = description
    self.transactionCreationDate = creationDate
    self.transactionAmount = amount
  }
  
  convenience init(transaction: TransactionResource) {
    self.init(identifier: transaction.id, display: transaction.attributes.description, subtitle: [transaction.attributes.amount.valueShort, transaction.attributes.creationDate].joined(separator: ", "), image: nil)
    self.transactionDescription = transaction.attributes.description
    self.transactionCreationDate = transaction.attributes.creationDate
    self.transactionAmount = transaction.attributes.amount.valueShort
    self.amount = transaction.attributes.amount.inCurrencyAmount
    self.creationDate = transaction.attributes.createdAtDateComponents
  }
}

extension Array where Element: TransactionType {
  var collection: INObjectCollection<TransactionType> {
    return INObjectCollection(items: self)
  }
}
