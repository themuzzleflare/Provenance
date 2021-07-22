import UIKit
import Rswift

enum TabBarItem: Int, CaseIterable {
    case transactions
    case accounts
    case tags
    case categories
    case about

    func vc() -> UIViewController {
        switch self {
            case .transactions:
                return NavigationController(rootViewController: TransactionsVC())
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

    func title() -> String {
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
    
    func image() -> UIImage? {
        switch self {
            case .transactions:
                return R.image.dollarsignCircle()
            case .accounts:
                return R.image.walletPass()
            case .tags:
                return R.image.tag()
            case .categories:
                return R.image.trayFull()
            case .about:
                return R.image.infoCircle()
        }
    }
    
    func selectedImage() -> UIImage? {
        switch self {
            case .transactions:
                return R.image.dollarsignCircleFill()
            case .accounts:
                return R.image.walletPassFill()
            case .tags:
                return R.image.tagFill()
            case .categories:
                return R.image.trayFullFill()
            case .about:
                return R.image.infoCircleFill()
        }
    }
}
