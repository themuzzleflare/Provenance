import UIKit

extension UIRefreshControl {
  convenience init(_ target: UIViewController, action: Selector) {
    self.init()
    self.addTarget(target, action: action, for: .valueChanged)
  }
}
