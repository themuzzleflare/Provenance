import UIKit
import Rswift

class NavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.navigationBar.barStyle = .black
        self.navigationBar.barTintColor = R.color.bgColour()
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: R.font.circularStdBook(size: 17)!]
    }
}
