import UIKit
import SwiftyBeaver
import Rswift

final class NavigationController: UINavigationController {
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
        log.verbose("configure")

        navigationBar.tintColor = R.color.accentColor()
        navigationBar.prefersLargeTitles = true
    }
}
