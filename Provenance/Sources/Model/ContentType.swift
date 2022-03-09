import Foundation

enum ContentType: Int {
  case transactions
  case accounts
  case tags
  case categories
}

// MARK: -

extension ContentType {
  var plural: String {
    switch self {
    case .transactions:
      return "Transactions"
    case .accounts:
      return "Accounts"
    case .tags:
      return "Tags"
    case .categories:
      return "Categories"
    }
  }

  var singular: String {
    switch self {
    case .transactions:
      return "Transaction"
    case .accounts:
      return "Account"
    case .tags:
      return "Tag"
    case .categories:
      return "Category"
    }
  }

  var noContentDescription: String {
    return "No \(self.plural)"
  }

  var loadingDescription: String {
    return "Loading \(self.plural)"
  }

  func searchBarPlaceholder(count: Int) -> String {
    return "Search \(count.description) \(count == 1 ? singular : plural)"
  }
}
