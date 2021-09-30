import UIKit

extension UIActivityIndicatorView {
  static var mediumAnimating: UIActivityIndicatorView {
    let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    activityIndicatorView.hidesWhenStopped = false
    activityIndicatorView.startAnimating()
    return activityIndicatorView
  }
}
