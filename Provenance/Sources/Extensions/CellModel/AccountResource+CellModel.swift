import Foundation

extension AccountResource {
  var cellModel: AccountCellModel {
    return AccountCellModel(account: self)
  }
}

// MARK: -

extension Array where Element == AccountResource {
  var cellModels: [AccountCellModel] {
    return self.map { (account) in
      return account.cellModel
    }
  }
}
