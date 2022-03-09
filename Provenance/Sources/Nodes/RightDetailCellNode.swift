import UIKit
import AsyncDisplayKit
import BonMot

final class RightDetailCellNode: CellNode {
  private let textNode = ASTextNode()
  private let detailTextNode = ASTextNode()

  private var text: String
  private var detailText: String

  init(text: String, detailText: String) {
    self.text = text
    self.detailText = detailText
    super.init()
    automaticallyManagesSubnodes = true
    selectionStyle = .none
    textNode.attributedText = text.styled(with: .leftText)
    detailTextNode.attributedText = detailText.styled(with: .rightText)
    detailTextNode.style.flexShrink = 1.0
    detailTextNode.style.flexGrow = 1.0
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 5,
                                            justifyContent: .spaceBetween,
                                            alignItems: .center,
                                            children: [textNode, detailTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: horizontalStack)
  }
}
