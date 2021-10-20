import Foundation

extension TagResource {
  var tagCellModel: TagCellModel {
    return TagCellModel(tag: self)
  }
}

extension Array where Element == TagResource {
  var tagCellModels: [TagCellModel] {
    return self.map { (tag) in
      return tag.tagCellModel
    }
  }

  var sortedTags: [SortedTags] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().prefix(1)) }).sorted { $0.key < $1.key }.map { (section) in
      return SortedTags(id: section.key, tags: section.value.map { $0.id })
    }
  }

  var tagSectionModels: [TagSectionModel] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().prefix(1)) }).sorted { $0.key < $1.key }.map { (section) in
      return TagSectionModel(id: section.key, tags: section.value.tagCellModels)
    }
  }

  var tagSectionCoreModels: [TagSectionCoreModel] {
    return Dictionary(grouping: self, by: { String($0.id.lowercased().prefix(1)) }).sorted { $0.key < $1.key }.map { (section) in
      return TagSectionCoreModel(id: section.key, tags: section.value)
    }
  }
}
