import UIKit
import AsyncDisplayKit
import SwiftyBeaver
import Rswift

final class NavigationController: ASNavigationController {
    // MARK: - Life Cycle

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        log.debug("init(rootViewController: \(rootViewController.description))")

        configure()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("Not implemented") }
}

// MARK: - Configuration

private extension NavigationController {
    private func configure() {
        log.verbose("configure")

        navigationBar.tintColor = R.color.accentColor()
        toolbar.tintColor = R.color.accentColor()

        navigationBar.prefersLargeTitles = true
    }
}
