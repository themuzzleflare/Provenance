import UIKit

extension UIBarButtonItem {
  static func dateStyleButtonItem(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .calendarBadgeClock, style: .plain, target: target, action: action)
  }
  
  static func close(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
  }
  
  static func addTags(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .add, target: target, action: action)
  }
  
  static func confirmAddTags(_ target: AddTagConfirmationVC, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .checkmark, style: .plain, target: target, action: action)
  }
  
  static func openDiagnostics(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .chevronLeftSlashChevronRight, style: .plain, target: target, action: action)
  }
  
  static func openSettings(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .gear, style: .plain, target: target, action: action)
  }
  
  static var activityIndicator: UIBarButtonItem {
    let activityIndicator = UIActivityIndicatorView.mediumAnimating
    return UIBarButtonItem(customView: activityIndicator)
  }
  
  static var tag: UIBarButtonItem {
    return UIBarButtonItem(image: .tag)
  }
  
  static var dollarsignCircle: UIBarButtonItem {
    return UIBarButtonItem(image: .dollarsignCircle)
  }
  
  static var walletPass: UIBarButtonItem {
    return UIBarButtonItem(image: .walletPass)
  }
  
  static var trayFull: UIBarButtonItem {
    return UIBarButtonItem(image: .trayFull)
  }
  
  static var infoCircle: UIBarButtonItem {
    return UIBarButtonItem(image: .infoCircle)
  }
}
