import UIKit

extension UIBarButtonItem {
  static let tag = UIBarButtonItem(image: .tag)

  static let dollarsignCircle = UIBarButtonItem(image: .dollarsignCircle)

  static let walletPass = UIBarButtonItem(image: .walletPass)

  static let trayFull = UIBarButtonItem(image: .trayFull)

  static let infoCircle = UIBarButtonItem(image: .infoCircle)

  static let activityIndicator = UIBarButtonItem(customView: UIActivityIndicatorView.mediumAnimating)

  static func transactionStatusIcon(_ target: UIViewController, status: TransactionStatusEnum, action: Selector) -> UIBarButtonItem {
    let barButtonItem = UIBarButtonItem(image: status.uiImage, style: .plain, target: target, action: action)
    barButtonItem.tintColor = status.uiColour
    return barButtonItem
  }

  static func dateStyleButtonItem(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .calendarBadgeClock, style: .plain, target: target, action: action)
  }

  static func accountInfo(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(image: .infoCircle, style: .plain, target: target, action: action)
  }

  static func close(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
  }

  static func add(_ target: UIViewController, action: Selector) -> UIBarButtonItem {
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
}
