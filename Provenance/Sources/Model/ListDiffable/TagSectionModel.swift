import IGListDiffKit

final class TagSectionModel {
  let id: String
  let tags: [TagCellModel]
  
  init(id: String, tags: [TagCellModel]) {
    self.id = id
    self.tags = tags
  }
}

// MARK: - ListDiffable

extension TagSectionModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    if self === object { return true }
    guard object is TagSectionModel else { return false }
    return true
  }
}

extension TagSectionModel {
  var sortedTagSectionModel: SortedTagSectionModel {
    return SortedTagSectionModel(id: self.id)
  }
}

extension Array where Element: TagSectionModel {
  var sectionIndexTitles: [String] {
    return self.map { (section) in
      return section.id.capitalized
    }
  }
  
  var sortedMixedModel: [ListDiffable] {
    var data = [ListDiffable]()
    self.forEach { (object) in
      data.append(object.sortedTagSectionModel)
      data.append(contentsOf: object.tags)
    }
    return data
  }
}
