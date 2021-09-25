import IGListKit

extension AccountResource: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? AccountResource else { return false }
    return self.attributes.balance.valueInBaseUnits == object.attributes.balance.valueInBaseUnits
  }
}
