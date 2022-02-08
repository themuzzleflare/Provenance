import Foundation
import IGListKit

final class TagCellModel: NSObject {
  let id: String

  init(tag: TagResource) {
    self.id = tag.id
  }
}

// MARK: - ListDiffable

extension TagCellModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard object is TagCellModel else { return false }
    return true
  }
}
