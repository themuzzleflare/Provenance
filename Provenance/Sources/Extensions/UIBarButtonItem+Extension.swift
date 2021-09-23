import UIKit

extension UIBarButtonItem {
  static func dateStyleButtonItem(_ viewController: UIViewController, selector: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .calendarBadgeClock, style: .plain, target: viewController, action: selector)
  }
  
  static var activityIndicator: UIBarButtonItem {
    let activityIndicator = UIActivityIndicatorView.mediumAnimating
    return UIBarButtonItem(customView: activityIndicator)
  }
  
  static func close(_ viewController: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .close, target: viewController, action: action)
  }
}
