import Foundation

enum ShortcutType: String {
  case transactions = "transactionsShortcut"
  case accounts = "accountsShortcut"
  case tags = "tagsShortcut"
  case categories = "categoriesShortcut"
  case about = "aboutShortcut"
}

// MARK: -

extension ShortcutType {
  var tabBarItem: TabBarItem {
    switch self {
    case .transactions:
      return .transactions
    case .accounts:
      return .accounts
    case .tags:
      return .tags
    case .categories:
      return .categories
    case .about:
      return .about
    }
  }
}
