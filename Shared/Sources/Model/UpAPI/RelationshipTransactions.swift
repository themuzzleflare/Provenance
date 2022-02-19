import Foundation

struct RelationshipTransactions: Codable {
  var links: RelatedLink?
}

// MARK: - ExpressibleByNilLiteral

extension RelationshipTransactions: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self.links = nil
  }
}
