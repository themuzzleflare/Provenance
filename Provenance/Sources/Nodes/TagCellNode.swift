import UIKit
import AsyncDisplayKit

final class TagCellNode: ASCellNode {
  private let tagTextNode = ASTextNode()
  
  init(tag: TagResource) {
    super.init()
    automaticallyManagesSubnodes = true
    accessoryType = .disclosureIndicator
    tagTextNode.attributedText = NSAttributedString(text: tag.id)
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .cellNode, child: tagTextNode)
  }
}
