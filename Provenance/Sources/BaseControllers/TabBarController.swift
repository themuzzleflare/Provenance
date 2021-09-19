import UIKit
import AsyncDisplayKit

final class TabBarController: ASTabBarController {
  // MARK: - Properties

  let controllers = TabBarItem.allCases.map { (item) -> UIViewController in
    let viewController = item.viewController
    viewController.tabBarItem = UITabBarItem(
      title: item.title,
      image: item.image,
      selectedImage: item.selectedImage
    )
    return viewController
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

private extension TabBarController {
  private func configure() {
    setViewControllers(controllers, animated: false)
  }
}
