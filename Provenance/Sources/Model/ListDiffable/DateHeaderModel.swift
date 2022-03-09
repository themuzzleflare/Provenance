import Foundation
import IGListKit

final class DateHeaderModel {
  let id: Date
  let dateString: String
  let spendTotal: String

  init(id: Date, dateString: String, spendTotal: String) {
    self.id = id
    self.dateString = dateString
    self.spendTotal = spendTotal
  }
}

// MARK: - ListDiffable

extension DateHeaderModel: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? DateHeaderModel else { return false }
    return self.dateString == object.dateString && self.spendTotal == object.spendTotal
  }
}
