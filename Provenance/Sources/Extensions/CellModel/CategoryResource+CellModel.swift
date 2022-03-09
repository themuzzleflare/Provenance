import Foundation

extension CategoryResource {
  var cellModel: CategoryCellModel {
    return CategoryCellModel(category: self)
  }
}

// MARK: -

extension Array where Element == CategoryResource {
  var cellModels: [CategoryCellModel] {
    return self.map { $0.cellModel }
  }
}
