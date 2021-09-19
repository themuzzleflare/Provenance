import Foundation

class CategoryResource: Codable {
  /// The type of this resource: categories
  var type = "categories"

  /// The unique identifier for this category. This is a human-readable but URL-safe value.
  var id: String

  var attributes: CategoryAttribute

  var relationships: CategoryRelationship

  var links: SelfLink?

  init(id: String, attributes: CategoryAttribute, relationships: CategoryRelationship, links: SelfLink? = nil) {
    self.id = id
    self.attributes = attributes
    self.relationships = relationships
    self.links = links
  }
}

extension CategoryResource {
  var isParent: Bool {
    return relationships.parent.data == nil
  }
}
