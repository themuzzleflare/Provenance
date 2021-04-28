import UIKit
import Rswift

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension NavigationController {
    private func configure() {
        navigationBar.tintColor = R.color.accentColour()
    }
}
