import UIKit

extension UIViewController {
  static func fullscreen(_ viewController: UIViewController) -> UIViewController {
    viewController.modalPresentationStyle = .fullScreen
    return viewController
  }
  
  static var widgets: UIViewController {
    return WidgetsVC()
  }
  
  static var stickers: UIViewController {
    return StickersVC()
  }
  
  static var settings: UIViewController {
    return SettingsVC()
  }
  
  static var diagnostics: UIViewController {
    return DiagnosticsVC()
  }
  
  static var addTagTransactionSelection: UIViewController {
    return AddTagTransactionSelectionVC()
  }
}