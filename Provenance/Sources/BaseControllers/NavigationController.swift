import UIKit
import AsyncDisplayKit

final class NavigationController: ASNavigationController {
  // MARK: - Life Cycle

  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
    configure()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Configuration

private extension NavigationController {
  private func configure() {
    navigationBar.prefersLargeTitles = true
  }
}
