import UIKit
import Rswift

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension NavigationController {
    private func configure() {
        navigationBar.tintColor = R.color.accentColor()
        navigationBar.titleTextAttributes = [NSAttributedString.Key.font: R.font.circularStdBook(size: UIFont.labelFontSize)!]
    }
}
