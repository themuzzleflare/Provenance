import Foundation

struct TagRelationships: Codable {
  var transactions: RelationshipTransactions
}

// MARK: -

extension TagRelationships {
  static let empty = TagRelationships(transactions: .empty)
}
