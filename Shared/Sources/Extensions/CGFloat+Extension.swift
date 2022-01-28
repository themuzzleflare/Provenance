import UIKit
import CoreGraphics

extension CGFloat {
  static var screenWidth: CGFloat {
    return UIScreen.main.bounds.width
  }

  static var screenHeight: CGFloat {
    return UIScreen.main.bounds.height
  }

  static var labelFontSize: CGFloat {
    return UIFont.labelFontSize
  }

  static var smallSystemFontSize: CGFloat {
    return UIFont.smallSystemFontSize
  }
}
