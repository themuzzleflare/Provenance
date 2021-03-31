import UIKit
import Rswift

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigationStyle()
    }
    
    private func setProperties() {
        delegate = self
    }
    
    private func setupNavigationStyle() {
        navigationBar.barStyle = .black
        navigationBar.barTintColor = R.color.bgColour()
        navigationBar.tintColor = R.color.accentColor()
        navigationBar.titleTextAttributes = [NSAttributedString.Key.font: R.font.circularStdBook(size: 17)!]
    }
}

extension NavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        print("Navigated to: \(viewController.title ?? "Unknown")")
    }
}
