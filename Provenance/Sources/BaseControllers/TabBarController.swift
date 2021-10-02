import AsyncDisplayKit
import UIKit

final class TabBarController: ASTabBarController {
    // MARK: - Life Cycle
  
//  private var coreDataViewController: UIViewController = {
//    let viewController = NavigationController(rootViewController: CoreDataVC())
//    viewController.tabBarItem = UITabBarItem(title: "CoreData", image: UIImage(systemName: "square.stack.3d.up"), selectedImage: UIImage(systemName: "square.stack.3d.up.fill"))
//    return viewController
//  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
  }
}

  // MARK: - Configuration

extension TabBarController {
  private func configureSelf() {
//    var controllers: [UIViewController] = []
//    controllers.append(contentsOf: TabBarItem.defaultTabs)
//    controllers.append(coreDataViewController)
    setViewControllers(TabBarItem.defaultTabs, animated: false)
  }
}
