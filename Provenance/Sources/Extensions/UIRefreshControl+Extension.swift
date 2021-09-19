import Foundation
import UIKit

extension UIRefreshControl {
  convenience init(_ viewController: UIViewController, selector: Selector) {
    self.init()
    self.addTarget(viewController, action: selector, for: .valueChanged)
  }
}
