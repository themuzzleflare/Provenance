import UIKit
import AsyncDisplayKit
import Rswift

class NavigationController: ASNavigationController {
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
        navigationBar.tintColor = R.color.accentColour()
    }
}
