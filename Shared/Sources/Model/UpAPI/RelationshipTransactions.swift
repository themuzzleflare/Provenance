import Foundation

struct RelationshipTransactions: Codable {
  var links: RelatedLink?
}

// MARK: -

extension RelationshipTransactions {
  static let empty = RelationshipTransactions(links: nil)
}
