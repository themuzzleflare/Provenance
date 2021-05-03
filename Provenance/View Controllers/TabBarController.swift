import UIKit
import Rswift

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension TabBarController {
    private func configure() {
        viewControllers = [
            {
                let vc = NavigationController(rootViewController: TransactionsVC(style: .grouped))
                vc.tabBarItem = UITabBarItem(title: "Transactions", image: R.image.dollarsignCircle(), selectedImage: R.image.dollarsignCircleFill())
                return vc
            }(),
            {
                let vc = NavigationController(rootViewController: AccountsCVC(collectionViewLayout: twoColumnGridLayout()))
                vc.tabBarItem = UITabBarItem(title: "Accounts", image: R.image.walletPass(), selectedImage: R.image.walletPassFill())
                return vc
            }(),
            {
                let vc = NavigationController(rootViewController: AllTagsVC(style: .grouped))
                vc.tabBarItem = UITabBarItem(title: "Tags", image: R.image.tag(), selectedImage: R.image.tagFill())
                return vc
            }(),
            {
                let vc = NavigationController(rootViewController: CategoriesCVC(collectionViewLayout: twoColumnGridLayout()))
                vc.tabBarItem = UITabBarItem(title: "Categories", image: R.image.arrowUpArrowDownCircle(), selectedImage: R.image.arrowUpArrowDownCircleFill())
                return vc
            }(),
            {
                let vc = NavigationController(rootViewController: AboutVC(style: .grouped))
                vc.tabBarItem = UITabBarItem(title: "About", image: R.image.infoCircle(), selectedImage: R.image.infoCircleFill())
                return vc
            }()
        ]
    }
}
