import IGListKit

extension RelationshipData: ListDiffable {
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? RelationshipData else { return false }
    return self.id == object.id
  }
}
