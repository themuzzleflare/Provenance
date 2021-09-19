import Foundation
import SwiftUI

class TransactionResource: Codable {
  /// The type of this resource: transactions
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
    var creationDate: String {
      switch configuration.dateStyle {
      case .unknown, .appDefault:
        return attributes.creationDate
      case .absolute:
        return formatDate(for: attributes.createdAt, dateStyle: .absolute)
      case .relative:
        return formatDate(for: attributes.createdAt, dateStyle: .relative)
      }
    }
    return LatestTransactionModel(id: self.id, description: self.attributes.description, creationDate: creationDate, amount: self.attributes.amount.valueShort, colour: self.attributes.amount.valueInBaseUnits.signum() == -1 ? .primary : .greenColour)
  }
}
