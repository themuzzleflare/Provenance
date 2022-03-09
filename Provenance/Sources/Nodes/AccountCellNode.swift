import UIKit
import AsyncDisplayKit
import BonMot

final class AccountCellNode: CellNode {
  private let balanceTextNode = ASTextNode()
  private let displayNameTextNode = ASTextNode()

  private var model: AccountCellModel

  init(model: AccountCellModel) {
    self.model = model
    super.init()
    automaticallyManagesSubnodes = true
    balanceTextNode.attributedText = model.balance.styled(with: .accountBalance)
    displayNameTextNode.attributedText = model.displayName.styled(with: .accountDisplayName)
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
    guard previousTraitCollection.userInterfaceStyle != asyncTraitCollection().userInterfaceStyle else { return }
    borderColor = .separator
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(direction: .vertical,
                                          spacing: 0,
                                          justifyContent: .center,
                                          alignItems: .center,
                                          children: [balanceTextNode, displayNameTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
