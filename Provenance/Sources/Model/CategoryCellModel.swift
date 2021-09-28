import IGListDiffKit

final class CategoryCellModel: ListDiffable {
  let id: String
  let name: String
  
  init(category: CategoryResource) {
    self.id = category.id
    self.name = category.attributes.name
  }
  
  func diffIdentifier() -> NSObjectProtocol {
    return id as NSObjectProtocol
  }
  
  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let object = object as? CategoryCellModel else { return false }
    return self.id == object.id && self.name == object.name
  }
}
