import Foundation

class TagResource: Codable {
    /// The type of this resource: tags
  let type = "tags"
  
    /// The label of the tag, which also acts as the tag’s unique identifier.
  let id: String
  
  let relationships: TagRelationship?
  
  init(id: String, relationships: TagRelationship? = nil) {
    self.id = id
    self.relationships = relationships
  }
}

extension TagResource {
  var relationshipData: RelationshipData {
    return RelationshipData(type: self.type, id: self.id)
  }
  
  var tagInputResourceIdentifier: TagInputResourceIdentifier {
    return TagInputResourceIdentifier(id: self.id)
  }
}

extension Array where Element: TagResource {
  var nsStringArray: [NSString] {
    return self.map { (tag) in
      return tag.id.nsString
    }
  }
  
  var stringArray: [String] {
    return self.map { (tag) in
      return tag.id
    }
  }
  
  var joinedWithComma: String {
    return stringArray.joined(separator: ", ")
  }
  
  var relationshipDatas: [RelationshipData] {
    return self.map { (tag) in
      return tag.relationshipData
    }
  }
  
  var tagInputResourceIdentifiers: [TagInputResourceIdentifier] {
    return self.map { (tag) in
      return tag.tagInputResourceIdentifier
    }
  }
}
