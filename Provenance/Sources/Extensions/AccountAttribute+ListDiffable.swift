import IGListKit

extension AccountAttribute: ListDiffable {
  var id: String {
    return displayName + accountType.rawValue
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? AccountAttribute else { return false }
    return self.id == object.id && self.balance.valueInBaseUnits == object.balance.valueInBaseUnits
  }
}
