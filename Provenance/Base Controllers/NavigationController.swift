import UIKit
import Rswift

class NavigationController: UINavigationController {
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
        navigationBar.tintColor = R.color.accentColour()
    }
}
