import UIKit

extension UIEdgeInsets {
  /// `UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16)`.
  static var cellNode: UIEdgeInsets {
    return UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16)
  }
  
  /// `UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)`.
  static var horizontalInset: UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
  }
  
  /// `UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0)`.
  static var verticalInset: UIEdgeInsets {
    return UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0)
  }
  
  /// `UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 0)`.
  static var sectionHeader: UIEdgeInsets {
    return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 0)
  }
}
