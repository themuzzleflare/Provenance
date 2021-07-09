import UIKit
import Hero
import SwiftyBeaver

final class TabController: UITabBarController {
    // MARK: - Properties

    let controllers = TabBarItem.allCases.map { item -> UIViewController in
        let vc = item.vc()
        vc.tabBarItem = UITabBarItem(title: item.title(), image: item.image(), selectedImage: item.selectedImage())
        return vc
    }

    // MARK: - Life Cycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Configuration

private extension TabController {
    private func configure() {
        log.verbose("configure")
        
        setViewControllers(controllers, animated: true)
    }
}

// MARK: - UITabBarDelegate

extension TabController {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let title = item.title {
            log.debug("tabBar(didSelect item: \(title))")
        }
    }
}
