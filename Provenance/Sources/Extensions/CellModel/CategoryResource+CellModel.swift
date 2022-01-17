import Foundation

extension CategoryResource {
  var categoryCellModel: CategoryCellModel {
    return CategoryCellModel(category: self)
  }
}

// MARK: -

extension Array where Element == CategoryResource {
  var categoryCellModels: [CategoryCellModel] {
    return self.map { (category) in
      return category.categoryCellModel
    }
  }
}
