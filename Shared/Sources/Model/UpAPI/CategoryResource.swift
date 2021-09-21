import Foundation

class CategoryResource: Codable {
  /// The type of this resource: categories
  let type = "categories"

  /// The unique identifier for this category. This is a human-readable but URL-safe value.
  let id: String

  let attributes: CategoryAttribute

  let relationships: CategoryRelationship

  let links: SelfLink?

  init(id: String, attributes: CategoryAttribute, relationships: CategoryRelationship, links: SelfLink? = nil) {
    self.id = id
    self.attributes = attributes
    self.relationships = relationships
    self.links = links
  }
}

extension CategoryResource {
  var categoryTypeEnum: CategoryTypeEnum {
    return relationships.parent.data == nil ? .parent : .child
  }
  
  var categoryType: CategoryType {
    return CategoryType(
      identifier: self.id,
      display: self.attributes.name
    )
  }
}

extension Array where Element: CategoryResource {
  var categoryTypes: [CategoryType] {
    return self.map { (category) in
      return category.categoryType
    }
  }
}
