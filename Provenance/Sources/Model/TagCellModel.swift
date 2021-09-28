import IGListDiffKit

final class TagCellModel: ListDiffable {
  let id: String
  
  init(tag: TagResource) {
    self.id = tag.id
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TagCellModel else { return false }
    return self.id == object.id
  }
}
