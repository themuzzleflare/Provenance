import UIKit
import Rswift

class TabBarController: UITabBarController {
    // MARK: - Life Cycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension TabBarController {
    private func configure() {
        viewControllers = TabBarItem.allCases.map { item in
            let vc = item.vc()
            vc.tabBarItem = UITabBarItem(title: item.title(), image: item.image(), selectedImage: item.selectedImage())
            return vc
        }
    }
}
