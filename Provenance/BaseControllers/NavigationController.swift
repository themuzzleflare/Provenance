import UIKit
import Rswift

final class NavigationController: UINavigationController {
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
}

// MARK: - Configuration

private extension NavigationController {
    private func configure() {
        navigationBar.tintColor = R.color.accentColor()
    }
}
