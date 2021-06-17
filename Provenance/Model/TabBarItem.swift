import UIKit
import Rswift

enum TabBarItem: Int, CaseIterable {
    case transactions, accounts, tags, categories, about

    func vc() -> UIViewController {
        switch self {
            case .transactions:
                return NavigationController(rootViewController: TransactionsCVC())
            case .accounts:
                return NavigationController(rootViewController: AccountsCVC(collectionViewLayout: twoColumnGridLayout()))
            case .tags:
                return NavigationController(rootViewController: AllTagsVC(style: .insetGrouped))
            case .categories:
                return NavigationController(rootViewController: CategoriesCVC(collectionViewLayout: twoColumnGridLayout()))
            case .about:
                return NavigationController(rootViewController: AboutVC(style: .insetGrouped))
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
                return R.image.arrowUpArrowDownCircle()
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
                return R.image.arrowUpArrowDownCircleFill()
            case .about:
                return R.image.infoCircleFill()
        }
    }
}
