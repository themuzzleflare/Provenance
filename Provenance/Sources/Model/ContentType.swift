import Foundation

enum ContentType: Int {
  case transactions = 0
  case accounts = 1
  case tags = 2
  case categories = 3
}

extension ContentType {
  var noContentDescription: String {
    switch self {
    case .transactions:
      return "No Transactions"
    case .accounts:
      return "No Accounts"
    case .tags:
      return "No Tags"
    case .categories:
      return "No Categories"
    }
  }
}
