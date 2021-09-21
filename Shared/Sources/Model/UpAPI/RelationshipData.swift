import Foundation

class RelationshipData: Codable {
  let type: String
  
  let id: String
  
  init(type: String, id: String) {
    self.type = type
    self.id = id
  }
}

extension RelationshipData {
  var tagResource: TagResource {
    return TagResource(id: self.id)
  }
}

extension Array where Element: RelationshipData {
  var tagResources: [TagResource] {
    return self.map { (tag) in
      return tag.tagResource
    }
  }
}
