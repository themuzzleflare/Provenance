import AsyncDisplayKit

final class AboutTopCellNode: ASCellNode {
  private let logoImageNode = ASImageNode()
  private let nameTextNode = ASTextNode()
  private let descriptionTextNode = ASTextNode()

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
    selectionStyle = .none
    logoImageNode.animatedImage = AnimatedImage.upLogoDrawMidnightYellowTransparentBackground.asAnimatedImage
    logoImageNode.backgroundColor = .accentColor
    logoImageNode.cornerRadius = 20
    logoImageNode.style.width = ASDimension(unit: .points, value: 100)
    logoImageNode.style.height = ASDimension(unit: .points, value: 100)
    nameTextNode.attributedText = "Provenance".styled(with: .aboutName)
    descriptionTextNode.attributedText = "Provenance is a native iOS application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags and more.".styled(with: .aboutDescription)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .center,
      alignItems: .center,
      children: [
        logoImageNode,
        nameTextNode,
        descriptionTextNode
      ]
    )

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
