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
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = R.color.accentColour()
        navigationBar.titleTextAttributes = [.font: R.font.proximaNovaBold(size: UIFont.labelFontSize)!]
        navigationBar.largeTitleTextAttributes = [.font: R.font.proximaNovaBold(size: 32)!]
    }
}
