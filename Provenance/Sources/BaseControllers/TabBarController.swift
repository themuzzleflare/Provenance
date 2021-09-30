import AsyncDisplayKit

final class TabBarController: ASTabBarController {
    // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
  }
}

  // MARK: - Configuration

private extension TabBarController {
  private func configureSelf() {
    setViewControllers(TabBarItem.defaultTabs, animated: false)
  }
}
