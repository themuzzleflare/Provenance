import AsyncDisplayKit

final class NavigationController: ASNavigationController {
    // MARK: - Life Cycle
  
  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
    configure()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }
}

  // MARK: - Configuration

private extension NavigationController {
  private func configure() {
    navigationBar.prefersLargeTitles = true
  }
}
