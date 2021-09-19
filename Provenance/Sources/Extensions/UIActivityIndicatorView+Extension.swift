import Foundation
import UIKit

extension UIActivityIndicatorView {
  static var mediumAnimating: UIActivityIndicatorView {
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    activityIndicatorView.startAnimating()
    return activityIndicatorView
  }
}
