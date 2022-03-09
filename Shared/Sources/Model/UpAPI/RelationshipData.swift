import Foundation

struct RelationshipData: Codable, Identifiable {
  /// The type of this resource.
  var type: String

  /// The unique identifier of the resource within its type.
  var id: String
}

// MARK: -

extension RelationshipData {
  var tagResource: TagResource {
    return TagResource(id: id)
  }
}

// MARK: -

extension Array where Element == RelationshipData {
  var tagResources: [TagResource] {
    return self.map { $0.tagResource }
  }
}
