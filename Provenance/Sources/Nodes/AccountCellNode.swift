import UIKit
import AsyncDisplayKit

final class AccountCellNode: ASCellNode {
  private let balanceTextNode = ASTextNode()
  private let displayNameTextNode = ASTextNode()

  init(account: AccountResource) {
    super.init()

    automaticallyManagesSubnodes = true

    balanceTextNode.attributedText = NSAttributedString(
      text: account.attributes.balance.valueShort,
      font: .circularStdBold(size: 32),
      colour: .accentColor,
      alignment: .centreAligned
    )

    displayNameTextNode.attributedText = NSAttributedString(
      text: account.attributes.displayName,
      alignment: .centreAligned
    )

    cornerRadius = 12.5
    borderColor = .separator
    borderWidth = 1.0
    backgroundColor = .secondarySystemGroupedBackground
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .systemGray4 : .secondarySystemGroupedBackground
    }
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .systemGray4 : .secondarySystemGroupedBackground
    }
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .center,
      alignItems: .center,
      children: [
        balanceTextNode,
        displayNameTextNode
      ]
    )

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
