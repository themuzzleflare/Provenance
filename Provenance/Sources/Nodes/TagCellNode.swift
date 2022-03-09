import UIKit
import AsyncDisplayKit
import BonMot

final class TagCellNode: CellNode {
  private let textNode = ASTextNode()

  private var model: TagCellModel
  private var selection: Bool

  init(model: TagCellModel, selection: Bool = true) {
    self.model = model
    self.selection = selection
    super.init()
    automaticallyManagesSubnodes = true
    accessoryType = .disclosureIndicator
    textNode.attributedText = model.id.styled(with: .provenance)
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
    return ASInsetLayoutSpec(insets: .cellNode, child: textNode)
  }
}
