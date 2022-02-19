import UIKit
import AsyncDisplayKit

final class SubtitleCellNode: CellNode {
  private let topTextNode = ASTextNode()
  private let bottomTextNode = ASTextNode()

  private var text: String
  private var detailText: String

  init(text: String, detailText: String) {
    self.text = text
    self.detailText = detailText
    super.init()
    automaticallyManagesSubnodes = true
    selectionStyle = .none
    topTextNode.attributedText = text.styled(with: .provenance)
    bottomTextNode.attributedText = detailText.styled(with: .bottomText)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let verticalStack = ASStackLayoutSpec(direction: .vertical,
                                          spacing: 0,
                                          justifyContent: .start,
                                          alignItems: .start,
                                          children: detailText.isEmpty ? [topTextNode] : [topTextNode, bottomTextNode])

    return ASInsetLayoutSpec(insets: .cellNode, child: verticalStack)
  }
}
