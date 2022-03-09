import Foundation
import UIKit

extension NSParagraphStyle {
  static let leftAligned: NSParagraphStyle = {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .left
    return paragraphStyle
  }()

  static let centreAligned: NSParagraphStyle = {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    return paragraphStyle
  }()

  static let rightAligned: NSParagraphStyle = {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .right
    return paragraphStyle
  }()
}
