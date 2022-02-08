import UIKit
import AsyncDisplayKit

final class AccountCellNode: ASCellNode {
  private let balanceTextNode = ASTextNode()
  private let displayNameTextNode = ASTextNode()

  private var model: AccountCellModel

  init(account: AccountCellModel) {
    self.model = account
    super.init()
    automaticallyManagesSubnodes = true
    balanceTextNode.attributedText = account.balance.styled(with: .accountBalance)
    displayNameTextNode.attributedText = account.displayName.styled(with: .accountDisplayName)
    displayNameTextNode.maximumNumberOfLines = 2
    cornerRadius = 12.5
    borderColor = .separator
    borderWidth = 1.0
    backgroundColor = .secondarySystemBackground
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .gray.withAlphaComponent(0.3) : .secondarySystemBackground
    }
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .gray.withAlphaComponent(0.3) : .secondarySystemBackground
    }
  }

  override func asyncTraitCollectionDidChange(withPreviousTraitCollection previousTraitCollection: ASPrimitiveTraitCollection) {
    super.asyncTraitCollectionDidChange(withPreviousTraitCollection: previousTraitCollection)
    guard previousTraitCollection.userInterfaceStyle != primitiveTraitCollection().userInterfaceStyle else { return }
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
