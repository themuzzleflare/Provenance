import UIKit
import Rswift

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBar.barStyle = .black
        self.tabBar.barTintColor = R.color.bgColour()
        
        let tabOne = NavigationController(rootViewController: TransactionsVC())
        let tabOneBarItem = UITabBarItem(title: "Transactions", image: R.image.dollarsignCircle(), selectedImage: R.image.dollarsignCircleFill())
        
        tabOne.tabBarItem = tabOneBarItem
        
        let tabTwo = NavigationController(rootViewController: AccountsVC())
        let tabTwoBarItem = UITabBarItem(title: "Accounts", image: R.image.walletPass(), selectedImage: R.image.walletPassFill())
        
        tabTwo.tabBarItem = tabTwoBarItem
        
        let tabThree = NavigationController(rootViewController: AllTagsVC())
        let tabThreeBarItem = UITabBarItem(title: "Tags", image: R.image.tag(), selectedImage: R.image.tagFill())
        
        tabThree.tabBarItem = tabThreeBarItem
        
        let tabFour = NavigationController(rootViewController: CategoriesVC())
        let tabFourBarItem = UITabBarItem(title: "Categories", image: R.image.arrowUpArrowDownCircle(), selectedImage: R.image.arrowUpArrowDownCircleFill())
        
        tabFour.tabBarItem = tabFourBarItem
        
        let tabFive = NavigationController(rootViewController: R.storyboard.aboutViewController.aboutVC()!)
        let tabFiveBarItem = UITabBarItem(title: "About", image: R.image.infoCircle(), selectedImage: R.image.infoCircleFill())
        
        tabFive.tabBarItem = tabFiveBarItem
        
        self.viewControllers = [tabOne, tabTwo, tabThree, tabFour, tabFive]
    }
}
