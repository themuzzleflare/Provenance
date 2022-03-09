import Foundation

extension TagResource {
  var cellModel: TagCellModel {
    return TagCellModel(tag: self)
  }
}

// MARK: -

extension Array where Element == TagResource {
  var cellModels: [TagCellModel] {
    return self.map { $0.cellModel }
  }

  var sortedTags: [SortedTags] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().first!) })
      .sorted { $0.key < $1.key }
      .map { SortedTags(id: $0.key, tags: $0.value.map { $0.id }) }
  }

  var sortedTagsCoreModels: [SortedTagsCoreModel] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().first!) })
      .sorted { $0.key < $1.key }
      .map { SortedTagsCoreModel(id: $0.key, tags: $0.value) }
  }
}
