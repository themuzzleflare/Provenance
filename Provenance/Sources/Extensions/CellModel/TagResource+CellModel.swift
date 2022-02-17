import Foundation

extension TagResource {
  var cellModel: TagCellModel {
    return TagCellModel(tag: self)
  }
}

// MARK: -

extension Array where Element == TagResource {
  var cellModels: [TagCellModel] {
    return self.map { (tag) in
      return tag.cellModel
    }
  }

  var sortedTags: [SortedTags] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().first!) }).sorted { $0.key < $1.key }.map { (section) in
      return SortedTags(id: section.key, tags: section.value.map { $0.id })
    }
  }

  var sortedTagsCoreModels: [SortedTagsCoreModel] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().first!) }).sorted { $0.key < $1.key }.map { (section) in
      return SortedTagsCoreModel(id: section.key, tags: section.value)
    }
  }
}
