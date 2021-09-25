import UIKit

extension UIRefreshControl {
  convenience init(_ viewController: UIViewController, action: Selector) {
    self.init()
    self.addTarget(viewController, action: action, for: .valueChanged)
  }
}
