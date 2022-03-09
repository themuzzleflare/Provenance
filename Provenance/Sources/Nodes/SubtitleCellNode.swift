import UIKit
import AsyncDisplayKit
import BonMot

final class SubtitleCellNode: CellNode {
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
    textNode.attributedText = text.styled(with: .provenance)
    detailTextNode.attributedText = detailText.styled(with: .bottomText)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(direction: .vertical,
                                          spacing: 0,
                                          justifyContent: .start,
                                          alignItems: .start,
                                          children: detailText.isEmpty ? [textNode] : [textNode, detailTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
