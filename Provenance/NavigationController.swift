import UIKit
import Rswift

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.barStyle = .black
        self.navigationBar.barTintColor = R.color.bgColour()
    }
}
