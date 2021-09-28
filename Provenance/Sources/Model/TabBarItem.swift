import UIKit

enum TabBarItem: Int, CaseIterable {
  case transactions = 0
  case accounts = 1
  case tags = 2
  case categories = 3
  case about = 4
}

extension TabBarItem {
  static var defaultTabs = TabBarItem.allCases.map { (item) -> UIViewController in
    let viewController = item.viewController
    viewController.tabBarItem = UITabBarItem(
      title: item.title,
      image: item.image,
      selectedImage: item.selectedImage
    )
    return viewController
  }
  
  var viewController: UIViewController {
    switch self {
    case .transactions:
      return NavigationController(rootViewController: TransactionsVCAlt())
    case .accounts:
      return NavigationController(rootViewController: AccountsVC())
    case .tags:
      return NavigationController(rootViewController: TagsVC())
    case .categories:
      return NavigationController(rootViewController: CategoriesVC())
    case .about:
      return NavigationController(rootViewController: AboutVC())
    }
  }
  
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
  
  var image: UIImage? {
    switch self {
    case .transactions:
      return .dollarsignCircle
    case .accounts:
      return .walletPass
    case .tags:
      return .tag
    case .categories:
      return .trayFull
    case .about:
      return .infoCircle
    }
  }
  
  var selectedImage: UIImage? {
    switch self {
    case .transactions:
      return .dollarsignCircleFill
    case .accounts:
      return .walletPassFill
    case .tags:
      return .tagFill
    case .categories:
      return .trayFullFill
    case .about:
      return .infoCircleFill
    }
  }
  
  var shortcutType: ShortcutType {
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
