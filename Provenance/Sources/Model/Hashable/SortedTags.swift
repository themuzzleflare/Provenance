import Foundation

struct SortedTags: Identifiable {
  var id: String
  
  var tags: [String]
  
  init(id: String, tags: [String]) {
    self.id = id
    self.tags = tags
  }
}

extension SortedTags: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: SortedTags, rhs: SortedTags) -> Bool {
    lhs.id == rhs.id
  }
}

extension Array where Element == SortedTags {
  var sectionIndexTitles: [String] {
    return self.map { (section) in
      return section.id.capitalized
    }
  }
}
