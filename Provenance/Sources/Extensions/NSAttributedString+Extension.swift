import Foundation
import UIKit

extension NSAttributedString {
  convenience init(text: String?, font: UIFont? = nil, colour: UIColor? = nil, alignment: NSParagraphStyle? = nil) {
    self.init(
      string: text ?? "",
      attributes: [
        .font: font ?? .circularStdBook(size: UIFont.labelFontSize),
        .foregroundColor: colour ?? .label,
        .paragraphStyle: alignment ?? .leftAligned
      ]
    )
  }
}
