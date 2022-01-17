import UIKit

struct TagResource: Codable, Identifiable {
  /// The type of this resource: `tags`
  var type = "tags"

  /// The label of the tag, which also acts as the tag’s unique identifier.
  var id: String

  var relationships: TagRelationships

  init(id: String) {
    self.id = id
    self.relationships = .empty
  }
}

// MARK: -

extension TagResource {
  var relationshipData: RelationshipData {
    return RelationshipData(type: self.type, id: self.id)
  }

  var tagInputResourceIdentifier: TagInputResourceIdentifier {
    return TagInputResourceIdentifier(id: self.id)
  }
}

// MARK: -

extension Array where Element == TagResource {
  static func singleTag(with tag: TagResource) -> [TagResource] {
    return [tag]
  }

  func filtered(searchBar: UISearchBar) -> [TagResource] {
    return self.filter { (tag) in
      return !searchBar.searchTextField.hasText || tag.id.localizedStandardContains(searchBar.text!)
    }
  }

  var searchBarPlaceholder: String {
    return "Search \(self.count.description) \(self.count == 1 ? "Tag" : "Tags")"
  }

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
    return ListFormatter.localizedString(byJoining: stringArray)
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
