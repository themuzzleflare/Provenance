import Foundation

class TagResource: Codable {
  /// The type of this resource: tags
  var type = "tags"

  /// The label of the tag, which also acts as the tag’s unique identifier.
  var id: String

  var relationships: TagRelationship?

  init(id: String, relationships: TagRelationship? = nil) {
    self.id = id
    self.relationships = relationships
  }
}
