import Foundation

struct SortedTags {
  let id: String
  let tags: [String]
}

// MARK: - Hashable

extension SortedTags: Hashable {
  static func == (lhs: SortedTags, rhs: SortedTags) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: -

extension Array where Element == SortedTags {
  var sectionIndexTitles: [String] {
    return self.map { (section) in
      return section.id.capitalized
    }
  }
}
