import IGListKit

extension TransactionResource: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TransactionResource else { return false }
    return true
  }
}
