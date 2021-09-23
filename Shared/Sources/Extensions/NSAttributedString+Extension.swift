import UIKit

extension NSAttributedString {
  convenience init(text: String?, font: UIFont? = nil, colour: UIColor? = nil, alignment: NSParagraphStyle? = nil) {
    self.init(
      string: text ?? .emptyString,
      attributes: [
        .font: font ?? .circularStdBook(size: .labelFontSize),
        .foregroundColor: colour ?? .label,
        .paragraphStyle: alignment ?? .leftAligned
      ]
    )
  }
}
