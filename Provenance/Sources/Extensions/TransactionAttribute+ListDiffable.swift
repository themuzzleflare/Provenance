import IGListKit

extension TransactionAttribute: ListDiffable {
  var id: String {
    return description + createdAt
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSString
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? TransactionAttribute else { return false }
    return self.id == object.id && self.creationDate == object.creationDate
  }
}
