import UIKit
import Rswift

class TabBarController: UITabBarController {
    let tabOne: UIViewController = {
        let vc = NavigationController(rootViewController: TransactionsVC(style: .grouped))
        vc.tabBarItem = UITabBarItem(title: "Transactions", image: R.image.dollarsignCircle(), selectedImage: R.image.dollarsignCircleFill())
        return vc
    }()
    
    let tabTwo: UIViewController = {
        let vc = NavigationController(rootViewController: AccountsCVC(collectionViewLayout: twoColumnGridLayout()))
        vc.tabBarItem = UITabBarItem(title: "Accounts", image: R.image.walletPass(), selectedImage: R.image.walletPassFill())
        return vc
    }()
    
    let tabThree: UIViewController = {
        let vc = NavigationController(rootViewController: AllTagsVC(style: .grouped))
        vc.tabBarItem = UITabBarItem(title: "Tags", image: R.image.tag(), selectedImage: R.image.tagFill())
        return vc
    }()
    
    let tabFour: UIViewController = {
        let vc = NavigationController(rootViewController: CategoriesCVC(collectionViewLayout: twoColumnGridLayout()))
        vc.tabBarItem = UITabBarItem(title: "Categories", image: R.image.arrowUpArrowDownCircle(), selectedImage: R.image.arrowUpArrowDownCircleFill())
        return vc
    }()
    
    let tabFive: UIViewController = {
        let vc = NavigationController(rootViewController: R.storyboard.aboutViewController.aboutVC()!)
        vc.tabBarItem = UITabBarItem(title: "About", image: R.image.infoCircle(), selectedImage: R.image.infoCircleFill())
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
}

extension TabBarController {
    private func configure() {
        viewControllers = [tabOne, tabTwo, tabThree, tabFour, tabFive]
        
        tabBar.barStyle = .black
        tabBar.barTintColor = R.color.bgColour()
    }
}

extension TabBarController {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Selected tab: \(item.title ?? "Unknown")")
    }
}
