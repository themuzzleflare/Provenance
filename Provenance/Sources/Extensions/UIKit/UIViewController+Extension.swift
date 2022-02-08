import UIKit

extension UIViewController {
  static func fullscreen(_ viewController: UIViewController) -> UIViewController {
    viewController.modalPresentationStyle = .fullScreen
    return viewController
  }
}
