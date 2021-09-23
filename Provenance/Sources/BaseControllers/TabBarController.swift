import AsyncDisplayKit

final class TabBarController: ASTabBarController {
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
    setViewControllers(TabBarItem.defaultTabs, animated: false)
  }
}
