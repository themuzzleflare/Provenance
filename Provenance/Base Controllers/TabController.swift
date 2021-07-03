import UIKit
import Rswift

final class TabController: UITabBarController {
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
}

// MARK: - Configuration

private extension TabController {
    private func configure() {
        viewControllers = TabBarItem.allCases.map { item in
            let vc = item.vc()

            vc.tabBarItem = UITabBarItem(title: item.title(), image: item.image(), selectedImage: item.selectedImage())

            return vc
        }
    }
}
