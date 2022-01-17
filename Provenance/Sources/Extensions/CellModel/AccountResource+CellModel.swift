import Foundation

extension AccountResource {
  var accountCellModel: AccountCellModel {
    return AccountCellModel(account: self)
  }
}

// MARK: -

extension Array where Element == AccountResource {
  var accountCellModels: [AccountCellModel] {
    return self.map { (account) in
      return account.accountCellModel
    }
  }
}
