import AsyncDisplayKit

extension ASTextCellNode {
  convenience init(text: String? = nil, insets: UIEdgeInsets? = nil, font: UIFont? = nil, colour: UIColor? = nil, alignment: NSParagraphStyle? = nil, selectionStyle: UITableViewCell.SelectionStyle? = nil, accessoryType: UITableViewCell.AccessoryType? = nil) {
    self.init(
      attributes: [
        NSAttributedString.Key.font: font ?? .circularStdBook(size: .labelFontSize),
        NSAttributedString.Key.foregroundColor: colour ?? .label,
        NSAttributedString.Key.paragraphStyle: alignment ?? .leftAligned
      ],
      insets: insets ?? .cellNode
    )
    self.text = text ?? .emptyString
    self.selectionStyle = selectionStyle ?? .default
    self.accessoryType = accessoryType ?? .none
  }
}
