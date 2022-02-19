import Foundation

struct TagRelationships: Codable {
  var transactions: RelationshipTransactions
}

// MARK: - ExpressibleByNilLiteral

extension TagRelationships: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self.transactions = nil
  }
}
