import Foundation
import UIKit

extension NSAttributedString {
  convenience init(text: String?,
                   font: UIFont = .circularStdBook(size: .labelFontSize),
                   colour: UIColor = .label,
                   alignment: NSParagraphStyle = .leftAligned) {
    self.init(string: text ?? "", attributes: [.font: font, .foregroundColor: colour, .paragraphStyle: alignment])
  }
}
