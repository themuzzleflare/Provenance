import UIKit
import AsyncDisplayKit

final class TagCellNode: ASCellNode {
  private let tagTextNode = ASTextNode()

  private var model: TagCellModel
  private var selection: Bool

  init(tag: TagCellModel, selection: Bool = true) {
    self.model = tag
    self.selection = selection
    super.init()
    automaticallyManagesSubnodes = true
    accessoryType = .disclosureIndicator
    tagTextNode.attributedText = tag.id.styled(with: .provenance)
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = selection && isSelected ? .gray.withAlphaComponent(0.3) : .clear
    }
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = selection && isHighlighted ? .gray.withAlphaComponent(0.3) : .clear
    }
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: .cellNode, child: tagTextNode)
  }
}
