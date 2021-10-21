import Foundation

struct SortedTags: Identifiable {
  let id: String
  let tags: [String]
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
