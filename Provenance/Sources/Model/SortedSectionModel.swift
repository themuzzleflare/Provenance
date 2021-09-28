import IGListDiffKit

final class SortedSectionModel: ListDiffable {
  let id: Date
  
  init(id: Date) {
    self.id = id
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? SortedSectionModel else { return false }
    return self.id == object.id
  }
}
