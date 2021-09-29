import IGListDiffKit

final class TagCellModel {
  let id: String
  
  init(tag: TagResource) {
    self.id = tag.id
  }
  
  init(id: String) {
    self.id = id
  }
}

extension TagCellModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TagCellModel else { return false }
    return true
  }
}
