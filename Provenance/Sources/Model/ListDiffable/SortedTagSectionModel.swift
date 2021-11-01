import IGListKit

final class SortedTagSectionModel {
  let id: String

  init(id: String) {
    self.id = id
  }
}

// MARK: - ListDiffable

extension SortedTagSectionModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    if self === object { return true }
    guard object is SortedTagSectionModel else { return false }
    return true
  }
}
