import Foundation

struct TagSectionCoreModel {
  let id: String
  let tags: [TagResource]
}

extension TagSectionCoreModel {
  var sortedTagSectionCoreModel: SortedTagSectionCoreModel {
    return SortedTagSectionCoreModel(id: self.id)
  }
}

extension Array where Element == TagSectionCoreModel {
  var sortedMixedCoreModel: [Any] {
    var data = [Any]()
    self.forEach { (object) in
      data.append(object.sortedTagSectionCoreModel)
      data.append(contentsOf: object.tags)
    }
    return data
  }
}
