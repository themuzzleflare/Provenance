import UIKit
import Rswift

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupTabBarStyle()
        setupTabBarItems()
    }
    
    private func setProperties() {
        delegate = self
    }
    
    private func setupTabBarStyle() {
        tabBar.barStyle = .black
        tabBar.barTintColor = R.color.bgColour()
    }
    
    private func setupTabBarItems() {
        // MARK: - Transactions
        let tabOne = NavigationController(rootViewController: TransactionsVC())
        let tabOneBarItem = UITabBarItem(title: "Transactions", image: R.image.dollarsignCircle(), selectedImage: R.image.dollarsignCircleFill())
        
        tabOne.tabBarItem = tabOneBarItem
        
        // MARK: - Accounts
        let tabTwo = NavigationController(rootViewController: AccountsVC())
        let tabTwoBarItem = UITabBarItem(title: "Accounts", image: R.image.walletPass(), selectedImage: R.image.walletPassFill())
        
        tabTwo.tabBarItem = tabTwoBarItem
        
        // MARK: - Tags
        let tabThree = NavigationController(rootViewController: AllTagsVC())
        let tabThreeBarItem = UITabBarItem(title: "Tags", image: R.image.tag(), selectedImage: R.image.tagFill())
        
        tabThree.tabBarItem = tabThreeBarItem
        
        // MARK: - Categories
        let tabFour = NavigationController(rootViewController: CategoriesVC())
        let tabFourBarItem = UITabBarItem(title: "Categories", image: R.image.arrowUpArrowDownCircle(), selectedImage: R.image.arrowUpArrowDownCircleFill())
        
        tabFour.tabBarItem = tabFourBarItem
        
        // MARK: - About
        let tabFive = NavigationController(rootViewController: R.storyboard.aboutViewController.aboutVC()!)
        let tabFiveBarItem = UITabBarItem(title: "About", image: R.image.infoCircle(), selectedImage: R.image.infoCircleFill())
        
        tabFive.tabBarItem = tabFiveBarItem
        
        // MARK: - Tab Bar Items
        viewControllers = [tabOne, tabTwo, tabThree, tabFour, tabFive]
    }
}
