import UIKit
import AsyncDisplayKit

extension ASTextCellNode {
  convenience init(text: String? = nil, insets: UIEdgeInsets? = nil, font: UIFont? = nil, colour: UIColor? = nil, alignment: NSParagraphStyle? = nil, selectionStyle: UITableViewCell.SelectionStyle = .default, accessoryType: UITableViewCell.AccessoryType = .none) {
    self.init(
      attributes: [
        NSAttributedString.Key.font: font ?? .circularStdBook(size: .labelFontSize),
        NSAttributedString.Key.foregroundColor: colour ?? .label,
        NSAttributedString.Key.paragraphStyle: alignment ?? .leftAligned
      ],
      insets: insets ?? .cellNode
    )
    self.text = text ?? ""
    self.selectionStyle = selectionStyle
    self.accessoryType = accessoryType
  }
}
