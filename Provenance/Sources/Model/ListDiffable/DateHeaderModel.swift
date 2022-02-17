import Foundation
import IGListKit

final class DateHeaderModel {
  let id: Date
  let displayString: String

  init(id: Date) {
    self.id = id
    self.displayString = Utils.formatDateHeader(for: id)
  }
}

// MARK: - ListDiffable

extension DateHeaderModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? DateHeaderModel else { return false }
    return self.displayString == object.displayString
  }
}
