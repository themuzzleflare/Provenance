import IGListKit

extension TagResource: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TagResource else { return false }
    return true
  }
}
