import Foundation
import UIKit

struct TransactionResource: Codable, Identifiable {
  /// The type of this resource: `transactions`
  var type = "transactions"

  /// The unique identifier for this transaction.
  var id: String

  var attributes: TransactionAttributes

  var relationships: TransactionRelationships

  var links: SelfLink?
}

// MARK: - CustomStringConvertible

extension TransactionResource: CustomStringConvertible {
  var description: String {
    return attributes.description
  }
}

// MARK: -

extension TransactionResource {
  func latestTransactionModel(configuration: DateStyleSelectionIntent) -> LatestTransactionModel {
    return LatestTransactionModel(id: id,
                                  description: attributes.description,
                                  creationDate: configuration.dateStyle.description(self),
                                  amount: attributes.amount.valueShort,
                                  colour: attributes.amount.transactionType.colour)
  }

  var transactionType: TransactionType {
    return TransactionType(transaction: self)
  }

  var tagsArray: [NSString] {
    return self.relationships.tags.data.map { $0.id.nsString }
  }
}

// MARK: -

extension Array where Element == TransactionResource {
  func filtered(searchBar: UISearchBar) -> [TransactionResource] {
    return self.filter { (transaction) in
      return !searchBar.searchTextField.hasText || transaction.attributes.description.localizedStandardContains(searchBar.text!)
    }
  }

  var searchBarPlaceholder: String {
    return "Search \(self.count.description) \(self.count == 1 ? "Transaction" : "Transactions")"
  }

  var transactionTypes: [TransactionType] {
    return self.map { $0.transactionType }
  }
}
