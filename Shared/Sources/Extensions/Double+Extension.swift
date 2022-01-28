import Foundation
import CoreGraphics

extension Double {
  var nsNumber: NSNumber {
    return NSNumber(value: self)
  }

  var integer: Int {
    return Int(self)
  }

  var float: Float {
    return Float(self)
  }

  var cgFloat: CGFloat {
    return CGFloat(self)
  }
}
