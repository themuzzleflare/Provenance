import Foundation
import UIKit

extension UIBarButtonItem {
  static func dateStyleButtonItem(_ viewController: UIViewController, selector: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .calendarBadgeClock, style: .plain, target: viewController, action: selector)
  }
}
