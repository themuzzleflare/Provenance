import Foundation
import IGListKit

extension CategoryResource: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? CategoryResource else { return false }
    return self.id == object.id
  }
}
