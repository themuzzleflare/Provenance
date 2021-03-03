import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tabOne = UINavigationController(rootViewController: TransactionsVC())
        let tabOneBarItem = UITabBarItem(title: "Transactions", image: UIImage(systemName: "dollarsign.circle"), selectedImage: UIImage(systemName: "dollarsign.circle.fill"))
        
        tabOne.tabBarItem = tabOneBarItem
        
        let tabTwo = UINavigationController(rootViewController: AccountsVC())
        let tabTwoBarItem = UITabBarItem(title: "Accounts", image: UIImage(systemName: "wallet.pass"), selectedImage: UIImage(systemName: "wallet.pass.fill"))
        
        tabTwo.tabBarItem = tabTwoBarItem
        
        let tabThree = UINavigationController(rootViewController: AllTagsVC())
        let tabThreeBarItem = UITabBarItem(title: "Tags", image: UIImage(systemName: "tag"), selectedImage: UIImage(systemName: "tag.fill"))
        
        tabThree.tabBarItem = tabThreeBarItem
        
        let tabFour = UINavigationController(rootViewController: CategoriesVC())
        let tabFourBarItem = UITabBarItem(title: "Categories", image: UIImage(systemName: "arrow.up.arrow.down.circle"), selectedImage: UIImage(systemName: "arrow.up.arrow.down.circle.fill"))
        
        tabFour.tabBarItem = tabFourBarItem
        
        let tabFive = UINavigationController(rootViewController: AboutVC())
        let tabFiveBarItem = UITabBarItem(title: "About", image: UIImage(systemName: "info.circle"), selectedImage: UIImage(systemName: "info.circle.fill"))
        
        tabFive.tabBarItem = tabFiveBarItem
        
        self.viewControllers = [tabOne, tabTwo, tabThree, tabFour, tabFive]
    }
}
