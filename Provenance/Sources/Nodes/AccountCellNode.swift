import AsyncDisplayKit

final class AccountCellNode: ASCellNode {
  private let balanceTextNode = ASTextNode()
  private let displayNameTextNode = ASTextNode()
  
  init(account: AccountResource) {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    balanceTextNode.attributedText = account.attributes.balance.valueShort.styled(with: .accountBalance)
    
    displayNameTextNode.attributedText = account.attributes.displayName.styled(with: .accountDisplayName)
    displayNameTextNode.maximumNumberOfLines = 2
    
    cornerRadius = 12.5
    borderColor = .separator
    borderWidth = 1.0
    backgroundColor = .secondarySystemGroupedBackground
  }
  
  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .gray.withAlphaComponent(0.3) : .secondarySystemGroupedBackground
    }
  }
  
  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .gray.withAlphaComponent(0.3) : .secondarySystemGroupedBackground
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