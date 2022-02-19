import UIKit
import AsyncDisplayKit

final class RightDetailCellNode: CellNode {
  private let leftTextNode = ASTextNode()
  private let rightTextNode = ASTextNode()

  private var text: String
  private var detailText: String

  init(text: String, detailText: String) {
    self.text = text
    self.detailText = detailText
    super.init()
    automaticallyManagesSubnodes = true
    selectionStyle = .none
    leftTextNode.attributedText = text.styled(with: .leftText)
    rightTextNode.attributedText = detailText.styled(with: .rightText)
    rightTextNode.style.flexShrink = 1.0
    rightTextNode.style.flexGrow = 1.0
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(direction: .horizontal,
                                            spacing: 5,
                                            justifyContent: .spaceBetween,
                                            alignItems: .center,
                                            children: [leftTextNode, rightTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: horizontalStack)
  }
}
