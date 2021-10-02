import AsyncDisplayKit

final class NavigationController: ASDKNavigationController {
    // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
  }
}

  // MARK: - Configuration

extension NavigationController {
  private func configureSelf() {
    navigationBar.prefersLargeTitles = true
  }
}
