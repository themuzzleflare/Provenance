import UIKit

class TransactionResource: Codable {
    /// The type of this resource: `transactions`
  let type = "transactions"
  
    /// The unique identifier for this transaction.
  let id: String
  
  let attributes: TransactionAttribute
  
  let relationships: TransactionRelationship
  
  let links: SelfLink?
  
  init(id: String, attributes: TransactionAttribute, relationships: TransactionRelationship, links: SelfLink? = nil) {
    self.id = id
    self.attributes = attributes
    self.relationships = relationships
    self.links = links
  }
}

extension TransactionResource {
  func latestTransactionModel(configuration: DateStyleSelectionIntent) -> LatestTransactionModel {
    return LatestTransactionModel(
      id: self.id,
      description: self.attributes.description,
      creationDate: configuration.dateStyle.description(self),
      amount: self.attributes.amount.valueShort,
      colour: self.attributes.amount.transactionType.colour
    )
  }
  
  var transactionType: TransactionType {
    return TransactionType(transaction: self)
  }
  
  var tagsArray: [NSString] {
    return self.relationships.tags.data.map { (tag) in
      return tag.id.nsString
    }
  }
}

extension Array where Element: TransactionResource {
  func filtered(searchBar: UISearchBar) -> [TransactionResource] {
    return self.filter { (transaction) in
      searchBar.text?.isEmpty ?? true || transaction.attributes.description.localizedStandardContains(searchBar.text!)
    }
  }
  
  var transactionTypes: [TransactionType] {
    return self.map { (transaction) in
      return transaction.transactionType
    }
  }
}
