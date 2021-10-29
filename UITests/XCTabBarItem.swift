import Foundation

enum XCTabBarItem {
  case transactions
  case accounts
  case tags
  case categories
  case about
}

extension XCTabBarItem {
  var title: String {
    switch self {
    case .transactions:
      return "Transactions"
    case .accounts:
      return "Accounts"
    case .tags:
      return "Tags"
    case .categories:
      return "Categories"
    case .about:
      return "About"
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .transactions:
      return "transactionsView"
    case .accounts:
      return "accountsView"
    case .tags:
      return "tagsView"
    case .categories:
      return "categoriesView"
    case .about:
      return "aboutView"
    }
  }
}
