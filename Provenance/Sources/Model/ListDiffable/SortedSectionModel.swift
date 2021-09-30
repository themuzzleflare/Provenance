import IGListDiffKit

final class SortedSectionModel {
  let id: Date
  
  init(id: Date) {
    self.id = id
  }
}

  // MARK: - ListDiffable

extension SortedSectionModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? SortedSectionModel else { return false }
    return true
  }
}
